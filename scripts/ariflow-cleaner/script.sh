#!/bin/bash

# Run this script at /data/logs/dag_id=zap_orders_external or any other dag directory to cleanup a DAG's log safely.
# This script only cleans the content of the log file. It doesn't remove them.
# Loop through each directory matching the pattern
for dir in run_id=scheduled__*; do
    # Check if the directory exists
    if [[ -d "$dir" ]]; then
        # Define the path to the log file
        log_file="$dir/task_id=query/attempt=1.log" # Replace 'some_log_file.log' with the actual log file name if needed

        # Check if the log file exists
        if [[ -f "$log_file" ]]; then
            # Empty the log file
            : > "$log_file"
            echo "Cleared: $log_file"
        else
            echo "Log file not found: $log_file"
        fi
    fi
done

