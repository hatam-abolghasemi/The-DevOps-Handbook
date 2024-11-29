import subprocess
import argparse
import re
from prometheus_client import start_http_server, Gauge, REGISTRY
import time

# Define Prometheus metrics
SERVICE_STATUS_ENABLED = Gauge(
    'service_status_enabled', 
    'Indicates if systemd service is enabled (1 for enabled, 0 for disabled)',
    labelnames=['name', 'service_path', 'status', 'uptime', 'pid', 'command']
)

# Function to get the systemctl status of a service and parse the required fields
def get_service_status(name):
    try:
        # Run the systemctl status command for the given service
        result = subprocess.run(['systemctl', 'status', name], capture_output=True, text=True)
        output = result.stdout

        service_status = {}

        # Get the service path from systemctl cat
        result_path = subprocess.run(['systemctl', 'cat', name], capture_output=True, text=True)
        path_output = result_path.stdout

        # Extract the service path (first line of systemctl cat output) and remove the "# " prefix
        service_status['service_path'] = path_output.splitlines()[0].lstrip('# ').strip() if path_output else 'unknown'

        # Extracting the service name
        service_status['name'] = name

        # Check if the service is enabled or disabled using systemctl is-enabled
        result_enabled = subprocess.run(['systemctl', 'is-enabled', name], capture_output=True, text=True)
        service_status['enabled'] = 1 if result_enabled.returncode == 0 and 'enabled' in result_enabled.stdout else 0

        # Extracting service active state (running or inactive)
        match_status = re.search(r'Active: (\S+)', output)
        service_status['status'] = match_status.group(1) if match_status else 'unknown'

        # Extracting service uptime (in the format '1 day 23h')
        match_uptime = re.search(r'Active:.*since.*;\s*(.*) ago', output)
        service_status['uptime'] = match_uptime.group(1) if match_uptime else 'unknown'

        # Extracting PID (main process)
        match_pid = re.search(r'Main PID: (\d+)', output)
        service_status['pid'] = match_pid.group(1) if match_pid else 'unknown'

        # Get the command from the systemd service file using systemctl cat
        result_command = subprocess.run(['systemctl', 'cat', name], capture_output=True, text=True)
        command_output = result_command.stdout

        # Extract the command from the ExecStart line
        match_command = re.search(r'ExecStart=(.*)', command_output)
        service_status['command'] = match_command.group(1).strip() if match_command else 'unknown'

        return service_status

    except Exception as e:
        print("Error retrieving status for service {}: {}".format(name, e))
        return None

# Function to collect service status and expose it as Prometheus metrics
def collect_service_metrics(services):
    # Clear old metrics before setting new ones to overwrite the values
    SERVICE_STATUS_ENABLED.clear()

    for service in services:
        service_status = get_service_status(service)
        if service_status:
            # Set the 'enabled' metric as the metric value (1 for enabled, 0 for disabled)
            SERVICE_STATUS_ENABLED.labels(
                name=service_status['name'],
                service_path=service_status['service_path'],
                status=service_status['status'],
                uptime=service_status['uptime'],
                pid=service_status['pid'],
                command=service_status['command']
            ).set(service_status['enabled'])  # The value is 'enabled' (1 or 0)

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

# Start Prometheus HTTP server
def start_prometheus_server():
    # Start the HTTP server to expose the metrics at port 9103
    start_http_server(9103)

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Retrieve and expose service status information as Prometheus metrics.")
    parser.add_argument('--service', type=str, required=True, help="Comma-separated list of service names")
    args = parser.parse_args()

    # Split the service names and iterate over each one
    services = args.service.split(',')

    deregister_unwanted_metrics()

    # Start Prometheus server in a separate thread
    start_prometheus_server()

    # Continuously collect metrics and update them every 5 seconds
    while True:
        collect_service_metrics(services)
        time.sleep(5)  # Sleep for 5 seconds before collecting again

if __name__ == "__main__":
    main()
