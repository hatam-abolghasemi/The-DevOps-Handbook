#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
nowdate="$(date +%Y-%m-%d_%H-%M-%S)"
OUTPUT_DIR="$SCRIPT_DIR/../outputs"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/users-list-$nowdate.json"

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
while :; do
  response=$(curl -sS \
    -H "X-Auth-Token: $RC_TOKEN" \
    -H "X-User-Id: $RC_USER_ID" \
    "$RC_URL/api/v1/users.list?count=$limit&offset=$offset")
  count=$(echo "$response" | jq '.users | length')
  total=$(echo "$response" | jq '.total')
  [[ "$count" -eq 0 ]] && break
  batch=$(echo "$response" | jq '[
    .users[] | {
      _id,
      type,
      name,
      email: (.emails[0].address // null),
      username,
      nameInsensitive
    }
  ]')
  tmp=$(mktemp)
  jq -s 'add' "$OUTPUT_FILE" <(echo "$batch") > "$tmp"
  mv "$tmp" "$OUTPUT_FILE"
  offset=$((offset + limit))
  printf "\r📦 %d / %d users processed..." "$offset" "$total"
  sleep 0.2
done
echo
echo "✅ saved to $OUTPUT_FILE"