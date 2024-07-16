---
title: "Crontab으로 GitHub Commit & Push 자동화, 스케쥴러 구성"
author: heomne
date: 2024-07-14 +/-TTTT
tags: linux blog
categories: Linux
pin: false
---
GitHub Commit과 Push를 자동화할 방법을 찾다가, 리눅스 Crontab에 자동화 스크립트가 실행되도록 하면 어떨까 생각하여 내용을 정리해봤습니다.

준비물은 아래와 같습니다.
- 레포지토리 Commit, Push 권한을 가진 GitHub Token
- Crontab을 구성할 수 있는 리눅스 서버 어떤 배포판이든 상관없음(Rocky, Ubuntu, RHEL, CentOS ...)
- Commit과 Push를 자동으로 수행할 스크립트

## GitHub Token 발급
GitHub Token이 없다면 자동화 스크립트가 시작될 때 매 번 유저 이름과 이메일을 입력해야합니다. 이러면 자동화의 의미가 사라지니 레포지토리에 커밋과 푸시를 할 수 있는 권한을 가진 토큰을 발급하여 바로바로 스크립트가 작동되도록 해줍니다.
GitHub Token은 GitHub 로그인 후 [계정 설정] > [Developer Settings] > [Personal access tokens] 메뉴에서 생성할 수 있습니다. [Generate new token]을 클릭하여 토큰을 생성해줍니다.

![image1](/assets/post_img/github-push-commit-automate/image.png)

저는 Fine-grained tokens로 생성해주었고, 레포지토리는 깃블로그로 사용중인 레포지토리만 지정했습니다.

![image2](/assets/post_img/github-push-commit-automate/image2.png)

권한은 Repository permissions에서 Commit statuses, Contents 만 RW로 설정해주었습니다.

![image3](/assets/post_img/github-push-commit-automate/image3.png)

토큰을 생성하면 토큰값이 나오게 되는데, 토큰값을 복사 후 메모장이나 클립보드에 복사해주세요. 페이지를 벗어나면 다시 토큰값을 볼 수 없습니다.

## 토큰값을 리눅스 서버에 변수로 설정
저는 자동화 스크립트를 레포지토리 안에 넣어놓았기 때문에 토큰값을 자동화 스크립트에 변수로 넣게되면 Public 레포지토리이기 때문에 보안상 매우 위험합니다.
따라서 리눅스 서버에 토큰값을 저장하고 자동화 스크립트에서 토큰값을 불러와서 사용할 수 있도록 구성했습니다.
먼저 `/root` 디렉토리에 `token.sh` 파일을 만들고 아래와 같이 작성합니다.
```bash
GITHUB_TOKEN=<token값>
```
저장 후에는 `chmod +x /root/token.sh` 명령어로 토큰값을 일반 사용자가 실행할 수 있도록 권한을 설정합니다.

## 자동화 스크립트 작성
이제 깃헙에 커밋과 푸시를 자동으로 날려주는 스크립트를 작성합니다.
```bash
#!/bin/bash

# Log file path
LOG_FILE="/home/user/autopush.log"

# import github token from local server
source /root/token.sh

# repository path.
REPO_PATH=/home/user/heomne.github.io/
COMMIT_MSG="Automated commit on $(date)"

# init comment
echo -e "\n" >> "$LOG_FILE"
echo "-----" >> "$LOG_FILE"
echo "$(date) autopush log" >> "$LOG_FILE"
echo "-----" >> "$LOG_FILE"

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
```
- `LOG_FILE`: 스크립트 로그를 저장하는 경로입니다. 정상적으로 스크립트가 작동되었는지를 확인할 수 있습니다.
- `source /root/token.sh`: 토큰값 변수를 불러오도록 명령어를 입력합니다.
- `REPO_PATH`: 클론한 레포지토리의 경로를 입력해줍니다.
- `COMMIT_MSG`: 자동화 스크립트가 실행될 때 커밋 메시지를 어떻게 할지 설정합니다.
- `CHK_UNTRACKED`: `git status` 명령어를 통해 레포지토리 내에 변경사항이 있는지 확인합니다.
- `git push https://heomne:$HEOMNE_TOKEN@github.com/heomne/heomne.github.io.git`
  - 토큰값을 사용하여 변경된 내용을 레포지토리로 Push 합니다.
  - 주소는 `https://<GITHUB_유저명>:<GITHUB_토큰값>@github.com/<GITHUB_유저명>/<REPO_주소>` 형식입니다.

위 내용을 참고하여 스크립트 내용을 변경 후에 저장해줍니다. 저는 레포지토리 내에 있는 `tools` 디렉토리에 저장해줬습니다.
필요에 따라 리눅스 서버 내에 스크립트를 만들어두어도 무방합니다. 

## Crontab으로 스크립트 구동되도록 설정
이제 crontab을 통해 스크립트가 자동으로 실행되도록 설정합니다.
crontab 형식은 아래와 같습니다.
```bash
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed
```

형식을 참고하여 아래와 같이 crontab을 설정해줍니다.
crontab 설정 명령어는 `crontab -e` 입니다. 저는 오후 11시 30분에 실행되도록 구성했습니다.
```bash
30 23 * * * root /home/user/heomne.github.io/tools/autopush.sh
```

정상적으로 스크립트가 실행되었을 경우 `/home/user/autopush.log` 로그에는 아래와 같이 변경사항이 Push된 기록이 있습니다.
```bash
-----
Mon Jul 15 10:43:37 PM KST 2024 autopush log
-----
[master e7b1437] Automated commit on Mon Jul 15 10:43:37 PM KST 2024
 2 files changed, 14 insertions(+)
To https://github.com/heomne/heomne.github.io.git
   7bf4ac3..e7b1437  master -> master
Successfully pushed changes to the repository
```

간단하게 만든 자동화 스크립트이기 때문에 필요한 기능이 있으면 계속해서 수정해 나갈 것 같습니다. 가장 최근버전으로 업데이트된 스크립트는 (여기)[https://github.com/heomne/heomne.github.io/blob/master/tools/autopush.sh]에서 확인할 수 있으니 참고해주세요.