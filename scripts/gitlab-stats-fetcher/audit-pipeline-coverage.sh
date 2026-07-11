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

INPUT_FILE="./outputs/projects-languages.json"
OUTPUT_FILE="./outputs/pipeline-coverage.json"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "❌ Missing dependency: ${INPUT_FILE}. Please run step 2 first!"
  exit 1
fi

echo "🚀 Bootstrapping Pipeline Coverage & Branch Audit..."

# Safely extract total projects count from the JSON file directly using jq
TOTAL_PROJECTS=$(jq 'length' "$INPUT_FILE")

echo "📌 Total projects to audit: ${TOTAL_PROJECTS}"
echo "------------------------------------------------"

TEMP_OUTPUT=$(mktemp)
echo "[" > "$TEMP_OUTPUT"

CURRENT_COUNT=0
FIRST_ENTRY=true
TARGET_BRANCHES=("main" "master" "develop")

# Run the loop inside a subshell with relaxed exit monitoring to prevent premature EOF termination
(
  set +e
  
  # Stream clean, single-line JSON strings out of the file
  jq -c '.[]' "$INPUT_FILE" | while read -r row; do
    [[ -z "$row" ]] && continue
    
    PID=$(echo "$row" | jq '.project_id')
    P_NAME=$(echo "$row" | jq -r '.name')
    P_PATH=$(echo "$row" | jq -r '.path_with_namespace')
    P_LANG=$(echo "$row" | jq -r '.primary_language')
    P_UPDATED=$(echo "$row" | jq -r '.last_activity_at')
    
    CI_ENABLED="false"
    FOUND_BRANCH="none"
    
    # Short-circuit branch iteration logic
    for branch in "${TARGET_BRANCHES[@]}"; do
      FILE_ENDPOINT="${GITLAB_URL}/api/v4/projects/${PID}/repository/files/%2Egitlab%2Dci%2Eyml?ref=${branch}"
      
      HTTP_STATUS=$(curl --silent --output /dev/null --write-out "%{http_code}" \
        --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "$FILE_ENDPOINT")
      
      if [[ "$HTTP_STATUS" == "200" ]]; then
        CI_ENABLED="true"
        FOUND_BRANCH="$branch"
        break
      fi
    done
    
    if [ "$FIRST_ENTRY" = true ]; then
      FIRST_ENTRY=false
    else
      echo "," >> "$TEMP_OUTPUT"
    fi
    
    jq -n \
      --argjson id "$PID" \
      --arg name "$P_NAME" \
      --arg path "$P_PATH" \
      --arg lang "$P_LANG" \
      --arg updated "$P_UPDATED" \
      --argjson ci "$CI_ENABLED" \
      --arg branch "$FOUND_BRANCH" \
      '{"project_id": $id, "name": $name, "path_with_namespace": $path, "primary_language": $lang, "last_activity_at": $updated, "has_gitlab_ci": $ci, "detected_branch": $branch}' \
      >> "$TEMP_OUTPUT"
      
    ((CURRENT_COUNT++))
    PERCENTAGE=$(( CURRENT_COUNT * 100 / TOTAL_PROJECTS ))
    PRINTABLE_NAME="${P_NAME:0:25}"
    printf "\r⏳ Auditing: [%d/%d] (%d%%) | %-25s" "$CURRENT_COUNT" "$TOTAL_PROJECTS" "$PERCENTAGE" "$PRINTABLE_NAME"
  done
)

echo "]" >> "$TEMP_OUTPUT"
printf "\n\n✨ Audit complete. Formatting layout...\n"

# Beautify output payload
jq '.' "$TEMP_OUTPUT" > "$OUTPUT_FILE"
rm -f "$TEMP_OUTPUT"

echo "📝 Beautified metrics inventory saved to ${OUTPUT_FILE}"
echo "------------------------------------------------"
echo "📊 Coverage Summary Report:"
echo ""

jq -r '
  length as $total |
  (map(select(.has_gitlab_ci == true)) | length) as $ci_true |
  (map(select(.has_gitlab_ci == false)) | length) as $ci_false |
  (($ci_true / $total * 10000 | round) / 100) as $coverage_pct |
  "| Metric | Count | Percentage |\n| :--- | :--- | :--- |\n| **CI-Enabled Projects** | \($ci_true) | \($coverage_pct)% |\n| **Missing Pipeline Config** | \($ci_false) | \((100 - $coverage_pct | tonumber))% |\n| **Total Fleet Audited** | \($total) | 100% |"
' "$OUTPUT_FILE"

echo ""
echo "🌿 Branch Breakdown Table (Where .gitlab-ci.yml was located):"
echo "| Branch | Match Count |"
echo "| :--- | :--- |"
jq -r '
  group_by(.detected_branch) | 
  map({branch: .[0].detected_branch, count: length}) | 
  sort_by(.count) | reverse |
  .[] | "| \(.branch) | \(.count) |"
' "$OUTPUT_FILE"