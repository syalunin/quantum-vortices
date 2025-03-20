#!/bin/bash

if [ -z "$1" ]; then
  echo "Error: No commit message provided!"
  exit 1
fi

gitignore_add_pattern() {
  local pattern="$1"
  local file=".gitignore"
  grep -qxF "$pattern" "$file" || echo "$pattern" >> "$file"
}

gitignore_add_pattern "*.x"
gitignore_add_pattern "*.DS_Store"
gitignore_add_pattern "repo_update.sh"

git add -A
git commit -m "$1"
git push origin main