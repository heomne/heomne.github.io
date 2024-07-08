---
title: "WSL에 Ruby 3.3.3, NodeJS 설치"
author: heomne
date: 2024-07-08
tags: blog linux
categories: Blog
pin: false
---
WSL 설치 후 Ruby 최신버전을 설치하는 방법이 약간 다릅니다. `sudo apt-get install ruby` 명령어로 ruby를 설치하면 3.0.2 버전으로 설치가 되는데, jekyll chirpy 테마의 경우 3.0.2 버전으로는 정상적으로 빌드가 되지 않기 때문에 3.3.3 버전을 따로 설치해야합니다.

## 설치환경
- Windows 11
- WSL: Ubuntu(22.04.3 LTS (Jammy Jellyfish)
  ```terminal
  PRETTY_NAME="Ubuntu 22.04.3 LTS"
  NAME="Ubuntu"
  VERSION_ID="22.04"
  VERSION="22.04.3 LTS (Jammy Jellyfish)"
  VERSION_CODENAME=jammy
  ID=ubuntu
  ID_LIKE=debian
  HOME_URL="https://www.ubuntu.com/"
  SUPPORT_URL="https://help.ubuntu.com/"
  BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
  PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
  ```
- Ruby 3.3.3 설치
- NodeJS 20.14.0 버전 설치

## Ruby & NodeJS 설치
[GO RAILS](https://gorails.com/setup/ubuntu/22.04) 공식 문서에 설치 가이드가 자세히 작성되어있어 문서를 참고하여 Ruby를 설치합니다.
### Dependency Package 설치
  아래 명령어를 입력하여 패키지 업데이트 & 의존성 패키지를 설치합니다.
  ```terminal
  sudo apt-get update
  sudo apt-get install git-core zlib1g-dev build-essential libssl-dev \
  libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev \
  libcurl4-openssl-dev software-properties-common libffi-dev
  ```
### [ASDF](https://asdf-vm.com/) 버전 매니저 설치
  아래 명령어를 입력하여 ASDF 버전 매니저를 설치합니다.
  ```terminal
  cd
  git clone https://github.com/excid3/asdf.git ~/.asdf
  echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
  echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
  echo 'legacy_version_file = yes' >> ~/.asdfrc
  echo 'export EDITOR="code --wait"' >> ~/.bashrc
  exec $SHELL
  ```
  
  설치 후 ruby, nodejs를 asdf 플러그인에 추가합니다.
  - `asdf plugin add ruby`
  - `asdf plugin add nodejs`

### Ruby 설치
  ASDF를 사용하여 Ruby 3.3.3 버전을 설치합니다.
  - `asdf install ruby 3.3.3`
  ```terminal
  ==> Downloading ruby-3.3.3.tar.gz...
  -> curl -q -fL -o ruby-3.3.3.tar.gz https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.3.tar.gz
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                  Dload  Upload   Total   Spent    Left  Speed
  100 21.0M  100 21.0M    0     0  9738k      0  0:00:02  0:00:02 --:--:-- 9741k
  ==> Installing ruby-3.3.3...
  -> ./configure "--prefix=$HOME/.asdf/installs/ruby/3.3.3" --enable-shared --with-ext=openssl,psych,+
  -> make -j 8
  -> make install
  ==> Installed ruby-3.3.3 to /home/user/.asdf/installs/ruby/3.3.3
  asdf: Warn: You have configured asdf to preserve downloaded files (with always_keep_download=yes or --keep-download). But
  asdf: Warn: the current plugin (ruby) does not support that. Downloaded files will not be preserved.
  ```
  
  설치 후 global 설정을 해줍니다.
  - `asdf global ruby 3.3.3`

> 설치 중 `BUILD FAILED` 문구가 나오면서 설치에 실패하는 경우 메모리가 적어서 생기는 문제입니다.
  - `%userprofile%/.wslconfig`에서 `memory=4GB`로 수정합니다.
  - CMD 실행 후 `wsl --shutdown` 명령어를 입력하여 WSL을 재실행합니다.
  -  `free -h` 명령어를 입력했을 때 `total`이 3.8Gi로 나오는지 확인합니다.
  {: .prompt-tip }

### NodeJS 설치
  ASDF를 사용하여 NodeJS 20.14.0 버전을 설치합니다.
  - `asdf install nodejs 20.14.0`
    ```terminal
    Cloning node-build...
    To follow progress, use 'tail -f /tmp/node-build.20240708135209.16478.log' or pass --verbose
    Downloading node-v20.14.0-linux-x64.tar.gz...
    -> https://nodejs.org/dist/v20.14.0/node-v20.14.0-linux-x64.tar.gz
    Installing node-v20.14.0-linux-x64...
    Installed node-v20.14.0-linux-x64 to /home/user/.asdf/installs/nodejs/20.14.0

    asdf: Warn: You have configured asdf to preserve downloaded files (with always_keep_download=yes or --keep-download). But
    asdf: Warn: the current plugin (nodejs) does not support that. Downloaded files will not be preserved.
    ```

  설치 후 global 설정을 해줍니다.
  - `asdf global nodejs 20.14.0`

설치가 완료되면 WSL에서 ruby와 nodejs를 사용할 수 있기 때문에 Visual Studio Code에서 WSL과 연동하여, 효율적인 빌드 및 배포가 가능해집니다.