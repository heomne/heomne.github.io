---
title: "Crontab으로 GitHub Commit&Push 자동화, 스케쥴러 구성"
author: heomne
date: 2024-07-14 +/-TTTT
tags: linux blog
categories: Linux
pin: false
---
GitHub Commit과 Push를 자동화할 방법을 찾다가, 리눅스 Crontab에 자동화 스크립트가 실행되도록 하면 어떨까 생각하여 내용을 정리해봤습니다.

준비물은 아래와 같습니다.
- Crontab을 구성할 수 있는 리눅스 서버
  - 어떤 배포판이든 상관없음(Rocky, Ubuntu, RHEL, CentOS ...)
- Commit과 Push를 자동으로 수행할 스크립트

## 자동화 스크립트 작성
먼저 깃헙에 커밋과 푸시를 자동으로 날려주는 스크립트를 작성해봅니다.
```bash
#!/bin/bash

# GitHub Commit & Push Script - heomne.github.io

# repository path
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
```
레포지토리 경로는 `REPO_PATH`, 커밋 메시지는 `$COMMIT_MSG`를 수정하여, 자신이 구성한 서버에 맞게 수정해줍니다.
