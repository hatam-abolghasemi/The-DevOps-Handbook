#!/bin/bash

# RUN IT IN THE VM YOU WANT IT TO FILL ALL OF ITS MEMORY.
# Define the amount of memory to allocate in MB per iteration
MEMORY_PER_CHUNK_MB=100  # Adjust as needed
COUNTER=0
TEMP_DIR="/dev/shm/memory_test"

# Function to clean up allocated memory on exit
cleanup() {
  echo "Releasing memory..."
  rm -rf "$TEMP_DIR"
  echo "Memory released. Exiting."
  exit 0
}

# Set up trap for Ctrl+C to call the cleanup function
trap cleanup SIGINT

# Create temporary directory for memory allocation
mkdir -p "$TEMP_DIR"

echo "Starting memory consumption..."

# Loop to continuously allocate memory
while true; do
  # Allocate memory chunk in the temporary directory
  dd if=/dev/zero of="$TEMP_DIR/memory_chunk_$COUNTER" bs=1M count=$MEMORY_PER_CHUNK_MB >/dev/null 2>&1
  COUNTER=$((COUNTER + 1))

  # Display current memory usage
  free -m

  # Wait a bit before the next allocation
  sleep 2
done

