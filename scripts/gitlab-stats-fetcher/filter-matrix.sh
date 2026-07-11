#!/usr/bin/env bash

set -euo pipefail

DB_FILE="../outputs/pipeline-coverage.json"

if [[ ! -f "$DB_FILE" ]]; then
  echo "❌ Error: Master database file not found at ${DB_FILE}"
  echo "Please run Step 3 first to generate the dataset."
  exit 1
fi

# Calculate dynamic boundary dates relative to current time (2026)
DATE_30_DAYS_AGO=$(date -d "30 days ago" +%Y-%m-%dT%H:%M:%SZ)
DATE_90_DAYS_AGO=$(date -d "90 days ago" +%Y-%m-%dT%H:%M:%SZ)
DATE_180_DAYS_AGO=$(date -d "180 days ago" +%Y-%m-%dT%H:%M:%SZ)

clear
echo "========================================================"
echo "🎛️  GitLab Fleet Advanced Multi-Filter Matrix CLI"
echo "========================================================"
echo "Database Status: Active | $(jq 'length' "$DB_FILE") Projects Indexed"
echo "--------------------------------------------------------"
echo "Select a pre-compiled compound audit filter:"
echo ""
echo "1) Active Risk: Missing CI configs on active repos (Updated last 30 days)"
echo "2) Stale Infrastructure: Repos with NO activity for 180+ days"
echo "3) Legacy Assets: Repos with CI enabled but NO updates for 90+ days"
echo "4) Custom Matrix Query: Filter by Language, CI Status, and Recency"
echo "5) Exit Matrix"
echo "--------------------------------------------------------"
read -rp "Enter choice [1-5]: " CHOICE

render_output() {
  local jq_filter="$1"
  local title="$2"
  local count_cond="$3"
  local show_summary="${4:-false}"
  
  echo ""
  echo "🔍 Running: $title"
  echo "------------------------------------------------------------------------------------------------"
  
  # Temporary file to store structural rows before formatting via column tool
  local TEMP_TABLE
  TEMP_TABLE=$(mktemp)
  
  # Print headers into the layout
  echo "Project_Path|Language|CI_Enabled|Last_Activity" > "$TEMP_TABLE"
  echo "---|---|---|---" >> "$TEMP_TABLE"
  
  # Run clean JQ extraction safely passing strings across pipes
  jq -r "$jq_filter" "$DB_FILE" >> "$TEMP_TABLE"
  
  # Format table into beautifully spaced alignments using native system tools
  column -t -s '|' "$TEMP_TABLE"
  rm -f "$TEMP_TABLE"
  
  # Count matches accurately
  local total_matches
  total_matches=$(jq "[ .[] | select($count_cond) ] | length" "$DB_FILE")
  
  echo "------------------------------------------------------------------------------------------------"
  echo "📊 Total Matches Found: $total_matches"
  
  # Build and append the dynamic one-line breakdown if requested
  if [[ "$show_summary" == "true" ]]; then
    printf "📈 Fleet Distribution: "
    jq -r --arg dynamic_30 "$DATE_30_DAYS_AGO" "[
      .[] | select($count_cond)
    ] | 
    (map(select(.last_activity_at >= \$dynamic_30)) | length) as \$recent_30 |
    group_by(.primary_language) | 
    map({lang: .[0].primary_language, count: length}) | 
    sort_by(.count) | reverse | 
    map(\"\(.lang):\(.count)\") | join(\", \") | 
    \"Total matching breakdown [\(.)] | Updates inside last 30 days: \(\$recent_30)\"
    " "$DB_FILE"
  fi
  echo ""
}

case "$CHOICE" in
  1)
    JQ_COND="(.has_gitlab_ci == false or .has_gitlab_ci == \"false\") and .last_activity_at >= \"$DATE_30_DAYS_AGO\""
    FILTER=".[] | select($JQ_COND) | \"\(.path_with_namespace)|\(.primary_language)|\(.has_gitlab_ci)|\(.last_activity_at[0:19])\""
    render_output "$FILTER" "Missing CI on Active Repositories (Last 30 Days)" "$JQ_COND"
    ;;
    
  2)
    JQ_COND=".last_activity_at < \"$DATE_180_DAYS_AGO\""
    FILTER=".[] | select($JQ_COND) | \"\(.path_with_namespace)|\(.primary_language)|\(.has_gitlab_ci)|\(.last_activity_at[0:19])\""
    render_output "$FILTER" "Stale Infrastructure (No updates for 180+ Days)" "$JQ_COND"
    ;;

  3)
    JQ_COND="(.has_gitlab_ci == true or .has_gitlab_ci == \"true\") and .last_activity_at < \"$DATE_90_DAYS_AGO\""
    FILTER=".[] | select($JQ_COND) | \"\(.path_with_namespace)|\(.primary_language)|\(.has_gitlab_ci)|\(.last_activity_at[0:19])\""
    render_output "$FILTER" "Orphaned CI Pipelines (CI Enabled, but un-updated for 90+ Days)" "$JQ_COND"
    ;;

  4)
    echo ""
    echo "--- Custom Matrix Wizard ---"
    read -rp "Target Language (e.g., Go, Python, TypeScript, or 'any'): " USR_LANG
    USR_LANG="${INPUT_LANG:-any}"
    read -rp "CI Status Target (true / false / any): " USR_CI
    USR_CI="${INPUT_CI:-true}"
    read -rp "Recency Max Days (e.g., 30, 90, 365, or 'any'): " USR_DAYS
    USR_DAYS="${INPUT_DAYS:-365}"
    
    # Construct fluid selection matrices
    JQ_SELECT="true"
    
    if [[ "${USR_LANG,,}" != "any" ]]; then
      JQ_SELECT="$JQ_SELECT and (.primary_language | ascii_downcase) == \"${USR_LANG,,}\""
    fi
    
    if [[ "${USR_CI,,}" != "any" ]]; then
      JQ_SELECT="$JQ_SELECT and (.has_gitlab_ci | tostring) == \"${USR_CI,,}\""
    fi
    
    if [[ "${USR_DAYS,,}" != "any" ]]; then
      TARGET_DATE=$(date -d "$USR_DAYS days ago" +%Y-%m-%dT%H:%M:%SZ)
      JQ_SELECT="$JQ_SELECT and .last_activity_at >= \"$TARGET_DATE\""
    fi
    
    # Notice the sort_by(.last_activity_at) | reverse addition to keep fresh commits on top
    DYNAMIC_FILTER="[ .[] | select($JQ_SELECT) ] | sort_by(.last_activity_at) | reverse | .[] | \"\(.path_with_namespace)|\(.primary_language)|\(.has_gitlab_ci)|\(.last_activity_at[0:19])\""
    render_output "$DYNAMIC_FILTER" "Custom Query [Lang: $USR_LANG | CI: $USR_CI | Window: $USR_DAYS days]" "$JQ_SELECT" "true"
    ;;
    
  5)
    echo "👋 Exiting matrix workspace."
    exit 0
    ;;
    
  *)
    echo "❌ Invalid Selection."
    exit 1
    ;;
esac