#!/bin/bash

# This script extracts URLs from every projects it finds in vault and saves them in 'vault-url.log'.
# PLACE THIS SCRIPT NEXT TO WHERE THERE ARE A LOT OF GIT PROJECTS.
export VAULT_ADDR="<vault-address>"
export VAULT_TOKEN="<vault-token>"
results=""
> vault-url.log
num_cores=$(nproc)
function vault_kv() {
  local dir="$1"
  dir_name="${dir##*/}"
  data=$(vault kv get -format=json <vault-slug>/${dir_name}/appConfig 2>/dev/null | jq '.data.data' | grep http)
  if [[ ! -z "$data" ]]; then
    results="${results:+,}$data"
    tput el
    echo -ne "Fetching $dir_name vault data\r"
  fi    
  echo "[$results]" >> vault-http.json
}
for dir in $(find . -mindepth 1 -maxdepth 1 -type d); do
  vault_kv "$dir" &
  while [[ $(jobs -r | wc -l) -ge $num_cores ]]; do
    sleep 1
  done
done
wait
tput el
echo "Finished fetching all projects vault data!"

echo -ne "Looking for URLs\r"
file="vault-http.json"
urls=$(grep -P "http[s]://([^>]+)" "$file" 2>&1)
if [[ ! -z "$urls" ]]; then
  echo "$urls" > extractor.log
fi
grep -E 'http://|https://' extractor.log | while read -r line; do
    extracted_line=$(echo "$line" | sed -n 's/.*\(http[s]*:\/\/[^'\'']*\).*/\1/p')
    if [[ ! $extracted_line =~ apache.org ]] &&
		[[ ! $extracted_line =~ amazonaws.com ]] &&
		[[ ! $extracted_line =~ bit.ly ]] &&
# more  [[ ! $extracted_line =~ whatever.com ]] &&
		[[ ! $extracted_line =~ bitnami.com ]] then
        echo "$extracted_line" >> cleaner.json
    fi
done
echo "Finished looking for URLs"
sed -i 's/[ "]//g; s/[)]//g; s/]//g; s/[,]//g; s/[""]//g' cleaner.json
sed -i 's/\/$//' "cleaner.json"
sort cleaner.json | uniq > vault-url.log
rm vault-http.json extractor.log cleaner.json
set VAULT_ADDR=
set VAULT_TOKEN=
echo "Cleanup finished! check vault-url.log"
