---
title: "[Linux] NTFS/exfat 파일시스템 사용하기"
author: heomne
date: 2024-08-08 +/-TTTT
tags: linux
categories: Linux
pin: false
---

RHEL 계열 리눅스는 기본적으로 NTFS, exfat 파일시스템을 지원하지 않습니다. USB가 둘 중 하나의 파일시스템으로 되어있을 경우 아래와 같이 메시지가 출력되며 파일시스템이 마운트되지 않습니다.

```terminal
[root@heomne ~]# mount /dev/sdb1 /mnt/usb
mount: /mnt/usb: unknown filesystem type 'exfat'.
```

이 경우 FAT32 파일시스템을 사용하여 마운트를 해야하는데, 단일파일이 4GB이상일 경우 FAT32 파일시스템에 저장이 불가능한 치명적인 단점이 있습니다.

다행히 NTFS, exfat을 마운트 할 수 있는 패키지를 설치하면 리눅스에도 마운트하여 파일을 사용할 수 있습니다.

## exfat 파일시스템 마운트 방법
테스트는 RHEL 8 버전 기준으로 테스트를 진행하였습니다. 

exfat 파일시스템을 마운트하기위해 필요한 패키지는 `exfatprogs` `fuse-exfat`입니다. RHEL 버전에 따라 필요한 패키지가 다를 수 있으니 이 경우 다른 글을 참조해야합니다.

`exfatprogs` 패키지는 `epel-release`라는 레포지토리를 통해서 받을 수 있고, `fuse-exfat` 패키지는 `rpmfusion-free-release` 레포지토리를 통해 설치할 수 있습니다. 
아래 명령어를 입력하여 두 레포지토리를 추가해줍니다.

```terminal
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
```

> 레포지토리 추가를 위해서는 public 환경에서 진행되어야하며, disconnected 환경에서는 레포지토리 주소로 직접 접근하여 패키지를 다운로드 받은 후 직접 설치를 진행해야합니다.

레포지토리 등록 후 패키지를 설치합니다.

- `yum -y install exfatprogs fuse-exfat`

연결된 USB를 다시 마운트해봅니다.

```terminal
mount /dev/sdb1 /mnt/usb
FUSE exfat 1.3.0
```
```terminal
root@localhost.localdomain /root # lsblk
NAME   MAJ:MIN RM    SIZE RO TYPE MOUNTPOINT
sda      8:0    0     80G  0 disk
├─sda1   8:1    0      1G  0 part /boot
├─sda2   8:2    0     30G  0 part /
├─sda3   8:3    0     20G  0 part /var
├─sda4   8:4    0      1K  0 part
├─sda5   8:5    0     10G  0 part /home
└─sda6   8:6    0     16G  0 part [SWAP]
sdb     8:16    1   29.3G  0 disk
└─sdb1  8:17    1   29.3G  0 part /mnt/usb
```

정상적으로 마운트 된 것을 확인할 수 있습니다.

## NTFS 파일시스템 마운트 방법
NTFS 파일시스템의 경우 `ntfs-3g` 패키지가 필요합니다. `epel-repository`에서 다운로드 받을 수 있습니다.

마찬가지로 아래 명령어를 입력하여 `epel-repository` 활성화 후, `ntfs-3g` 패키지를 설치합니다.

```terminal
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install ntfs-3g
```

> disconnected에서 설치할 경우 `ntfs-3g` `ntfs-3g-libs` 패키지 2개가 필요합니다.

이후 NTFS 파일시스템을 사용하는 USB연결 후 정상적으로 마운트되는지 확인합니다.