from flask import Flask, Response
import requests
import time
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
    while True:
        try:
            # Fetch metrics from the source
            response = requests.get("http://0.0.0.0:9100/metrics")
            if response.status_code == 200:
                lines = response.text.splitlines()
                filtered_lines = []

                # Filter relevant metrics including HELP and TYPE
                for metric in METRICS:
                    for i, line in enumerate(lines):
                        # Include HELP, TYPE, and all appearances of the metric
                        if (
                            line.startswith(f"# HELP {metric}") or
                            line.startswith(f"# TYPE {metric}") or
                            (line.startswith(metric) and not line.startswith(f"# "))
                        ):
                            filtered_lines.append(line)

                # Combine all filtered lines
                filtered_metrics = "\n".join(filtered_lines)
        except Exception as e:
            print(f"Error fetching metrics: {e}")

        time.sleep(1)

if __name__ == '__main__':
    # Start metrics fetching in a separate thread
    threading.Thread(target=fetch_metrics, daemon=True).start()

    # Start Flask app
    app.run(host="0.0.0.0", port=9101)


