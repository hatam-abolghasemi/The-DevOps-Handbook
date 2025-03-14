import os
import subprocess
import time
from prometheus_client import start_http_server, Gauge, REGISTRY

redis_queue_count = Gauge('redis_queue_count', 'Number of queues in Redis', 
                          labelnames=['pod', 'app', 'namespace'])
redis_queue_job_count = Gauge('redis_queue_job_count', 'Number of jobs in each Redis queue', 
                              labelnames=['pod', 'app', 'namespace', 'queue'])

def get_redis_credentials():
    redis_host = os.getenv("REDIS_HOST")
    redis_port = os.getenv("REDIS_PORT", "6379")
    redis_password = os.getenv("REDIS_PASSWORD")
    if not redis_host:
        print("Redis host not found in environment variables.")
        return None, None, None
    print(f"Redis connection details: host={redis_host}, port={redis_port}")
    return redis_host, redis_port, redis_password

def run_redis_command(redis_host, redis_port, redis_password, commands):
    try:
        process = subprocess.Popen(
            ["redis-cli", "-h", redis_host, "-p", redis_port],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        stdout, stderr = process.communicate(input=commands.encode(), timeout=14)
        if process.returncode == 0:
            return stdout.strip().decode()
        else:
            print("Command failed: {}".format(stderr.decode()))
            return None
    except Exception as e:
        print("Error running Redis command: {}".format(e))
        return None

def count_queues(redis_host, redis_port, redis_password):
    commands = "AUTH {}\nkeys *queues*".format(redis_password)
    output = run_redis_command(redis_host, redis_port, redis_password, commands)
    if output:
        queues = [line for line in output.splitlines() if "queue" in line]
        return queues
    return []

def get_queue_job_count(redis_host, redis_port, redis_password, queue_name):
    commands = "AUTH {}\nllen {}".format(redis_password, queue_name)
    output = run_redis_command(redis_host, redis_port, redis_password, commands)
    if output:
        try:
            return int(output.split()[-1])
        except ValueError:
            return 0
    return 0

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
    deregister_unwanted_metrics()
    start_http_server(9107)
    print("Redis exporter started on port 9107.")
    redis_host, redis_port, redis_password = get_redis_credentials()
    if not redis_host:
        return
    pod_name = "alopeyk-redis-1"
    app_label = "alopeyk-app"
    pod_namespace = "prod"

    while True:
        start_time = time.time()
        try:
            queues = count_queues(redis_host, redis_port, redis_password)
            queue_job_counts = {}
            for queue in queues:
                job_count = get_queue_job_count(redis_host, redis_port, redis_password, queue)
                queue_job_counts[queue] = job_count
            elapsed_time = time.time() - start_time
            if elapsed_time > 14:
                print("Data fetch exceeded time limit, skipping update.")
                continue
            redis_queue_count.clear()
            redis_queue_job_count.clear()
            redis_queue_count.labels(pod=pod_name, app=app_label, namespace=pod_namespace).set(len(queues))
            for queue, job_count in queue_job_counts.items():
                redis_queue_job_count.labels(pod=pod_name, app=app_label, namespace=pod_namespace, queue=queue).set(job_count)
        except Exception as e:
            print("Error updating metrics: {}".format(e))
        time.sleep(1)

if __name__ == "__main__":
    main()
