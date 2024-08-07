---
title: "Linux BIOS/UEFI 부팅 시퀀스"
author: heomne
date: 2024-07-11 +/-TTTT
tags: linux troubleshooting study
categories: Linux
pin: false
---
## BIOS
### BIOS Firwmare
- BIOS는 부팅 프로세스의 첫 단계를 제어하고 외부 장치에 가장 낮은 레벨의 인터페이스를 제공하는 펌웨어 인터페이스입니다.
- 전원이 들어오면 시스템 검사 및 부팅 프로세스를 시작하기위해 MBR 파티션이 있는 부팅 장치를 탐색합니다.
  - MBR 부트 로더는 리눅스 배포판마다 다르며, RHEL 계열 리눅스는 GRUB2를 MBR 부트 로더로 사용합니다.
- BIOS가 MBR 파티션을 찾게되면 MBR에 저장된 부트 로더를 메모리에 로드한 후 GRUB2 부트 메뉴로 제어권을 전달합니다.

### MBR
- MBR(Master Boot Record)은 파티션 섹터로도 불리며, 스토리지의 첫 번째 섹터를 의미합니다. 
  - 기본적인 크기는 512KB로 되어있으며, 바이오스가 MBR 내에 있는 기계어 명령어를 해석하여 부트 로더를 실행시키는데 주로 사용됩니다.
  - 512KB의 용량 제한을 해결하기위해 MBR 갭이라는 기능을 사용할 수 있는데, MBR 블록과 첫 번째 디스크 파티션 사이의 공간을 활용하여 크기를 늘리는 방법입니다.
  - 안정적인 부트 로더 작동을 위해서는 최소 31KB의 MBR 갭이 있어야하며, RHEL 계열 리눅스의 경우 1MiB의 MBR갭을 생성합니다.

### GRUB2를 통한 BIOS 시스템 부팅
- 부트 로더는 시스템이 시작될 때 가장 먼저 실행되는 프로그램이며, OS를 찾아서 로드하고 제어권을 OS로 넘기는 역할을 수행합니다.
- 부트 로더에 의해 GRUB2가 제어권을 전달받게 되면 GRUB2는 부팅 가능한 운영 체제를 부팅하며, 지원하지 않는 운영 체제의 경우 다른 부트 로더로 제어권을 넘기게 됩니다.
- 서버에 설치된 OS가 없고, OS 설치 DVD가 연결되어 있는 경우에는 부트 로더가 anaconda 설치 관리자로 제어권을 넘기게 됩니다.
- GRUB2에서는 BIOS 부팅 시스템에서 부팅을 위해 아래 경로에 있는 파일을 참고합니다.
  - `/boot` - 커널과 초기 램 디스크가 저장되어있습니다.
  - `/boot/grub2` - 부팅을 위한 config 파일과 확장 모듈이 저장되어있습니다.
  - `/boot/grub2/grub.cfg` - 부팅 config 파일로, `/etc/grub2.cfg`에 대한 심볼릭 링크가 지정되어있습니다.
  - `/boot/grub.d` - `/boot/grub2/grub.cfg` 파일을 생성하는 구성 헬퍼 스크립트가 포함되어있습니다.
  - `/etc/default/grub` - 구성 헬퍼 스크립트에서 사용하는 변수가 포함되어있어, grub2 파일 생성시 해당 파일을 참조하게됩니다.

## UEFI
2005년 도입된 UEFI Firmware는 BIOS 부팅방식을 대체하기위해 등장한 부팅 방식입니다. 

### UEFI Feature
UEFI 부팅 방식은 BIOS 부팅 방식과 비교하여 아래의 장점을 가집니다.
- 1MiB밖에 지정하지 못했던 부팅 파티션 한계를 극복할 수 있습니다.
- GPT 파티션 테이블 형식을 지원하여 기존에 파티션 크기를 최대 2TB까지밖에 생성하지 못했던 문제를 해결했습니다.
- UEFI 펌웨어에 부팅 가능한 운영 체제를 처음부터 등록하여 부팅하는 방식을 사용합니다. (BIOS는 부팅가능한 장치를 탐색하는 것과 다릅니다.) 이는 보안 부팅기능을 지원하도록 할 수 있다는 장점을 가집니다.

### GRUB2 - UEFI
RHEL계열 리눅스의 경우 UEFI 부팅에서도 똑같이 GRUB2를 부트 로더로 사용하며, 부팅을 위해서는 아래의 요구사항을 충족해야합니다.
- OS가 설치된 디스크에 EFI 시스템 파티션(ESP - EFI System Partition)이 있어야합니다.
- GPT 파티션을 사용하는게 장점이 더 많지만, 일단 MBR 파티션도 지원합니다.
- ESP 파티션은 FAT 파일시스템에서만 지원하며, 부트 로더 및 모든 부팅 가능한 커널을 저장할 수 있을 정도의 저장공간을 가져야합니다.
  - 권장 크기는 512MiB이며, 최소로 할당해야하는 공간은 200MiB입니다.
  - 기본 경로는 `/boot/efi`이며, UEFI로 설치된 OS 경우에는 필수로 필요한 파티션입니다.

### UEFI Booting Chain
- UEFI 부팅의 가장 큰 특징이라고 볼 수 있는 보안 부팅 기능입니다.
- 부트 로더, 커널 및 부트 객체에 서명을 사용하여 검증된 부트 로더만 부팅이 가능하도록 합니다.
- 부팅 시 신뢰할 수 있는 서명된 키라고 볼 수 있는 `shim.efi` 어플리케이션이 `grubx64.efi`라는 UEFI 펌웨어 로드를 시도하여 검증이 이루어집니다.
  - 검증되지않은 서명으로 인하여 UEFI 펌웨어가 로드되지 않을 경우에 shim은 검증되는 다른 키를 찾으려 시도합니다.
  - `emibootmgr` 명령어를 사용하면 UEFI의 부팅 순서를 확인할 수 있습니다.
