#!/bin/bash

# This script extracts hard-coded URLs from every git projects it finds and saves them in 'url.log'.
# PLACE THIS SCRIPT NEXT TO WHERE THERE ARE A LOT OF GIT PROJECTS.
num_cores=$(nproc)
function checkout_pull() {
  local dir="$1"
  if [[ -d "$dir/.git" ]]; then
    cd "$dir" || return
    tput el
    echo -ne "Updating project:$dir\r"
    git checkout develop &> /dev/null
    git pull &> /dev/null
    cd - &> /dev/null
  fi
}
for dir in */; do
  checkout_pull "$dir" &
  while [[ $(jobs -r | wc -l) -ge $num_cores ]]; do
    sleep 1
  done
done
wait
tput el
echo "Finished updating all projects!"

> extractor.log
> cleaner.log
> git-url.log
echo -ne "Looking for URLs\r"
find . -type f -exec grep -P "http[s]://([^>]+)" {} \; >> extractor.log 2>&1
grep -E 'http://|https://' extractor.log | while read -r line; do
    extracted_line=$(echo "$line" | sed -n 's/.*\(http[s]*:\/\/[^'\'']*\).*/\1/p')
    if [[ ! $extracted_line =~ apache.org ]] &&
		[[ ! $extracted_line =~ amazonaws.com ]] &&
		[[ ! $extracted_line =~ bit.ly ]] &&
# more  [[ ! $extracted_line =~ whatever.com ]] &&
		[[ ! $extracted_line =~ bitnami.com ]] then
        echo "$extracted_line" >> cleaner.log
    fi
done
echo "Finished looking for URLs"
sed -i 's/[ "]//g; s/[)]//g; s/[,]//g; s/[""]//g' cleaner.log
sed -i 's/\/$//' "cleaner.log"
sort cleaner.log | uniq > git-url.log
rm extractor.log cleaner.log 
echo "Cleanup finished! check git-url.log"
