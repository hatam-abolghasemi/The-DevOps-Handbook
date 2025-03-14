import os
import logging
import json
import re
import time
from kubernetes import client, config
from prometheus_client import start_http_server, Gauge, REGISTRY
from collections import defaultdict

logging.basicConfig(level=logging.INFO)
log_pattern = re.compile(r'^\{"msec":"\d+\.\d+","request":".*","status":"\d{3}","request_time":"\d+\.\d+","bytes_sent":"\d+"\}$')
POD_NAME = os.getenv("POD_NAME")
APP_LABEL = os.getenv("APP_LABEL")
nginx_request_count = Gauge(
    'nginx_request_count_total',
    'Counts occurrences of routes in nginx requests with method and status',
    ['route', 'method', 'status', 'app', 'namespace']
)
nginx_request_time = Gauge(
    'nginx_request_time',
    'Nginx request processing time in milliseconds',
    ['method', 'route', 'status', 'app', 'namespace']
)
request_counts = {}
request_times = defaultdict(lambda: {'total_time': 0.0, 'count': 0})

def update_request_count(route, method, status):
    key = (route, method, status)
    if key not in request_counts:
        request_counts[key] = 0
    request_counts[key] += 1
    nginx_request_count.labels(route=route, method=method, status=status, app=APP_LABEL, namespace=POD_NAMESPACE).set(request_counts[key])

def update_request_time(method, route, status, request_time):
    key = (method, route, status)
    request_times[key]['total_time'] += request_time
    request_times[key]['count'] += 1

def get_average_request_time(method, route, status):
    key = (method, route, status)
    data = request_times[key]
    if data['count'] == 0:
        return 0.0
    return data['total_time'] / data['count']

def process_log_line(log):
    try:
        log_json = json.loads(log)
        request = log_json.get("request", "")
        status = log_json.get("status", "0")
        request_time = float(log_json.get("request_time", 0))
        method, route = parse_request(request)
        nginx_request_count.labels(route=route, method=method, status=status, app=APP_LABEL, namespace=POD_NAMESPACE).inc()
        update_request_time(method, route, status, request_time * 1000)
        avg_time = get_average_request_time(method, route, status)
        nginx_request_time.labels(method=method, route=route, status=status, app=APP_LABEL, namespace=POD_NAMESPACE).set(avg_time)
    except json.JSONDecodeError:
        logging.warning(f"Log doesn't match JSON format: {log}")
        
def read_nginx_logs(pod_name, namespace, container_name="nginx"):
    try:
        config.load_incluster_config()
        v1 = client.CoreV1Api()
        logging.info(f"Fetching logs from container '{container_name}' in pod '{pod_name}'...")
        while True:
            try:
                nginx_request_count.clear()
                nginx_request_time.clear()
                log_lines = v1.read_namespaced_pod_log(
                    name=pod_name,
                    namespace=namespace,
                    container=container_name,
                    tail_lines=1000
                )
                now = time.time()
                for log in log_lines.splitlines():
                    if log and "msec" in log:
                        log_json = json.loads(log)
                        if float(log_json["msec"]) >= (now - 15):
                            process_log_line(log)
            except Exception as e:
                logging.error(f"Error while fetching logs: {e}")
            time.sleep(1)
    except Exception as e:
        logging.error(f"Error while setting up log reading: {e}")

def parse_request(request):
    parts = request.split()
    if len(parts) >= 2:
        method = parts[0]
        route = parts[1]
        route = route.split('?')[0]
        segments = route.split('/')
        sanitized_segments = []
        for segment in segments:
            if segment.isdigit():
                sanitized_segments.append('$param')
            elif len(segment) > 4 and re.search(r'\d', segment):
                sanitized_segments.append('$param')
            else:
                sanitized_segments.append(segment)
        route = '/'.join(sanitized_segments)
        if route.endswith('/') and len(route) > 1:
            route = route[:-1]
    else:
        method = "UNKNOWN"
        route = "UNKNOWN"
    return method, route

def deregister_unwanted_metrics():
    unwanted_metrics = [
        'python_gc_objects_uncollectable_total',
        'python_gc_collections_total',
        'python_info',
        'process_virtual_memory_bytes',
        'process_resident_memory_bytes',
        'process_start_time_seconds',
        'process_cpu_seconds_total',
        'process_open_fds',
        'process_max_fds'
    ]
    for metric_name in unwanted_metrics:
        if metric_name in REGISTRY._names_to_collectors:
            REGISTRY.unregister(REGISTRY._names_to_collectors[metric_name])

def main():
    pod_name = os.getenv("POD_NAME")
    namespace = os.getenv("POD_NAMESPACE")
    global POD_NAMESPACE
    POD_NAMESPACE = namespace
    deregister_unwanted_metrics()
    if not pod_name or not namespace:
        logging.error("Pod name or namespace environment variables not set.")
        return
    start_http_server(9106)
    logging.info("nginx-exporter started on port 9106.")
    read_nginx_logs(pod_name, namespace)

if __name__ == "__main__":
    main()
