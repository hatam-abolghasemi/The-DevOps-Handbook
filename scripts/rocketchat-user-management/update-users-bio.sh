#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../outputs"
mkdir -p "$OUTPUT_DIR"

RC_FILE=$(find "$SCRIPT_DIR/../outputs" -maxdepth 1 -name 'users-list-*.json' -print 2>/dev/null | tail -n 1 || true)
FUDOS_FILE=$(find "$SCRIPT_DIR/../../fudos-info-fetcher/outputs" -maxdepth 1 -name 'users-*.json' -print 2>/dev/null | tail -n 1 || true)

if [[ -z "$RC_FILE" ]]; then
  echo "No users-list JSON found in ../outputs/"
  exit 1
fi

if [[ -z "$FUDOS_FILE" ]]; then
  echo "No Fudos users JSON found in ../fudos-info-fetcher/outputs/"
  exit 1
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="$OUTPUT_DIR/users-fudos-bio-${TIMESTAMP}.json"

echo "[*] RC users-list : $(basename "$RC_FILE")"
echo "[*] Fudos file    : $(basename "$FUDOS_FILE")"
echo ""

jq -n \
  --slurpfile rc "$RC_FILE" \
  --slurpfile fudos "$FUDOS_FILE" '
  ($fudos[0] | map({
    key: (.id | ascii_downcase),
    value: (
      [
          .job_description,
          .department,
          .employment_type
      ]
      | map(select(. != null and . != ""))
      | join(" | ")
    )
  }) + map({
    key: (.email | ascii_downcase),
    value: (
      [
          .job_description,
          .department,
          .employment_type
      ]
      | map(select(. != null and . != ""))
      | join(" | ")
    )
  }) | unique_by(.key) | from_entries) as $bio_map
  |
  $rc[0]
  | map(
      . as $user |
      ($user.email // "" | ascii_downcase) as $email |
      $user + {
      new_bio: ($bio_map[$email] // "")
      }
  )
  | map(select(.new_bio != ""))
' > "$OUTPUT_FILE"

TOTAL=$(jq 'length' "$OUTPUT_FILE")
MATCHED=$(jq '[.[] | select(.new_bio != "")] | length' "$OUTPUT_FILE")
UNMATCHED=$(jq '[.[] | select(.new_bio == "")] | length' "$OUTPUT_FILE")

echo "[+] Output : $(basename "$OUTPUT_FILE")"
echo ""
echo "  Total users    : $TOTAL"
echo "  Bio matched    : $MATCHED"
echo "  No fudos match : $UNMATCHED"

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
    USERNAME=$(echo "$user" | jq -r '.username')
    NEW_BIO=$(echo "$user" | jq -r '.new_bio')

    echo "[?] Updating bio for '$USERNAME'"
    echo "    -> $NEW_BIO"

    RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
        -H "X-Auth-Token: $RC_TOKEN" \
        -H "X-User-Id: $RC_USER_ID" \
        -H "Content-Type: application/json" \
        -d "{
            \"userId\": \"$USER_ID\",
            \"data\": {
                \"bio\": \"$NEW_BIO\"
            }
        }")

    if echo "$RESPONSE" | jq -e '.success == true' > /dev/null; then
        echo "    ✅ Success"
    else
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // .message // "Unknown error"')
        echo "    ❌ Failed: $ERROR_MSG"
    fi

done < <(jq -c '.[]' "$OUTPUT_FILE")