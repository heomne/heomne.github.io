---
title: "[Linux] 파일시스템 - 2"
author: heomne
date: 2023-08-30
tags: linux
categories: Linux
pin: false
---
## 파일의 종류

파일시스템은 사용자 데이터를 보관하는 일반 파일과 파일을 보관하는 디렉터리가 있습니다. 리눅스는 이 외에도 디바이스 파일이라는 종류를 갖고 있습니다.

리눅스는 동작하고있는 하드웨어 장치를 거의 모두 파일로 표현합니다. 디바이스 파일에 접근할 수 있는 것은 일반적으로 root만 가능합니다.

디바이스에는 여러 종류가 있지만, 리눅스는 파일로써 접근하는 디바이스를 캐릭터 장치, 블록 장치 두 가지 종류로 구분합니다. 각 디바이스 파일은 `/dev` 아래에 존재하며, 디바이스 파일의 메타데이터에 보관된 정보로 각 장치를 식별합니다. 메타데이터는 캐릭터 장치 혹은 블록 장치, 장치의 Major number, Minor number로 식별이 가능합니다.

일단 `/dev` 내의 파일을 살펴보겠습니다.
``` console
[root@localhost ~]# ls -l /dev/
...
crw-rw-rw-.  1 root tty       5,   0 Jul 18 14:28 tty
...
brw-rw----.  1 root disk      8,   0 Jun 26 15:03 sda
```
+ 첫 번째 필드 맨 앞의 알파벳으로 장치를 식별할 수 있습니다. b는 블록 장치, c는 캐릭터 장치입니다.

+ 다섯 번째 필드가 Major number입니다. tty는 5, sda는 8입니다.

+ 여섯 번째 필드가 Minor number입니다. 둘 다 0으로 표기되어있습니다.


## 캐릭터 장치

캐릭터 장치는 읽기와 쓰기가 가능하지만 탐색이 되지 않는 특성을 가집니다. 대표적인 캐릭터 장치는 터미널, 키보드, 마우스가 있습니다.

실제로 애플리케이션이 터미널의 디바이스 파일을 직접 조작하는 일은 많지 않으나, 리눅스가 제공하는 셸 또는 라이브러리가 직접 디바이스 파일을 다룹니다. 셸이나 라이브러리에서 제공된 더 쉬운 인터페이스를 애플리케이션에서 사용합니다.

흔히 사용하는 bash의 조작이 최종적으로 디바이스 파일의 조작으로 변환됨을 이해한다면 문제 없습니다.

## 블록 장치

블록 장치는 단순히 파일의 읽고 쓰기 이외에 랜덤 접근이 가능합니다. 대표적인 블록 장치로는 HDD와 SDD가 있습니다. 블록 장치에 데이터를 읽고 쓰는 것으로 일반적인 파일처럼 스토리지의 특정 장소에 있는 데이터로 접근할 수 있습니다.

블록 장치는 직접 접근하지않고 파일시스템을 작성하고 마운트함으로써 파일시스템을 경유하여 사용합니다. 블록 장치를 직접 다루는 것은 아래의 경우에만 해당됩니다.

+ `parted`를 사용한 파티션 업데이트
+ `dd` 명령어를 통한 블록 장치 레벨의 데이터 백업, 복구
+ `mkfs` 명령어를 통한 파일시스템 작성
+ `mount`를 통한 파일시스템 마운트
+ `fsck`


## 여러 가지 파일시스템

지금까지는 ext4, XFS, Btrfs라는 파일시스템을 소개했으나 이러한 파일시스템은 저장 장치상에 존재하는 파일시스템입니다. 리눅스는 이 외에도 여러 가지 종류의 파일시스템을 가집니다.

## tmpfs

저장 장치 대신 메모리에 작성하는 파일시스템이 있습니다. 이를 tmpfs라고합니다. 이 파일시스템에 보존된 데이터는 전원을 끄면 사라지지만 저장 장치의 접근이 전혀 발생하지 않기 때문에 고속으로 사용이 가능합니다.

tmpfs는 `/tmp`나 `/var/run` 디렉토리에 사용하는 경우가 많습니다. 재부팅 후 남아있을 필요가 없는 디렉터리에 마운트합니다.

tmpfs는 마운트할 때 작성하는데, `size` 마운트 옵션으로 최대 사이즈를 사용하도록 할 수 있습니다. 그렇다고 최대 용량의 메모리를 확보하는 것은 아니고, 파일시스템 내의 각 영역이 처음 접근할 때, 페이지 단위로 메모리를 확보하는 방식이므로 문제가 없습니다.

`free` 명령어를 입력했을 때 `shared` 필드값이 tmpfs에 의해 실제로 사용된 메모리 양을 표시합니다.


## 가상  파일시스템

### procfs
시스템에 존재하는 프로세스에 대한 정보를 얻기 위해서 'procfs'라는 파일시스템이 존재합니다. procfs는 일반적으로 `/proc` 이하에 마운트됩니다. `/proc/pid/` 이하의 파일에 접근함으로써 각 프로세스의 정보를 얻을 수 있습니다.

보통 설치된 서버의 하드웨어 정보를 조회하기위해 `/proc/cpuinfo`, `/proc/diskstat`, `/proc/meminfo` 등을 조회하는데, 해당 시스템 모두 procfs 파일시스템을 통해 조회가 가능합니다.

`ps` `sar` `top` `free`와 같이 OS가 제공하는 각 정보를 표시하는 명령어또한 모두 procfs로부터 정보를 얻고 있습니다.

### sysfs

리눅스에 procfs가 도입되고 커널의 프로세스 정보 외에 잡다한 정보가 procfs에 모두 들어가게되면서 마구잡이로 사용되는 것을 막기 위해 도입된 파일시스템입니다. sysfs는 보통 `/sys` 이하에 마운트됩니다. sysfs에는 다음과 같은 파일이 있습니다.

+ `/sys/device`이하의 파일 - 시스템에 탑재된 디바이스에 대한 정보
+ `/sys/fs` 이하의 파일 - 시스템에 존재하는 각종 파일시스템에 대한 정보

### cgroupfs

하나의 프로세스, 혹은 여러 개의 프로세스로 만들어진 그룹에 대해 여러 리소스 사용량의 제한을 가하는 cgroup이라는 기능이 있습니다. cgroup은 'cgroupfs'라는 파일시스템을 통해 다루게 됩니다. cgroup을 다룰 수 있는 것은 root만 가능합니다. cgroupfs는 일반적으로 `/sys/fs/cgrup` 이하에 마운트됩니다.

cgroup으로 제한할 수 있는 리소스는 CPU, 메모리를 포함하여 여러가지가 있습니다.

+ CPU: `/sys/fs/cgroup/cpu` 이하의 파일을 읽고 쓰는 것으로 제어가 가능하고, 전체 리소스의 일정 비율 이상을 사용할 수 없도록 설정할 수 있습니다.

+ 메모리: 특정 용량 이상으로 메모리를 사용할 수 없도록 `/sys/fs/cgroup/memory` 이하의 파일을 읽고 쓰는 것으로 제어가 가능합니다.

일반적으로 docker와 같은 컨테이너 프로그램, virt-manager와 같은 가상 시스템 관리 프로그램 등에 각각의 컨테이너나 VM의 리소스를 제한할 때 사용됩니다. 하나의 시스템 상에 여러 개의 컨테이너나 가상 시스템이 공존하는 서버 시스템이 주로 많이 사용됩니다.



