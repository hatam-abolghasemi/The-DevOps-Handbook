#!/bin/bash

df_output=$(df -h)
root_line=$(echo "$df_output" | grep root)
available_space_before_cleanup=$(echo "$root_line" | awk '{print $4}')

cd /opt/sentry/self-hosted
echo "** Starting Sentry cleanup and rebuild process **"
restarting_containers=$(sudo docker ps --filter status=restarting --quiet)
if [[ ! -z "$restarting_containers" ]]; then
  echo "** Error: Found restarting containers. Aborting cleanup."
  exit 1
fi
all_running=$(sudo docker ps --filter status=running --quiet)
if [[ -z "$all_running" ]]; then
  echo "** Error: No running containers found. Aborting cleanup."
  exit 1
fi
echo "* Stopping Sentry services and removing volumes"
sudo docker-compose down --volumes
echo "* Removing sentry-kafka and sentry-zookeeper volumes"
sudo docker volume rm sentry-kafka sentry-zookeeper
echo "* Running Sentry installation script"
http_proxy="http://proxy.alopeyk.com:8118" https_proxy="https://proxy.alopeyk.com:8118" sudo bash ./install.sh --no-report-self-hosted-issues
echo "* Starting Sentry services in the background"
sudo docker-compose up -d

container_id=$(sudo docker ps --filter name=sentry-self-hosted_postgres_1 --format '{{.ID}}')
if [[ -z "$container_id" ]]; then
  echo "** Error: Could not find Postgres container. Skipping postgres cleanup."
else
  echo "* Connecting to Postgres container ($container_id)"
  sudo docker exec -it "$container_id" bash -c 'psql -U postgres -c "TRUNCATE TABLE public.nodestore_node;"'
  sudo docker exec -it "$container_id" bash -c 'psql -U postgres -c "VACUUM FULL public.nodestore_node;"'
fi

df_output=$(df -h)
root_line=$(echo "$df_output" | grep root)
available_space_after_cleanup=$(echo "$root_line" | awk '{print $4}')
echo "Available Space Before Cleanup: $available_space_before_cleanup"
echo "Available Space After Cleanup: $available_space_after_cleanup"
