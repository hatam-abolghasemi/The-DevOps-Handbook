import re
import time
import subprocess
from prometheus_client import start_http_server, Gauge, REGISTRY
from decimal import Decimal

# Define the Prometheus metrics
duration_metric = Gauge('coredns_duration_seconds', 'Duration of CoreDNS queries', ['domain', 'source', 'reqtype', 'rescode'])
reqsize_metric = Gauge('coredns_request_size_bytes', 'Request size of CoreDNS queries', ['domain', 'source', 'reqtype', 'rescode'])
ressize_metric = Gauge('coredns_response_size_bytes', 'Response size of CoreDNS queries', ['domain', 'source', 'reqtype', 'rescode'])

# Regex to match CoreDNS log entries
log_pattern = re.compile(
    r"Domain: (\S+) \| Source: (\S+):(\d+) \| Duration: ([0-9\.]+)s \| ReqType: (\S+) \| ReqSize: (\d+) \| ResCode: (\S+) \| ResSize: (\d+)"
)

# Function to fetch logs from the last 15 seconds using journalctl
def fetch_logs():
    # Get logs from the last 15 seconds for the coredns service
    command = [
        "journalctl",
        "-u", "coredns",           # Log for coredns service
        "--since", "15 seconds ago",  # Fetch logs from the last 15 seconds
        "--output", "short"        # Short format output
    ]
    print(f"Running command: {' '.join(command)}")  # Debugging line
    result = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    for line in result.stdout:
        yield line.strip()

# Function to parse and update metrics
def parse_and_update_metrics():
    # Fetch new log entries
    log_lines = list(fetch_logs())  # Get the logs into a list

    # Clear all previous metric values for this 15-second cycle
    # Set the values to None so they're removed from the Prometheus scrape
    duration_metric.clear()
    reqsize_metric.clear()
    ressize_metric.clear()

    # Process the new log lines and update metrics
    for line in log_lines:
        print(f"Parsing line: {line}")  # Debugging line
        match = log_pattern.search(line)
        if match:
            # Extract log fields
            domain = match.group(1)
            source = match.group(2)
            reqtype = match.group(5)
            rescode = match.group(7)
            duration = float(match.group(4))
            formatted_duration = f"{duration:.9f}"
            reqsize = int(match.group(6))
            ressize = int(match.group(8))

            # Update the metrics with the new values
            print(f"Updating metrics for: {domain}, {source}, {reqtype}, {rescode}")  # Debugging line
            duration_metric.labels(domain=domain, source=source, reqtype=reqtype, rescode=rescode).set(formatted_duration)
            reqsize_metric.labels(domain=domain, source=source, reqtype=reqtype, rescode=rescode).set(reqsize)
            ressize_metric.labels(domain=domain, source=source, reqtype=reqtype, rescode=rescode).set(ressize)

# Function to periodically parse logs and update metrics every 15 seconds
def run_exporter():
    while True:
        parse_and_update_metrics()  # Update metrics every 15 seconds
        time.sleep(15)  # Wait for 15 seconds before refreshing the metrics

def deregister_unwanted_metrics():
    # Remove Python's default exporter-related metrics
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
    # Unregister metrics
    for metric_name in unwanted_metrics:
        if metric_name in REGISTRY._names_to_collectors:
            REGISTRY.unregister(REGISTRY._names_to_collectors[metric_name])

if __name__ == "__main__":
    # Deregister unwanted metrics before starting the exporter
    deregister_unwanted_metrics()

    # Start the Prometheus exporter on port 9160
    start_http_server(9160)
    print("Exporter running on http://0.0.0.0:9160/metrics")

    # Run the exporter
    run_exporter()


