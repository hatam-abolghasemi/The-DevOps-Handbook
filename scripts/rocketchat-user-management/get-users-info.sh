#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
nowdate="$(date +%Y-%m-%d_%H-%M-%S)"
OUTPUT_DIR="$SCRIPT_DIR/../outputs"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/users-info-$nowdate.json"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "❌ missing .env"
  exit 1
fi

limit=100
offset=0
total=0
echo "[]" > "$OUTPUT_FILE"

# Step 1: collect all user IDs from users.list
echo "🔍 fetching user list..."
all_ids=()
while :; do
  response=$(curl -sS \
    -H "X-Auth-Token: $RC_TOKEN" \
    -H "X-User-Id: $RC_USER_ID" \
    "$RC_URL/api/v1/users.list?count=$limit&offset=$offset")

  count=$(echo "$response" | jq '.users | length')
  total=$(echo "$response" | jq '.total')
  [[ "$count" -eq 0 ]] && break

  mapfile -t batch_ids < <(echo "$response" | jq -r '.users[]._id')
  all_ids+=("${batch_ids[@]}")

  offset=$((offset + limit))
  printf "\r   %d / %d users collected..." "${#all_ids[@]}" "$total"
  sleep 0.2
done
echo
echo "📋 total users: ${#all_ids[@]}"

# Step 2: call users.info for each user to get bio
processed=0
for userId in "${all_ids[@]}"; do
  response=$(curl -sS \
    -H "X-Auth-Token: $RC_TOKEN" \
    -H "X-User-Id: $RC_USER_ID" \
    "$RC_URL/api/v1/users.info?userId=$userId&fields=%7B%22bio%22%3A1%7D")

  success=$(echo "$response" | jq -r '.success')
  if [[ "$success" != "true" ]]; then
    echo "⚠️  skipping userId=$userId: $(echo "$response" | jq -r '.error // "unknown error"')"
    continue
  fi

  entry=$(echo "$response" | jq '[.user | {
    _id,
    name,
    email: (.emails[0].address // null),
    username,
    bio: (.bio // null)
  }]')

  tmp=$(mktemp)
  jq -s 'add' "$OUTPUT_FILE" <(echo "$entry") > "$tmp"
  mv "$tmp" "$OUTPUT_FILE"

  processed=$((processed + 1))
  printf "\r📦 %d / %d users info fetched..." "$processed" "${#all_ids[@]}"
  sleep 0.1
done

echo
echo "✅ saved to $OUTPUT_FILE"
