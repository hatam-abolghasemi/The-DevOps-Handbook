#!/bin/bash

# This script assumes that you have set the root directories of docker and containerd on a
# dedicated second disk mounted on /mnt/disk-2.
set -e
stop_attempt=0
MAX_STOP_ATTEMPTS=60
MOUNT_POINT="/mnt/disk-2"
THRESHOLD=80
WAIT_INTERVAL=30
MAX_ATTEMPTS=120
DOCKER_DIR="$MOUNT_POINT/docker"
CONTAINERD_DIR="$MOUNT_POINT/containerd"
DOCKER_SERVICE="docker.service"
DOCKER_SOCKET="docker.socket"
CONTAINERD_SERVICE="containerd.service"
GITLAB_RUNNER_SERVICE="gitlab-runner.service"

# Here you must set the images that need to be pre-pulled and you don't want to make your
# pipelines wait for these images to be pulled
IMAGES=(
  "<image-1>"
  "<image-2>"
)
echo "Checking disk usage of $MOUNT_POINT..."
USAGE=$(df --output=pcent "$MOUNT_POINT" | tail -1 | tr -dc '0-9')
echo "Disk usage: $USAGE%"
if [ "$USAGE" -lt "$THRESHOLD" ]; then
  echo "Disk usage is below ${THRESHOLD}%. Exiting."
  exit 0
fi
echo "Disk usage is above ${THRESHOLD}%. Proceeding with cleanup..."
attempt=0
while true; do
  container_count=$(docker ps -q | wc -l)
  echo "Running containers: $container_count"
  if [ "$container_count" -eq 0 ]; then
    echo "No containers are running. Continuing..."
    break
  fi
  attempt=$((attempt + 1))
  if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
    echo "Max wait time reached (~60 hours). Continuing anyway..."
    break
  fi
  echo "Containers still running. Attempt $attempt/$MAX_ATTEMPTS. Sleeping for ${WAIT_INTERVAL}s..."
  sleep "$WAIT_INTERVAL"
done
echo "Stopping GitLab Runner service..."
systemctl stop "$GITLAB_RUNNER_SERVICE"
echo "Stopping Docker and containerd service..."
systemctl stop "$DOCKER_SERVICE"
systemctl stop "$CONTAINERD_SERVICE"
echo "Stopping Docker socket..."
systemctl stop "$DOCKER_SOCKET"
echo "Masking Docker socket to prevent auto-start..."
systemctl mask "$DOCKER_SOCKET"
echo "Waiting for Docker and GitLab Runner services to fully stop..."
sleep 60
echo "Deleting Docker and containerd directories: $DOCKER_DIR $CONTAINERD"
rm -rf "$DOCKER_DIR" "$CONTAINERD_DIR"
echo "Docker directory deleted."
echo "Unmasking Docker socket..."
systemctl unmask "$DOCKER_SOCKET"
echo "Starting Docker service..."
systemctl start "$CONTAINERD_SERVICE"
systemctl start "$DOCKER_SERVICE"
echo "Pulling required Docker images..."
for image in "${IMAGES[@]}"; do
  echo "Pulling: $image"
  docker pull "$image"
done
echo "Starting GitLab Runner service..."
systemctl start "$GITLAB_RUNNER_SERVICE"
runner_status=$(systemctl is-active "$GITLAB_RUNNER_SERVICE")
echo "GitLab Runner service status after start: $runner_status"
echo "Cleanup and restoration process completed successfully."
