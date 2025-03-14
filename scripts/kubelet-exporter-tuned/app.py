import os
import requests
import threading
import time
from flask import Flask, Response

# Create a Flask app
app = Flask(__name__)

# Configuration
SCRAPE_URL = "https://kubernetes.default.svc:443/api/v1/nodes/{}/proxy/metrics"
TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"
CA_CERT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

# Read the bearer token
with open(TOKEN_PATH, 'r') as token_file:
    BEARER_TOKEN = token_file.read().strip()

# Get the node name from the NODE_NAME environment variable
NODE_NAME = os.getenv("NODE_NAME")

# List of metrics to expose
METRICS_TO_EXPOSE = [
    "kubelet_volume_stats_capacity_bytes",
    "kubelet_volume_stats_available_bytes",
    "kubelet_volume_stats_used_bytes",
    "kubelet_volume_stats_inodes",
    "kubelet_volume_stats_inodes_free",
    "kubelet_volume_stats_inodes_used"
]

# Shared variable to store the fetched metrics
shared_metrics_data = "# Metrics not available yet\n"
data_lock = threading.Lock()

# Function to fetch metrics for the current node
def fetch_metrics(node_name):
    headers = {"Authorization": f"Bearer {BEARER_TOKEN}"}
    url = SCRAPE_URL.format(node_name)
    try:
        response = requests.get(url, headers=headers, verify=CA_CERT_PATH, timeout=10)
        response.raise_for_status()
        return filter_metrics(response.text, node_name)
    except requests.RequestException as e:
        return f"# Error fetching metrics for node {node_name}: {e}\n"

# Function to filter the metrics and add the kubernetes_io_hostname label
def filter_metrics(metrics_data, node_name):
    filtered_metrics = []
    for line in metrics_data.splitlines():
        if line.startswith("# HELP") or line.startswith("# TYPE"):
            # Include only HELP and TYPE lines for the exposed metrics
            if any(metric in line for metric in METRICS_TO_EXPOSE):
                filtered_metrics.append(line)
        elif any(metric in line for metric in METRICS_TO_EXPOSE):
            # Add label to the metrics
            if "}" in line:  # If the metric already has labels
                line = line.replace("}", f',kubernetes_io_hostname="{node_name}"}}')
            else:  # If the metric has no labels
                line = f'{line}{{kubernetes_io_hostname="{node_name}"}}'
            filtered_metrics.append(line)
    return "\n".join(filtered_metrics)

# Background thread function to update the shared metrics data
def update_metrics_periodically():
    global shared_metrics_data
    while True:
        if NODE_NAME:
            new_metrics = fetch_metrics(NODE_NAME)
            with data_lock:
                shared_metrics_data = new_metrics
        time.sleep(15)  # Sleep for 15 seconds between updates

# Flask route to serve metrics
@app.route('/metrics')
def metrics():
    with data_lock:
        return Response(shared_metrics_data, mimetype='text/plain')

if __name__ == "__main__":
    # Start the background thread
    threading.Thread(target=update_metrics_periodically, daemon=True).start()

    # Expose the app on port 10251
    app.run(host="0.0.0.0", port=10251)
