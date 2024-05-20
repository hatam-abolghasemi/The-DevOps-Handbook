#!/bin/bash

# PLACE THIS SCRIPT NEXT TO WHERE THERE ARE A LOT OF GIT PROJECTS.
num_cores=$(nproc)
function checkout_pull() {
  local dir="$1"
  if [[ -d "$dir/.git" ]]; then
    cd "$dir" || return
    tput el
    echo -ne "Updating project:$dir\r"
    git checkout main &> /dev/null
    git pull &> /dev/null
    git checkout master &> /dev/null
    git pull &> /dev/null
    git checkout pre &> /dev/null
    git pull &> /dev/null
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
