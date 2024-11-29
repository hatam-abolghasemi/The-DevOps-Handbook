import subprocess
from prometheus_client import start_http_server, Gauge, REGISTRY
import time
import os

# Define Prometheus metrics with 'pid' and 'rss' as labels for memory
cpu_gauge = Gauge('process_cpu', 'CPU Usage in percentage', ['user', 'command', 'pid', 'threads'])
mem_gauge = Gauge('process_mem', 'Memory Usage in percentage', ['user', 'command', 'pid', 'rss'])

def parse_ps_output():
    # Clear existing labels before updating to prevent appending old metrics
    cpu_gauge.clear()
    mem_gauge.clear()

    # Run the 'ps' command with args for full command details (top CPU and top MEM)
    result_mem = subprocess.run(['ps', '-eo', 'pid,user,%cpu,%mem,rss,comm,args', '--sort=-%mem'], stdout=subprocess.PIPE)
    result_cpu = subprocess.run(['ps', '-eo', 'pid,user,%cpu,%mem,rss,comm,args', '--sort=-%cpu'], stdout=subprocess.PIPE)
    
    output_mem = result_mem.stdout.decode('utf-8').splitlines()
    output_cpu = result_cpu.stdout.decode('utf-8').splitlines()

    # Parse the output and keep top 10 processes for each
    processes_mem = parse_ps_lines(output_mem)
    processes_cpu = parse_ps_lines(output_cpu)

    # Update Prometheus gauges
    for pid, user, cpu, mem, rss, _, command in processes_mem:  # Ignore threads for mem_gauge
        mem_gauge.labels(user=user, command=command, pid=pid, rss=rss).set(mem)

    for pid, user, cpu, _, rss, threads, command in processes_cpu:
        cpu_gauge.labels(user=user, command=command, pid=pid, threads=threads).set(cpu)

def get_threads(pid):
    """Get the number of threads for a process by reading /proc/<pid>/status"""
    try:
        with open('/proc/{}/status'.format(pid), 'r') as f:
            for line in f:
                if line.startswith("Threads"):
                    return int(line.split()[1])  # Return the number of threads
    except FileNotFoundError:
        return 0  # In case the process has terminated by the time we check
    except ValueError:
        return 0  # In case the Threads field is not formatted as expected

def parse_ps_lines(output):
    """Parse the output of `ps` command into structured data."""
    processes = []
    for line in output[1:]:  # Skip header
        columns = line.split(None, 7)  # Split into 8 fields, with the last being the full command and comm
        if len(columns) < 8:
            continue  # Skip malformed lines
        
        pid, user, cpu, mem, rss, threads, comm, args = columns
        
        # Safely convert values to the correct types and handle any invalid input
        try:
            pid = int(pid)  # Ensure pid is an integer
            cpu = float(cpu)  # Ensure cpu is a float
            mem = float(mem)  # Ensure mem is a float
            rss = int(rss)  # Ensure rss is an integer
        except ValueError as e:
            print("Skipping process due to error: {} - line: {}".format(e, line))
            continue  # Skip the process if there was an error parsing its values
        
        # Get the number of threads from /proc/<pid>/status
        threads = get_threads(pid)
        
        # Combine comm and args to create the full command
        command = "{} {}".format(comm, args).strip()
        
        processes.append((pid, user, cpu, mem, rss, threads, command))
    return processes[:10]  # Keep top 10 processes

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

def run_exporter():
    deregister_unwanted_metrics()
    # Start process-exporter on port 9102
    start_http_server(9102)
    print("process-exporter started at http://0.0.0.0:9102")
    
    # Update metrics every 5 seconds
    while True:
        parse_ps_output()
        time.sleep(5)

if __name__ == '__main__':
    run_exporter()

