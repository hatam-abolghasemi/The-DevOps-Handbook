#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
USER="node-exporter-tuned"
GROUP="node-exporter-tuned"
SERVICE_FILE="/etc/systemd/system/node-exporter-tuned.service"
APP_DIR="/etc/node-exporter-tuned"
APP_FILE="$APP_DIR/app.py"
VENV_DIR="$APP_DIR/venv"

# Create user and group
if ! getent group $GROUP > /dev/null; then
  groupadd -f $GROUP
  echo "Group $GROUP created."
fi

if ! id $USER > /dev/null 2>&1; then
  useradd -g $GROUP --no-create-home --shell /bin/false $USER
  echo "User $USER created."
fi

# Setup application directory
mkdir -p $APP_DIR
chown $USER:$GROUP $APP_DIR
chmod 750 $APP_DIR

# Python virtual environment setup
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate
pip install flask requests

# Create app.py (basic content added)
cat <<EOL > $APP_FILE
from flask import Flask, Response
import requests
import threading

# Metrics to filter
METRICS = [
    "node_cpu_seconds_total", "node_memory_MemAvailable_bytes", "node_memory_MemTotal_bytes",
    "node_network_receive_bytes_total", "node_network_transmit_bytes_total", "node_load1",
    "node_time_seconds", "node_boot_time_seconds", "node_filesystem_size_bytes",
    "node_filesystem_avail_bytes", "node_context_switches_total", "node_intr_total",
    "node_disk_reads_completed_total", "node_disk_writes_completed_total", "node_procs_running",
    "node_procs_blocked", "node_forks_total", "node_memory_SwapTotal_bytes", "node_memory_SwapFree_bytes"
]

# Global variable to store the filtered metrics
filtered_metrics = ""

# Flask app to serve metrics
app = Flask(__name__)

@app.route('/metrics', methods=['GET'])
def serve_metrics():
    global filtered_metrics
    return Response(filtered_metrics, mimetype='text/plain')

def fetch_metrics():
    global filtered_metrics
    stop_event = threading.Event()

    session = requests.Session()  # Use a session for connection reuse

    while not stop_event.is_set():
        try:
            # Fetch metrics from the source
            response = session.get("http://0.0.0.0:9100/metrics", timeout=5)
            if response.status_code == 200:
                lines = response.text.splitlines()
                filtered_lines = []
                metrics_set = set(METRICS)  # Use a set for faster lookups

                # Filter relevant metrics including HELP and TYPE
                for line in lines:
                    if any(
                        line.startswith(prefix.format(metric))
                        for metric in METRICS
                        for prefix in ["# HELP {}", "# TYPE {}", "{}"]
                    ):
                        filtered_lines.append(line)

                # Combine all filtered lines
                filtered_metrics = "\n".join(filtered_lines)
        except Exception as e:
            print("Error fetching metrics: {}".format(e))

if __name__ == '__main__':
    # Start metrics fetching in a separate thread
    threading.Thread(target=fetch_metrics, daemon=True).start()

    # Start Flask app
    app.run(host="0.0.0.0", port=9101)
EOL

chown $USER:$GROUP $APP_FILE
chmod 640 $APP_FILE

# Create systemd service file
cat <<EOL > $SERVICE_FILE
[Unit]
Description=Node Exporter TUNED
After=network.target

[Service]
User=$USER
Group=$GROUP
WorkingDirectory=$APP_DIR
Environment=VIRTUAL_ENV=$VENV_DIR
ExecStart=/bin/bash -c "source $VIRTUAL_ENV/bin/activate && exec python3 $APP_FILE"
Restart=always
RestartSec=5
CPUAccounting=true
MemoryAccounting=true
CPUQuota=5%
MemoryMax=60M

[Install]
WantedBy=multi-user.target
EOL

chmod 644 $SERVICE_FILE

# Enable and start service
systemctl daemon-reload
systemctl enable node-exporter-tuned.service --now
systemctl status node-exporter-tuned.service

echo "Node Exporter Tuned setup complete."

