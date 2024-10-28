---
title: "[RHEL] Kickstart USB 부팅 디스크 사용시 유의사항"
author: heomne
tags:
  - linux
  - RHEL
  - troubleshooting
categories: Linux
---
이번에 RHEL 킥스타트를 만들게되면서 생긴 이슈를 정리한 글입니다. 킥스타트 제작방법까지 적기에는 글 내용이 너무 길어 패스합니다.

[레드햇 솔루션](https://access.redhat.com/solutions/60959)을 참고한 킥스타트 제작과정을 간단하게 정리하면,

* RHEL DVD ISO 파일을 다운로드 받습니다. (8.4버전을 사용했습니다.)
* ISO 파일을 마운트 후, 파일 전체를 로컬 디렉토리에 복사합니다.
* 작성한 킥스타트파일을 복사한 디렉토리 내에 넣어줍니다.
* UEFI 부팅 기준으로 `EFI/BOOT/grub.cfg` 파일을 수정하여 부팅 시 킥스타트파일을 참조하도록 설정합니다.
* `genisoimage` 패키지를 다운로드 후, `mkisofs` 명령어를 사용하여 iso파일을 생성합니다.

위 가이드를 통해 ISO 파일을 생성한 후 VM에 설치해보니 문제없이 킥스타트의 내용이 잘 반영되어 설치되었습니다.

하지만 베어메탈에 리눅스를 설치하는 환경이기 때문에 ISO 파일을 USB 부팅디스크로 만들어야하는 요구사항이 있었습니다. rufus 프로그램으로 USB 부팅디스크를 만들어 설치해보니 킥스타트 내용이 반영되지가 않더군요... 살펴보니 킥스타트 파일 내용에 문제가 있었습니다.

## 변경해야할 내용

킥스타트로 RHEL을 설치할 때는 iso 파일을 사용하는지(VM환경), USB stick을 사용하는지(베어메탈)따라 설정해주어야하는 내용에 차이가 있습니다.

### 1. cdrom vs harddrive

redhat에서 다운로드 받은 RHEL 설치 후 `/root`경로를 가면 `anaconda-ks.cfg` 파일이 존재합니다. RHEL 설치에 사용된 킥스타트 파일인데요, 파일 내용을 살펴보면 아래의 내용이 있습니다.

```shell
...
# Use CDROM installation media
cdrom
```

ISO 파일로 설치되기때문에 cdrom이라고 적혀있습니다. USB stick으로 만들어 설치할 때는 아래와 같이 작성해주어야합니다.

```shell
...
# Use CDROM installation media
# cdrom
harddrive --partition=LABEL=RHEL-8-4-0- --dir=/
```

`harddrive`를 통해 설치하게되며, 설치디스크는 디스크 라벨이 `RHEL-8-4-0-`으로 되어있는 디스크를 사용하라고 작성하였습니다.
디스크 라벨을 사용하는 이유는 RHEL을 설치하게될 서버장비에 스토리지가 여러 개 붙어있을지 모르니, `/dev/sd*`를 직접적으로 명시하면 문제가 발생하게될 수 있습니다.

### 2. 레포지토리 설정

cdrom으로 설치하는 킥스타트 파일에는 `%post`스크립트에 부팅디스크를 마운트하고(`/dev/sr0`), 필요한 패키지를 설치하도록 작성했는데, 이게 USB 설치에서는 적용되지가 않았습니다. 로그를 살펴보니 USB에서는 부팅디스크가 마운트 되지 않더군요.

따라서 `repo`구문을 사용하여 설치단계에서 레포지토리를 잡도록 설정해주어야했습니다. `repo`구문을 사용하여 필요한 레포지토리의 파일 경로를 잡아주었습니다.

```shell
...
# enable repository
url --url file:///mnt/install/repo/BaseOS
repo --name="Appstream" --baseurl=file:///mnt/install/repo/Appstream
```

USB stick으로 RHEL을 설치하는 경우, 부팅디스크는 `/mnt/install/repo`경로에 마운트됩니다. 따라서 repo 경로를 위와같이 설정해주면 자동적으로 설치단계에서 레포지토리를 인식하게됩니다.
갑자기 `url`이 어디서 나온건지 궁금해하실 수 있는데, BaseOS는 RHEL 설치에 핵심이 되는 레포지토리이기 때문에 `repo`가 아닌 `url`을 사용해야한다고합니다.

`%Package`섹션에서 설치할 패키지들을 입력하여 설치할 수 있도록해줍니다.

```shell
...
%packages
@^graphical-server-environment
kexec-tools
httpd
yum-utils
createrepo_c
%end
```

이러면 설치단계에서 `httpd` `yum-utils` `createrepo_c` 패키지가 설치됩니다. `%post`스크립트에서 마운트-레포파일작성- install 과정보다 효율적으로 보이네요.

### 3. 특정 파일을 복붙해야할 때

아마 가장 중요한 항목이 아닐까 싶습니다. cdrom으로 Kickstart를 설치할 때, 부팅디스크 내에 존재하는 파일을 사용하기위해선 단순히 마운트 시킨다음 사용하면 간단하게 사용이 가능했습니다.
하지만 USB에서는 마운트가 되지 않기때문에 부팅디스크에 있는 파일을 옮기는 방법이 상대적으로 복잡합니다. `%post`스크립트를 사용하여 파일을 옮길 수 있습니다. 일단 아래 예시구문을 봅시다.

```shell
## 부팅 디스크에 있는 쉘 파일을 설치될 OS의 /tmp 디렉토리로 복사
%post --nochroot
cp -r /mnt/install/repo/hello.sh /mnt/sysroot/tmp
%end

## 파일 실행
%post
bash /tmp/hello.sh
%end
```

RHEL이 설치될 때 설치되는 파일들은 `/mnt/sysroot`경로에 저장됩니다. `/`는 아나콘다 콘솔을 통해 접근이 가능하고, 설치가 모두 끝난 뒤에는 `/mnt/sysroot`경로에 있는 내용이 모두 `/`로 이동하게됩니다.
`%post`스크립트는 기본적으로 `/mnt/sysroot/` 내에서 실행되기 때문에 외부에서 마운트된 항목에 접근할 수 없습니다. `--nochroot` 옵션을 사용하여 외부에있는 파일시스템에 접근하도록할 수 있습니다.

위 구문을 보시면 `%post`스크립트가 2개 작성되어있는데, 전자는 `--nochroot`옵션을 사용 후 외부에서 USB 마운트 경로에 접근하여 특정 파일을 `/mnt/sysroot/tmp` 경로로 복사하고있고, 후자는 옵션없이 복사된 쉘 스크립트 파일을 실행하고있습니다.

cdrom이었다면 단순히 `/dev/sr0`에서 마운트한 다음 파일을 실행하면 됐겠지만, USB stick이기 때문에 마운트가 될 수 없고 파일을 복사하여 사용해야한다는 점이 다소 복잡해보이지만, 열심히 삽질해본 결과 위 방법이 그나마 편한수단이었습니다.


위의 세가지 사항을 유의하면 USB stick에서 kickstart 방식으로 RHEL을 설치할 때 발생하는 문제의 대부분을 해결할 수 있을 것으로 보입니다. 확실히 요즘은 클라우드환경에서 RHEL을 설치하다보니 Kickstart를 사용할 일이 별로 없을 것 같긴하지만 알아두면 나쁠건 없을 것 같네요.