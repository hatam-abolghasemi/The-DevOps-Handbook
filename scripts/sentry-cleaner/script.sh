#!/bin/bash

# Exit on any error
set -e

# Constants
MOUNT_POINT="/mnt/disk-2"
USAGE_THRESHOLD=70
LOG_DIR="/mnt/disk-2/docker/var/lib/docker/containers"

# Step 0: Check if sentry is up
echo "Checking Sentry health..."
CONTAINER_COUNT=$(docker ps | wc -l)
if [ "$CONTAINER_COUNT" -lt "69" ]; then
  cd /opt/sentry/self-hosted
  docker compose down --volumes
  docker volume rm sentry-kafka || true
  docker volume rm sentry-clickhouse || true
  bash ./install.sh --no-report-self-hosted-issues
  docker compose up -d
fi

# Step 1: Check disk usage
USAGE=$(df --output=pcent "$MOUNT_POINT" | tail -1 | tr -dc '0-9')
echo "Current disk usage of $MOUNT_POINT: ${USAGE}%"

# Exit if disk usage is below threshold
if [ "$USAGE" -lt "$USAGE_THRESHOLD" ]; then
  echo "Disk usage is below ${USAGE_THRESHOLD}%. Exiting."
  exit 0
fi

echo "Disk usage exceeds ${USAGE_THRESHOLD}%. Proceeding with maintenance..."

# Step 2: Stop Sentry services and remove selected volumes
cd /opt/sentry/self-hosted
echo "Stopping Sentry and removing volumes..."
docker compose down --volumes
docker volume rm sentry-kafka || true
docker volume rm sentry-clickhouse || true

# Step 3: Output logs from container JSON files
echo "Dumping Docker container logs..."
find "$LOG_DIR" -type f -name "*-json.log" | while read -r logfile; do
  echo "----- Contents of $logfile -----"
  cat "$logfile"
  echo ""
done

# Step 4: Reinstall and restart Sentry
echo "Reinstalling and starting Sentry..."
cd /opt/sentry/self-hosted
bash ./install.sh --no-report-self-hosted-issues
docker compose up -d

# Step 5: Truncate nodestore_node table
echo "Truncating nodestore_node table..."
docker exec -i sentry-self-hosted-postgres-1 bash -c 'psql -U postgres -c "TRUNCATE TABLE public.nodestore_node;"'

# Step 6: Vacuum the truncated table
echo "Vacuuming nodestore_node table..."
docker exec -i sentry-self-hosted-postgres-1 bash -c 'psql -U postgres -c "VACUUM FULL public.nodestore_node;"'

# Step 7: Healthcheck
echo "⏳ Waiting 1 minute before healthcheck..."
sleep 180

echo "🔍 Checking Sentry health..."
EXPECTED_COUNT=0
CURRENT_COUNT=$(docker ps -q | grep seconds | wc -l)

if [ "$CURRENT_COUNT" -lt "$EXPECTED_COUNT" ]; then
  echo "⚠️  Detected unhealthy or recently restarting containers:"
  cd /opt/sentry/self-hosted
  docker compose down --volumes
  docker volume rm sentry-kafka || true
  docker volume rm sentry-clickhouse || true
  bash ./install.sh --no-report-self-hosted-issues
  docker compose up -d
  echo "✅ Sentry restarted successfully."
else
  echo "✅ All Sentry containers are healthy. No action needed."
fi

echo "Done."
