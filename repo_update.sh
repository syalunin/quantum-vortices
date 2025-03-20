#!/bin/bash

if [ -z "$1" ]; then
  echo "Error: No commit message provided!"
  exit 1
fi

echo "*.x" >> .gitignore
echo "*.log" >> .gitignore
echo "*.env" >> .gitignore
echo "*.DS_Store" >> .gitignore
echo "repo_update.sh" >> .gitignore

git add .
git commit -m "$1"
git push origin main