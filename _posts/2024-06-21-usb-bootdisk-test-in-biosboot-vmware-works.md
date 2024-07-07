---
title: Bios 부팅 환경에서 USB 부팅디스크 테스트 (VMWare Workstation)
author: heomne
tags:
  - troubleshoot
  - linux
categories: Etc
---
이전에 [VirtualBox에서 USB 부팅 디스크 테스트 방법](https://heomne.github.io/posts/bootdisk-test-with-virtualbox/)에 대한 글을 작성한 적이 있습니다. 유용하게 사용하고 있었는데,, 다른 고객사에서 BIOS(Legacy) 부팅 환경에서 킥스타트 USB 부팅 디스크를 요청하게되어 새로운 글을 작성하게 되었습니다.

# VirtualBox 쓰다 VMWare를 굳이 사용한 이유

VirtualBox에서는 UEFI 환경에서만 USB 부팅 디스크를 지원하는 듯 합니다. Legacy 환경으로도 부팅할 수 있는 방법이 있긴 하지만 너무 복잡하고 비효율적이어서 VMware Workstation으로 해봤는데, 기본 부팅 방식이 BIOS 부팅으로되어있어 고객사에서 요청한 환경과 동일한 점, USB 부팅을 간단하게 사용하여 테스트 해볼 수 있다는 점이 장점이었는데요.

다만 처음 사용하는 경우에는 어느정도 진입장벽이 존재하여 여러 번 삽질한 끝에 성공했습니다. **VMWare Workstation 17** 버전에서 테스트했으며, 최신버전이다 보니 최신 하드웨어가 기본으로 설정되어있어 변경해야할 부분이 많았습니다.

# VMWare Workstation VM 구성방법

일단 이 글에서는 USB 부팅 디스크가 정상적으로 되는지를 중점적으로 다루기 때문에 네트워크 구성은 하지 않습니다. OS를 설치할 Local 볼륨, 그리고 컴퓨터에 연결된 USB를 VM과 연동하고, 최소한의 CPU와 메모리만을 구성한 VM을 생성합니다.

## VM 생성

1. **VMWare Workstation Pro 17을 관리자 권한으로 실행 후** VM을 생성합니다.\
   생성한 다음에 세팅에서 구성을 변경하기 때문에 껍데기 대충 만들어줍니다.
2. 생성 후에는 VM 우클릭 후 Setting으로 들어간 후, 기본적으로 생성된 Hard Disk를 삭제합니다.
3. 새로운 Hard Disk를 생성합니다. 타입은 SCSI로 설정하고, Create a new virtual disk를 클릭하여 새로운 가상디스크를 생성합니다. Allocate all disk space now 체크, Store virtual disk as a single file을 선택해줍니다. 

   ![](/assets/post_img/usb-bootdisk-test-in-biosboot-vmware-works/341646299-d26428ff-c12f-44a2-9b4e-1ff91bdd6dc1.png)
4. Hard Disk를 하나 더 생성합니다. 두 번째 하드 디스크는 USB와 연동되는 하드디스크입니다. 타입은 똑같이 SCSI를 선택한 후 Use physical disk를 선택한 후 Next로 넘어갑니다.

   ![](/assets/post_img/usb-bootdisk-test-in-biosboot-vmware-works/341647359-f397f505-d2ff-42d3-894a-83f8f16217f7.png)
5. Device를 선택해줍니다. USB가 꽂혀있는 PhysicalDrive를 선택해야되는데, 윈도우의 Diskpart로 어떤 스토리지가 연결되어있는지 확인이 가능합니다. cmd 터미널에서 `diskpart`를 입력한 후 `list disk`를 입력하면 현재 윈도우에 연결된 스토리지 리스트를 확인할 수 있습니다. 여기서 USB 용량이 출력되는 디스크를 확인후, VMWare에서 해당 디스크를 선택해줍니다.

   ![](/assets/post_img/usb-bootdisk-test-in-biosboot-vmware-works/341647972-97a65753-a026-4e24-a8e7-54f95a777198.png)

## BIOS 부팅순서 설정

설정이 완료되면 VM을 시작해줍니다. VM이 시작될 때 F2를 연타하여 BIOS로 진입해야합니다. 넘어가는 속도가 빠르니 빠르게 연타해줍니다. BIOS로 넘어가지 못한경우 VM을 재시작하여 반복합니다.

BIOS로 진입한 다음 BOOT 탭으로 이동하여 부팅 순서를 변경해야합니다. 먼저 +Hard Drive를 제일 위로 올려준 다음, +Hard Drive를 선택 후 엔터를 누르면 여러 Hard Drive 중에서도 부팅 순서를 정할 수 있습니다. USB 부팅 디스크의 경우 (0:1)로 되어있으므로 해당 디스크를 제일 먼저 부팅되도록 순위를 올려줍니다.

![](/assets/post_img/usb-bootdisk-test-in-biosboot-vmware-works/341648690-bc1e4bc6-6dd5-4be6-8958-376e2ec99304.png)

위 이미지와 같이 세팅한 다음 F10 + Enter 를 눌러 저장해줍니다. 바이오스가 부팅될 때 USB 부팅디스크로 부팅되는지 확인합니다.



Linux를 설치할 때 킥스타트를 통해 패키지를 설치하는 경우 UEFI, BIOS 부팅에 따라서 필요한 패키지가 달라지는 듯 합니다. UEFI에서 문제없던 패키지 설치가 BIOS에서 문제가 발생하는 경우가 더러 있으니.. 항상 고객사에서 설치하려는 바이오스 환경을 물어보고 이에 맞는 테스트 작업이 필요해보입니다.
