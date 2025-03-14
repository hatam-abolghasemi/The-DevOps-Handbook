from kubernetes import client, config, watch
import os
import re
import time
import requests
import threading
from flask import Flask, Response
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
import numpy as np
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
app = Flask(__name__)
latest_metrics = ""

def get_node_name():
    return os.getenv("NODE_NAME", "")

def watch_pods_on_node(node_name):
    v1 = client.CoreV1Api()
    w = watch.Watch()
    pods = []
    for event in w.stream(v1.list_pod_for_all_namespaces, field_selector=f"spec.nodeName={node_name}"):
        pod = event['object']
        if pod.metadata.deletion_timestamp:
            pods = [p for p in pods if p.metadata.name != pod.metadata.name]
        else:
            pods.append(pod)
        yield pods

def fetch_metrics_from_pods(pods):
    all_metrics = {
        "nginx_request_time": defaultdict(list),
        "nginx_request_count_total": defaultdict(int)
    }

def fetch_metrics_from_pods(pods):
    all_metrics = {
        "nginx_request_time": defaultdict(list),
        "nginx_request_count_total": defaultdict(int)
    }

    def fetch_metrics_for_pod(pod):
        for container in pod.spec.containers:
            if re.match(r".*nginx-exporter.*", container.name) and any(port.container_port == 9106 for port in (container.ports or [])):
                pod_ip = pod.status.pod_ip
                if not pod_ip:
                    return
                metrics_url = f"http://{pod_ip}:9106/metrics"
                try:
                    response = requests.get(metrics_url, timeout=5)
                    if response.status_code == 200:
                        lines = response.text.splitlines()
                        for line in lines:
                            if line.startswith("nginx_request_time"):
                                match = re.match(r"nginx_request_time\{(.*)\} (\d+\.\d+)", line)
                                if match:
                                    all_metrics["nginx_request_time"][match.group(1)].append(float(match.group(2)))
                            elif line.startswith("nginx_request_count_total"):
                                match = re.match(r"nginx_request_count_total\{(.*)\} (\d+)", line)
                                if match:
                                    all_metrics["nginx_request_count_total"][match.group(1)].append(int(match.group(2)))
                except requests.RequestException as e:
                    logger.error(f"Error fetching metrics from {metrics_url}: {e}")
    with ThreadPoolExecutor() as executor:
        threads = [executor.submit(fetch_metrics_for_pod, pod) for pod in pods]
        for t in threads:
            t.result()
    return summarize_metrics(all_metrics)

def summarize_metrics(all_metrics):
    result_metrics = []
    for labels, values in all_metrics["nginx_request_time"].items():
        avg_value = np.mean(values)
        result_metrics.append(f"nginx_request_time{{{labels}}} {avg_value:.3f}")
    for labels, value in all_metrics["nginx_request_count_total"].items():
        total_value = np.sum(value)
        result_metrics.append(f"nginx_request_count_total{{{labels}}} {total_value}")
    return "\n".join(result_metrics)

def update_metrics():
    global latest_metrics
    node_name = get_node_name()
    if not node_name:
        logger.warning("No NODE_NAME found, sleeping...")
        time.sleep(15)
        return
    for pods in watch_pods_on_node(node_name):
        filtered_pods = filter_pods(pods)
        latest_metrics = fetch_metrics_parallel(filtered_pods)
        time.sleep(15) 

@app.route("/metrics")
def expose_metrics():
    return Response(latest_metrics, mimetype="text/plain")

def start_flask():
    app.run(host="0.0.0.0", port=9106, debug=False, threaded=True)

if __name__ == "__main__":
    try:
        config.load_incluster_config()
    except config.ConfigException:
        config.load_kube_config()
    threading.Thread(target=update_metrics, daemon=True).start()
    start_flask()
