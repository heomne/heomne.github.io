#!/bin/bash

# heomne.github.io repository path
REPO_PATH=/home/h_min/heomne.github.io/
COMMIT_MSG="Automated commit on $(date)"

# move to repository path
cd "$REPO_PATH" || exit

# Check untracked files
CHK_UNTRACKED=$(git status --short --untracked)

# Commit & Push
if [ -n "$CHK_UNTRACKED" ]; then
  git add .
  git commit -m "$COMMIT_MSG"
  git push origin master

  # error
  if [ $? -ne 0 ]; then
    echo "Error: Failed to push changes to the repository"
    exit 1
  fi
  echo "Successfully pushed changes to the repository"
else
  echo "No changes to commit"
fi