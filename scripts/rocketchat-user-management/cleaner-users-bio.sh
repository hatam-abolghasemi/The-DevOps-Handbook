#!/usr/bin/env bash

set -euo pipefail

INPUT_FILE="${1:-users.json}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "❌ missing .env"
  exit 1
fi
API_ENDPOINT="$RC_URL/api/v1/users.update"

while read -r user; do
    USER_ID=$(echo "$user" | jq -r '._id')
    USERNAME=$(echo "$user" | jq -r '.username // "unknown"')

    echo "[?] Clearing bio for '$USERNAME' ($USER_ID)"

    RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
        -H "X-Auth-Token: $RC_TOKEN" \
        -H "X-User-Id: $RC_USER_ID" \
        -H "Content-Type: application/json" \
        -d "{
            \"userId\": \"$USER_ID\",
            \"data\": {
                \"bio\": null
            }
        }")

    if echo "$RESPONSE" | jq -e '.success == true' > /dev/null; then
        echo "    ✅ Success"
    else
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // .message // "Unknown error"')
        echo "    ❌ Failed: $ERROR_MSG"
    fi

done < <(jq -c '.[]' "$INPUT_FILE")