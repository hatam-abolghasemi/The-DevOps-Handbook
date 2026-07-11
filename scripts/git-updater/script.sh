#!/bin/bash

# PLACE THIS SCRIPT AT THE ROOT OF A DIRECTORY TREE CONTAINING GIT PROJECTS.
# It recursively finds every git repo underneath the current directory.
set -uo pipefail

num_cores=$(nproc)
tmp_report_dir=$(mktemp -d)
trap 'rm -rf "$tmp_report_dir"' EXIT

# Run a git command silently; only if it fails, log a labeled block
# containing its combined output to the report file.
run_logged() {
  local report_file="$1"; shift
  local label="$1"; shift
  local output
  if ! output=$("$@" 2>&1); then
    {
      echo "ERROR: $label"
      [[ -n "$output" ]] && echo "$output"
    } >> "$report_file"
    return 1
  fi
  return 0
}

sync_repo() {
  local dir="$1"   # absolute path to the repo (parent of .git)
  local name="${dir#$PWD/}"
  [[ "$name" == "$dir" ]] && name=$(basename "$dir")
  local report_file="$tmp_report_dir/$(echo "$name" | tr '/' '_').log"

  (
    cd "$dir" || { echo "ERROR: could not cd into directory" >> "$report_file"; exit 1; }

    tput el 2>/dev/null
    echo -ne "Updating: $name\r"

    local dirty
    dirty=$(git status --porcelain 2>/dev/null)
    if [[ -n "$dirty" ]]; then
      echo "SKIPPED: uncommitted local changes present" >> "$report_file"
      exit 1
    fi

    if ! run_logged "$report_file" "git fetch origin failed" \
         git fetch origin --prune --tags --quiet; then
      exit 1
    fi

    local current_branch
    current_branch=$(git symbolic-ref --short -q HEAD || true)
    local had_error=0

    local remote_branches
    remote_branches=$(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v '^origin/HEAD$')

    if [[ -z "$remote_branches" ]]; then
      echo "ERROR: no remote branches found on origin" >> "$report_file"
      exit 1
    fi

    while IFS= read -r rb; do
      [[ -z "$rb" ]] && continue
      local branch_name="${rb#origin/}"
      if [[ "$branch_name" == "$current_branch" ]]; then
        if ! run_logged "$report_file" "failed to reset current branch '$branch_name' to $rb" \
             git reset --hard "$rb"; then
          had_error=1
        fi
      else
        if ! run_logged "$report_file" "failed to update branch '$branch_name' from $rb" \
             git branch -f "$branch_name" "$rb"; then
          had_error=1
        fi
      fi
    done <<< "$remote_branches"

    local gone_branches
    gone_branches=$(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '$0 ~ /\[gone\]/ {print $1}')

    if [[ -n "$gone_branches" ]]; then
      while IFS= read -r gb; do
        [[ -z "$gb" ]] && continue
        if [[ "$gb" == "$current_branch" ]]; then
          local default_branch
          default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
          if [[ -n "$default_branch" ]]; then
            run_logged "$report_file" "failed to checkout default branch '$default_branch'" \
              git checkout "$default_branch"
            current_branch="$default_branch"
          else
            echo "WARNING: could not determine default branch, leaving stale branch '$gb' in place" >> "$report_file"
            continue
          fi
        fi
        if ! run_logged "$report_file" "failed to delete stale local branch '$gb'" \
             git branch -D "$gb"; then
          : # already logged by run_logged
        fi
      done <<< "$gone_branches"
    fi

    exit $had_error
  )
}

mapfile -t repos < <(find "$PWD" -type d -name ".git" -prune -print0 | xargs -0 -n1 dirname 2>/dev/null)

if [[ ${#repos[@]} -eq 0 ]]; then
  echo "No git repositories found under $PWD."
  exit 0
fi

for dir in "${repos[@]}"; do
  sync_repo "$dir" &
  while [[ $(jobs -r | wc -l) -ge $num_cores ]]; do
    wait -n
  done
done
wait

tput el 2>/dev/null
echo "Finished updating all projects (${#repos[@]} repos found)."
echo

had_any_issue=0
for f in "$tmp_report_dir"/*.log; do
  [[ -s "$f" ]] || continue
  had_any_issue=1
  repo_name=$(basename "$f" .log | tr '_' '/')
  echo "----- $repo_name -----"
  cat "$f"
  echo
done

if [[ $had_any_issue -eq 0 ]]; then
  echo "All repositories updated successfully with no issues."
else
  echo "Some repositories had issues — see above."
fi