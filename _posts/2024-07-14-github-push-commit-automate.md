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
스크립트를 실행해보면 아래와 같은 결과가 나오면서 정상적으로 GitHub에 커밋 & 푸시가 진행된 것을 볼 수 있습니다.
```terminal
h_min@HEO24:~/heomne.github.io/tools$ ./autopush.sh 
[master eb460f0] Automated commit on Sun Jul 14 22:45:07 KST 2024
 1 file changed, 49 insertions(+)
 create mode 100644 _posts/github-push-commit-automate.md
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
Delta compression using up to 12 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 1.25 KiB | 1.25 MiB/s, done.
Total 4 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To https://github.com/heomne/heomne.github.io.git
   8fc93eb..eb460f0  master -> master
Successfully pushed changes to the repository
```
