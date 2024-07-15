#!/bin/bash

# Log file path
LOG_FILE="/home/user/autopush.log"

# import github token from local server
source /root/token.sh

# repository path.
REPO_PATH=/home/user/heomne.github.io/
COMMIT_MSG="Automated commit on $(date)"

# move to repository path
cd "$REPO_PATH" >> "$LOG_FILE" 2>&1 || {
  echo "[$(date)] Error: Failed to change directory to $REPO_PATH" >> "$LOG_FILE"
  exit 1
}

# Check untracked files
CHK_UNTRACKED=$(git status --short --untracked)

# Commit & Push
if [ -n "$CHK_UNTRACKED" ]; then
  git add . >> "$LOG_FILE" 2>&1
  git commit -m "$COMMIT_MSG" >> "$LOG_FILE" 2>&1
  git push https://heomne:$HEOMNE_TOKEN@github.com/heomne/heomne.github.io.git >> "$LOG_FILE" 2>&1

  # error message
  if [ $? -ne 0 ]; then
    echo "Error: Failed to push changes to the repository" >> "$LOG_FILE"
    exit 1
  fi
  echo "Successfully pushed changes to the repository" >> "$LOG_FILE"
else
  echo "No changes to commit" >> "$LOG_FILE"
fi