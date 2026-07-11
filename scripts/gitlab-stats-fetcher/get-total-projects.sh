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
OUTPUT_FILE="${OUTPUT_DIR}/total-projects-count.json"

echo "🚀 Bootstrapping ordered multi-dimensional GitLab Project Audit..."

# Helper function to handle GitLab pagination for group lists
fetch_paginated_groups() {
    local query_params="$1"
    local url="${GITLAB_URL}/api/v4/groups?per_page=100&${query_params}"
    while [[ -n "$url" ]]; do
        local response
        response=$(curl --silent --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "$url")
        echo "$response" | jq -c '.[]'
        
        # Parse next page header
        url=$(curl --silent -I --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "$url" \
              | grep -i 'next:' \
              | awk '{print $2}' \
              | tr -d '\r')
    done
}

# Helper function to get project count for a specific group (including its nested subgroups)
get_group_project_count() {
    local group_id="$1"
    local count
    count=$(curl --silent -I --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" \
        "${GITLAB_URL}/api/v4/groups/${group_id}/projects?include_subgroups=true&per_page=1" \
        | grep -i 'x-total:' \
        | awk '{print $2}' \
        | tr -d '\r')
    echo "${count:-0}"
}

# 1. Global Total Fleet Count
echo "📊 Extracting global fleet numbers..."
GLOBAL_TOTAL=$(curl --silent -I --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "${GITLAB_URL}/api/v4/projects?per_page=1" \
    | grep -i 'x-total:' \
    | awk '{print $2}' \
    | tr -d '\r')
GLOBAL_TOTAL="${GLOBAL_TOTAL:-0}"

# Initialize temp files for structural array construction
ROOT_GROUPS_JSON=$(mktemp)
ALL_GROUPS_JSON=$(mktemp)

echo "📂 Processing Root Groups (Top-Level Only)..."
echo "[" > "$ROOT_GROUPS_JSON"
FIRST=true
while read -r group; do
    [[ -z "$group" ]] && continue
    G_ID=$(echo "$group" | jq '.id')
    G_NAME=$(echo "$group" | jq -r '.name')
    G_PATH=$(echo "$group" | jq -r '.full_path')
    
    P_COUNT=$(get_group_project_count "$G_ID")
    
    if [ "$FIRST" = true ]; then FIRST=false; else echo "," >> "$ROOT_GROUPS_JSON"; fi
    jq -n --arg id "$G_ID" --arg name "$G_NAME" --arg path "$G_PATH" --arg count "$P_COUNT" \
      '{"group_id": ($id | tonumber), "name": $name, "full_path": $path, "total_projects": ($count | tonumber)}' >> "$ROOT_GROUPS_JSON"
done < <(fetch_paginated_groups "top_level_only=true")
echo "]" >> "$ROOT_GROUPS_JSON"

echo "🌿 Processing All Groups & Subgroups (Granular View)..."
echo "[" > "$ALL_GROUPS_JSON"
FIRST=true
while read -r group; do
    [[ -z "$group" ]] && continue
    G_ID=$(echo "$group" | jq '.id')
    G_NAME=$(echo "$group" | jq -r '.name')
    G_PATH=$(echo "$group" | jq -r '.full_path')
    
    # Direct projects only (no subgroups) to avoid duplicating sub-counts in this granular array
    P_COUNT=$(curl --silent -I --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "${GITLAB_URL}/api/v4/groups/${G_ID}/projects?include_subgroups=false&per_page=1" \
        | grep -i 'x-total:' \
        | awk '{print $2}' \
        | tr -d '\r')
    P_COUNT="${P_COUNT:-0}"
    
    if [ "$FIRST" = true ]; then FIRST=false; else echo "," >> "$ALL_GROUPS_JSON"; fi
    jq -n --arg id "$G_ID" --arg name "$G_NAME" --arg path "$G_PATH" --arg count "$P_COUNT" \
      '{"group_id": ($id | tonumber), "name": $name, "full_path": $path, "direct_projects": ($count | tonumber)}' >> "$ALL_GROUPS_JSON"
done < <(fetch_paginated_groups "all_available=true")
echo "]" >> "$ALL_GROUPS_JSON"

# Sort data and extract summary arrays using jq
# - Sort root_groups descending by total_projects
# - Sort all_groups_and_subgroups descending by direct_projects
# - Dynamically count size of arrays for global block
jq -n \
  --argjson global "$GLOBAL_TOTAL" \
  --argjson root "$(cat "$ROOT_GROUPS_JSON")" \
  --argjson all "$(cat "$ALL_GROUPS_JSON")" \
  '
    ($root | sort_by(.total_projects) | reverse) as $safe_root |
    ($all | sort_by(.direct_projects) | reverse) as $safe_all |
    {
      "global": { 
        "total_projects": ($global | tonumber),
        "total_root_groups": ($safe_root | length),
        "total_all_groups_and_subgroups": ($safe_all | length)
      },
      "root_groups": $safe_root,
      "all_groups_and_subgroups": $safe_all
    }
  ' > "$OUTPUT_FILE"

# Clean up memory
rm -f "$ROOT_GROUPS_JSON" "$ALL_GROUPS_JSON"

echo "✨ Sorted dimensional analysis complete! Check the layout here: ${OUTPUT_FILE}"