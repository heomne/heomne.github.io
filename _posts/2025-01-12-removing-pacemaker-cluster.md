---
title: "RHEL 7 버전 python3.8 패키지 설치"
author: heomne
date: 2025-02-27 +/-TTTT
tags: linux
categories: Linux
pin: false
---

RHEL 7 버전에서 기본적으로 제공하는 Python 버전은 3.6.8 버전까지로 알려져 있습니다. 상위 버전을 설치하기위해서는 기본 레포지토리가 아닌 레드햇에서 추가로 제공하는 RHSCL 레포지토리를 통해 Python3.8 버전을 설치할 수 있습니다.

여기에서 RHSCL은 RedHat Software Collections로, RHEL6, 7 버전을 구독하고있다면 같이 활성화되는 레포지토리라고 보면됩니다. RHEL 8 버전부터는 기본적으로 제공되는 패키지 레포지토리가 BaseOS, AppStream으로 나누어지게 되었고, AppStream이 RHSCL의 역할을 하고 있습니다.
RHCSL을 통해 사용하는 패키지의 경우 기술지원 및 보안 취약점 패치가 적용됩니다.

다만 RHEL 7 버전에서 Python은 3.8.X버전까지가 레드햇에서 최대로 제공하는 버전이며, 여기에서 상위버전의 Python을 설치하려면 RHEL 8 버전을 사용해야합니다.

## 설치 방법

1. RHCSL Repository를 활성화합니다.
```bash
subscription-manager repos --enable rhel-server-rhscl-7-rpms
yum clean all; yum repolist
```

2. python 3.8 패키지를 설치합니다. 패키지 이름은 `rh-python38`입니다.
```bash
yum install -y rh-python38
```

3. RHCSL에서 설치한 패키지는 기본적으로 활성화되지 않은 상태로 설치됩니다. 패키지를 활성화하기위해 다음 명령어를 입력합니다.
```bash
scl enable rh-python38 bash
```

4. 정상적으로 실행되는지 확인합니다.
```bash
python3.8 --version
Python 3.8.18
```

참고로 RHEL 7 버전의 경우 Python 2.X 버전에 의존하는 패키지들이 있기 때문에 기본 설치된 Python은 삭제하지않고 상위버전을 설치하도록 권장됩니다.