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

def count_queues(redis_host, redis_port, redis_password):
    commands = f"AUTH {redis_password}\nkeys *queues*"
    result = subprocess.run(
        ["redis-cli", "-h", redis_host, "-p", redis_port],
        input=commands,
        text=True,
        capture_output=True,
        check=True,
    )
    if result.returncode == 0:
        queues = [line for line in result.stdout.splitlines() if "queue" in line]
        return queues
    else:
        print(f"Failed to fetch keys: {result.stderr}")
        return []

def get_queue_job_count(redis_host, redis_port, redis_password, queue_name):
    commands = f"AUTH {redis_password}\nllen {queue_name}"
    result = subprocess.run(
        ["redis-cli", "-h", redis_host, "-p", redis_port],
        input=commands,
        text=True,
        capture_output=True,
        check=True,
    )
    if result.returncode == 0:
        try:
            job_count = int(result.stdout.strip().split()[-1])
            return job_count
        except ValueError:
            return 0
    else:
        print(f"Failed to get job count for {queue_name}: {result.stderr}")
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
    pod_name = os.getenv("POD_NAME", "unknown_pod")
    app_label = os.getenv("APP_LABEL", "unknown_app")
    pod_namespace = os.getenv("POD_NAMESPACE", "unknown_namespace")
    while True:
        try:
            redis_queue_count.clear()
            redis_queue_job_count.clear()
            queues = count_queues(redis_host, redis_port, redis_password)
            queue_count = len(queues)
            redis_queue_count.labels(pod=pod_name, app=app_label, namespace=pod_namespace).set(queue_count)
            for queue in queues:
                job_count = get_queue_job_count(redis_host, redis_port, redis_password, queue)
                redis_queue_job_count.labels(pod=pod_name, app=app_label, namespace=pod_namespace, queue=queue).set(job_count)
                print(f"Updated redis_queue_job_count for pod={pod_name}, app={app_label}, namespace={pod_namespace}, queue={queue}: {job_count}")
        except Exception as e:
            print(f"Error updating metrics: {e}")
        time.sleep(15)

if __name__ == "__main__":
    main()
