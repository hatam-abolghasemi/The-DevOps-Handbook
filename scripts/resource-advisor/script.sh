#!/bin/bash

# Function: Next power of two
next_power_of_two() {
    local n=$1
    local p=1
    while [ $p -lt $n ]; do
        p=$((p * 2))
    done
    echo $p
}

# Parse args
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --cpu)
        CPU_AVG="$2"
        CPU_MAX="$3"
        shift 3
        ;;
        --mem)
        MEM_AVG="$2"
        MEM_MAX="$3"
        shift 3
        ;;
        *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

if [[ -z "$CPU_AVG" || -z "$CPU_MAX" || -z "$MEM_AVG" || -z "$MEM_MAX" ]]; then
    echo "Usage: $0 --cpu <avg> <max> --mem <avg> <max>"
    exit 1
fi

# CPU calculations (millicores)
REQ_CPU_INT=$(printf "%.0f" $(echo "($CPU_AVG + 0.999)" | bc))   # ceil avg
REQ_CPU_MILLICORES=$((REQ_CPU_INT))

MAX_CPU_INT=$(printf "%.0f" $(echo "($CPU_MAX + 0.999)" | bc))   # ceil max
LIM_CPU_MILLICORES=$((MAX_CPU_INT * 2))

# Memory calculations (bytes → next power of two → Mi)
REQ_MEM_BYTES=$(next_power_of_two "$MEM_AVG")
REQ_MEM_Mi=$((REQ_MEM_BYTES / 1024 / 1024))

SCALED_MAX_MEM=$(printf "%.0f" $(echo "$MEM_MAX * 1.2" | bc -l))
LIM_MEM_BYTES=$(next_power_of_two "$SCALED_MAX_MEM")
LIM_MEM_Mi=$((LIM_MEM_BYTES / 1024 / 1024))

# Fix memory limit if ≤ request by scaling request * 1.2 without rounding to power of two
if [ "$LIM_MEM_BYTES" -le "$REQ_MEM_BYTES" ]; then
    # new limit bytes = 1.2 * request bytes rounded up to integer
    NEW_LIMIT_BYTES=$(printf "%.0f" $(echo "$REQ_MEM_BYTES * 1.2" | bc -l))
    LIM_MEM_BYTES=$NEW_LIMIT_BYTES
    LIM_MEM_Mi=$(( (LIM_MEM_BYTES + 1024*1024 -1) / (1024*1024) ))  # ceil bytes to Mi
fi

# Output YAML format
echo "    cpu:"
echo "      limits: \"${LIM_CPU_MILLICORES}m\""
echo "      requests: \"${REQ_CPU_MILLICORES}m\""
echo "    memory:"
echo "      limits: \"${LIM_MEM_Mi}Mi\""
echo "      requests: \"${REQ_MEM_Mi}Mi\""

