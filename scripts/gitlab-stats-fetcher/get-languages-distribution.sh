#!/usr/bin/env bash

set -euo pipefail

# --- CONFIGURATION ---
ENV_FILE=".env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "❌ missing .env"
  exit 1
fi

OUTPUT_DIR="../outputs"
mkdir -p "$OUTPUT_DIR"
RAW_OUTPUT_FILE="${OUTPUT_DIR}/projects-languages.json"
TEMP_RAW_FILE=$(mktemp)

echo "🚀 Bootstrapping Language Distribution Matrix Audit..."

# 1. Fetch total count first for progress calculation
echo "📊 Fetching global fleet metrics for progress tracking..."
TOTAL_FLEET=$(curl --silent -I --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "${GITLAB_URL}/api/v4/projects?archived=false&per_page=1" \
    | grep -i 'x-total:' \
    | awk '{print $2}' \
    | tr -d '\r')
TOTAL_FLEET="${TOTAL_FLEET:-0}"

if [ "$TOTAL_FLEET" -eq 0 ]; then
    echo "❌ Error: Could not determine total project fleet size. Exiting."
    rm -f "$TEMP_RAW_FILE"
    exit 1
fi

echo "📌 Total projects to process: $TOTAL_FLEET"
echo "------------------------------------------------"

# Initialize variables for loop
echo "[" > "$TEMP_RAW_FILE"
PAGE=1
PROCESSED_COUNT=0
FIRST_ENTRY=true

while true; do
  # Fetch a batch of 100 projects
  RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects?per_page=100&page=${PAGE}&archived=false")
  
  # Clean verification if page returns empty array
  if [[ "$RESPONSE" == "[]" || -z "$RESPONSE" ]]; then
    break
  fi
  
  # Use an explicit subshell configuration to process the stream safely under set -e
  (
    # Temporarily allow the read stream to hit EOF safely without triggering set -e termination
    set +e
    echo "$RESPONSE" | jq -c '.[]' | while read -r project; do
      [[ -z "$project" ]] && continue
      
      PID=$(echo "$project" | jq '.id')
      P_NAME=$(echo "$project" | jq -r '.name')
      P_PATH=$(echo "$project" | jq -r '.path_with_namespace')
      P_UPDATED=$(echo "$project" | jq -r '.last_activity_at')
      
      # Fetch languages for this specific project
      LANG_RESP=$(curl --silent --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${PID}/languages")
      
      PRIMARY_LANG=$(echo "$LANG_RESP" | jq -r 'to_entries | sort_by(.value) | last | .key // "Unknown/Empty"')
      
      # Manage JSON commas cleanly inside the temp file
      if [ "$FIRST_ENTRY" = true ]; then
        FIRST_ENTRY=false
      else
        echo "," >> "$TEMP_RAW_FILE"
      fi
      
      # Write metadata to temp file
      jq -n \
        --arg id "$PID" \
        --arg name "$P_NAME" \
        --arg path "$P_PATH" \
        --arg lang "$PRIMARY_LANG" \
        --arg updated "$P_UPDATED" \
        '{"project_id": ($id | tonumber), "name": $name, "path_with_namespace": $path, "primary_language": $lang, "last_activity_at": $updated}' \
        >> "$TEMP_RAW_FILE"
        
      # Update progress metrics globally shared parameters
      ((PROCESSED_COUNT++))
      PERCENTAGE=$(( PROCESSED_COUNT * 100 / TOTAL_FLEET ))
      
      PRINTABLE_NAME="${P_NAME:0:25}"
      printf "\r⏳ Processing: [%d/%d] (%d%%) | Current: %-25s" "$PROCESSED_COUNT" "$TOTAL_FLEET" "$PERCENTAGE" "$PRINTABLE_NAME"
    done
  )

  # Sync the loop context's tracking metrics based on what was added to the file
  PROCESSED_COUNT=$(grep -c '"project_id"' "$TEMP_RAW_FILE" || true)
  if [ "$PROCESSED_COUNT" -eq 0 ]; then
     FIRST_ENTRY=true
  else
     FIRST_ENTRY=false
  fi
  
  ((PAGE++))
done

echo "]" >> "$TEMP_RAW_FILE"
printf "\n\n✨ All projects fetched. Beautifying JSON payload...\n"

# 2. Beautify the final output JSON using jq
jq '.' "$TEMP_RAW_FILE" > "$RAW_OUTPUT_FILE"
rm -f "$TEMP_RAW_FILE"

echo "📝 Beautified project inventory saved to ${RAW_OUTPUT_FILE}"
echo "------------------------------------------------"
echo "📊 Language Distribution Matrix:"
echo ""

# Use jq to crunch numbers and calculate precise fleet percentages
jq -r '
  length as $total_fleet |
  group_by(.primary_language) |
  map({
    language: .[0].primary_language,
    count: length,
    percentage: ((length / $total_fleet * 10000 | round) / 100)
  }) |
  sort_by(.count) | reverse |
  . + [{"language": "Total", "count": $total_fleet, "percentage": 100}] |
  .[] |
  "| **\(.language)** | \(.count) | \(.percentage)% |"
' "$RAW_OUTPUT_FILE" > /tmp/matrix_rows.txt

echo "| Language | Total Repositories | Percentage of Fleet |"
echo "| :--- | :--- | :--- |"
cat /tmp/matrix_rows.txt
rm -f /tmp/matrix_rows.txt