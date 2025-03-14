from prometheus_client import start_http_server, Gauge, REGISTRY
import requests
import time

# Configuration for endpoints and their desired output
ENDPOINTS = [
    {
        "url": "https://<3rd-part-url-1>",
        "expected_status": 404,
        "expected_body_substring": "Endpoint not found."
    },
    {
        "url": "https://<3rd-part-url-1>",
        "expected_status": 404,
        "expected_body_substring": "Invalid request"
    },
    # Add more endpoint configurations here
]

# Prometheus metric definition
third_party_status = Gauge(
    "third_party_status",
    "Status of third-party endpoints",
    ["endpoint"]
)

def check_endpoint(endpoint_config):
    """Checks an endpoint for desired status code and response body."""
    url = endpoint_config["url"]
    expected_status = endpoint_config.get("expected_status")
    expected_body_substring = endpoint_config.get("expected_body_substring")

    try:
        response = requests.get(url, timeout=5)
        status_code_match = (response.status_code == expected_status)
        body_match = (expected_body_substring in response.text)
        if status_code_match and body_match:
            return 1  # Metric value for success
        else:
            return 0  # Metric value for failure
    except Exception as e:
        print(f"Error checking endpoint {url}: {e}")
        return 0  # Metric value for failure

def update_metrics():
    """Updates the Prometheus metrics based on the endpoint checks."""
    for endpoint in ENDPOINTS:
        result = check_endpoint(endpoint)
        third_party_status.labels(endpoint=endpoint["url"]).set(result)


def deregister_unwanted_metrics():
    """
    Remove unwanted default metrics from Prometheus client registry.
    """
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
    deregister_unwanted_metrics()
    # Start Prometheus HTTP server on port 9109
    start_http_server(9109)
    print("Prometheus exporter is running on port 9109...")

    # Main loop to periodically update metrics
    while True:
        third_party_status.clear()
        update_metrics()
        time.sleep(15)  # Wait 15 seconds before the next check

if __name__ == "__main__":
    main()

