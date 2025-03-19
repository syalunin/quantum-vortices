#!/bin/bash

echo "*.log" > .gitignore
echo "*.env" >> .gitignore
echo "*.DS_Store" >> .gitignore

git add .
git commit -m "Update repository"
git push origin main