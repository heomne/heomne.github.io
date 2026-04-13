---
title: "(RHEL8~) module 패키지 레포지토리 구성하기"
author: heomne
date: 2026-01-20 +/-TTTT
tags: linux
categories: Linux
pin: false
---

RHEL 8 버전에서는 모듈 패키지라는 기능이 추가되어 특정 패키지가 모듈에 소속되는 경우가 있습니다. 

이 경우 모듈 스트림의 버전 검사 규칙 때문에 모듈에 해당되는 패키지는 개별로 업그레이드할 때 에러가 발생합니다.

```bash
# yum install criu-3.18-4.module+el8.9.0+21243+a586538b.x86_64
Running transaction check
No available modular metadata for modular package 'criu-3.18-4.module+el8.9.0+21243+a586538b.x86_64', it cannot be installed on the system
```

폐쇄망 환경에서 안정화 작업을 위해 패키지를 업그레이드 하려고하면 위와 같은 문제가 발생하는 경우가 많습니다.

해결을 위해 레포지토리를 설정할 때 `module_hotfixes=1` 옵션을 사용하는 경우가 많은데요, 이 경우 대부분의 문제는 해결되지만, 여러 개의 모듈 패키지를 레포지토리에 담아야하거나, 킥스타트를 사용하는 등 해당 옵션을 사용할 수 없는 상황이 되었을 때는 직접 모듈 패키지를 정의하는 `modules.yaml` 파일을 통해 repodata를 생성해야합니다.

후자의 경우 어떤식으로 생성이 되는지를 정리해보고자 합니다.

## 개별패키지가 속해있는 모듈 스트림 확인
위에서 잠깐 언급한 `criu-3.18-4.module+el8.9.0+21243+a586538b.x86_64` 패키지를 예로 들어보겠습니다.  
패키지를 설치하려고할 때 `modular package` 에러가 발생하면서 패키지가 설치되지 못하고 있습니다.

먼저 해당 패키지가 레드햇 레포지토리에서 어떤 모듈에 속해있는지를 확인합니다.  
아래 명령어를 입력하여 확인할 수 있습니다. (RHEL 8 공식 레포지토리가 연결되어있는 상태에서 입력)

`dnf module provides criu-3.18-4.module+el8.9.0+21243+a586538b.x86_64`
```bash
Updating Subscription Management repositories.
Last metadata expiration check: 2:31:54 ago on Wed 21 Jan 2026 07:23:46 AM KST.
criu-3.18-4.module+el8.9.0+21243+a586538b.x86_64
Module   : container-tools:rhel8:8090020240201111839:d7b6f4b7:x86_64
Profiles : common
Repo     : rhel-8-for-x86_64-appstream-rpms
Summary  : Most recent (rolling) versions of podman, buildah, skopeo, runc, conmon, runc, conmon, CRIU, Udica, etc as well as dependencies such as container-selinux built and tested together, and updated as frequently as every 12 weeks.
```

여기서 `Module   : container-tools:rhel8:8090020240201111839:d7b6f4b7:x86_64` 이라고 써져있는 부분이 보입니다.

- module name: `container-tools`
- stream: `rhel8`
- version: `8090020240201111839`
- context: `d7b6f4b7`
- architecture: `x86_64`

패키지는 `container-tools` 라는 모듈에 포함되고있고, 스트림은 `rhel8`, 버전은 `8090020240201111839`, 아키텍처는 `x86_64`에 포함되어있다 정도만 알면됩니다.

## 개별 패키지 다운로드

먼저 패키지를 다운받기 위해 폴더를 생성합니다.   
`mkdir ~/container-tools; cd $_`

업그레이드 하려는 `criu` 패키지가 `container-tools` 모듈에 포함되는 것을 확인했으니, 이제 모듈에 해당되는 개별 패키지들을 다운로드 받아줍니다.
아래 명령어를 입력하면 특정 모듈에 해당되는 모든 패키지를 다운받습니다.

`dnf module install --downloadonly --destdir=. container-tools:rhel8:8090020240201111839:d7b6f4b7:x86_64`

## modules.yaml, repodata 생성
이제 모듈 메타데이터를 생성할 `modules.yaml` 파일을 생성해야하는데, 해당 파일을 생성해주는 `modulemd-tools` 패키지를 설치해주어야합니다. 
`createrepo_c` 패키지도 같이 설치해줍니다.

`dnf install modulemd-tools createrepo_c`

패키지를 설치한 후 `modules.yaml` 파일을 생성하기위해 아래 명령어를 입력합니다.   
`repo2module --module-name=container-tools-custom --module-stream=rhel8 --module-version=8090020240201111839 --module-context=d7b6f4b7 . modules.yaml`

- `--module-name=container-tools-custom`: 모듈이름을 지정합니다. 기존 이름과 다르게 지정하여 conflict를 최대한 피하도록합니다.
- `--module-stream=rhel8`: 모듈의 스트림을 지정합니다. 모듈 이름을 다르게 했기 때문에 기존 스트림과 같게 설정해도 상관없습니다.
- `--module-version=8090020240201111839`: 모듈 버전을 지정합니다. 마찬가지로 기존 스트림과 같게 설정합니다.
- `--module-context=d7b64b7`: 모듈의 컨텍스트를 지정합니다. 기존 컨텍스트와 같게 설정합니다.
- `. modules.yaml`: 현재 위치한 디렉토리에 있는 패키지를 기준으로 모듈 데이터를 생성하며, 파일이름은 `modules.yaml`로 지정합니다.

이후 `modules.yaml` 파일이 생성되었으면 `createrepo_c .` 명령어를 입력하여 repodata를 생성합니다.

## 레포지토리와 통합
생성한 `modules.yaml` 파일과 모듈 패키지가 있는 경우 기존에 사용하던 레포지토리가 있으면 해당 레포지토리 폴더로 패키지와 `modules.yaml` 파일을 옮겨준 다음 `createrepo_c` 명령어로 repodata를 생성하면 문제없이 사용이 가능합니다.