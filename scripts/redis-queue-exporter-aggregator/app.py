from kubernetes import client, config
import os
import re
import time
import requests
import threading
from flask import Flask, Response

def get_node_name():
    """Retrieve the node name from the environment variable."""
    return os.getenv("NODE_NAME", "")

def get_pods_on_node(node_name):
    """Retrieve all pods scheduled on the given node."""
    v1 = client.CoreV1Api()
    pods = v1.list_pod_for_all_namespaces(field_selector=f"spec.nodeName={node_name}")
    return pods.items

def filter_pods(pods):
    """Filter pods based on namespace, container name, and port."""
    valid_namespaces = {"stg", "pre", "prod"}
    matching_pods = []
    
    for pod in pods:
        if pod.metadata.namespace not in valid_namespaces:
            continue
        
        for container in pod.spec.containers:
            if not re.match(r".*queue-exporter.*", container.name):
                continue
            
            if any(port.container_port == 9107 for port in (container.ports or [])):
                matching_pods.append(pod)
                break
    
    return matching_pods

def fetch_metrics(pods):
    """Fetch metrics from the found pods."""
    all_metrics = []
    
    for pod in pods:
        pod_ip = pod.status.pod_ip
        if not pod_ip:
            continue
        metrics_url = f"http://{pod_ip}:9107/metrics"
        
        try:
            response = requests.get(metrics_url, timeout=5)
            if response.status_code == 200:
                all_metrics.append(response.text)
        except requests.RequestException:
            pass  # Ignore failed requests
    
    return "\n".join(all_metrics)

# Flask app to expose metrics
app = Flask(__name__)
latest_metrics = ""

def update_metrics():
    global latest_metrics
    while True:
        node_name = get_node_name()
        if not node_name:
            time.sleep(15)
            continue
        
        pods = get_pods_on_node(node_name)
        filtered_pods = filter_pods(pods)
        latest_metrics = fetch_metrics(filtered_pods)
        
        time.sleep(15)

@app.route("/metrics")
def expose_metrics():
    return Response(latest_metrics, mimetype="text/plain")

def start_flask():
    app.run(host="0.0.0.0", port=9107)

if __name__ == "__main__":
    try:
        config.load_incluster_config()
    except config.ConfigException:
        config.load_kube_config()
    
    threading.Thread(target=update_metrics, daemon=True).start()
    start_flask()
