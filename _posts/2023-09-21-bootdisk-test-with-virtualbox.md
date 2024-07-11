---
title: USB 부팅디스크 테스트 방법 (with VirtualBox)
author: heomne
updated: 2024-06-20
tags:
  - troubleshooting
  - linux
categories: Linux
---
USB로 부팅디스크를 만들고나서 설치가 정상적으로 되는지 테스트를 하려면 사용하지않는 노트북이나 컴퓨터가 필요합니다. 사용하는 노트북으로도 테스트는 할 수 있겠지만 설치과정까지 테스트하기는 어렵습니다.(내 데이터가 다 날라갑니다..)

다행히 부팅디스크를 테스트하는 툴이 여러가지 있었는데요, 대표적으로 MobaLiveCD를 많이 추천하시는 것 같았습니다. 하지만 제가 테스트하려는 부팅디스크는 킥스타트가 설정된 RHEL, x86_64 환경인데 해당 프로그램으로는 설치과정까지 테스트하긴 힘들었습니다.

hyper-v로도 테스트가 가능했었는데, 가상 디스크로 변환하는 과정이 꽤나 피곤하더라구요. 킥스타트에 문제가 있는 부분을 바꾸면서 테스트하기에는 가상 디스크로 변환시간이 길어서 이것도 포기하게되었습니다.

그러다가 우연히 VirtualBox에서 USB 부팅기능을 발견하게되어 쉽게 테스트가 가능한 방법을 알아내어 공유하게되었습니다.

## VirtualBox 설치

USB 부팅디스크를 통해 가상머신을 부팅하려면 **VirtualBox 7 버전이 필요**합니다. 저는 7.0.10 버전을 다운받았는데요, 아래 링크를 통해 OS환경에 맞게 다운받아 설치합니다.

<https://www.virtualbox.org/wiki/Downloads>

[](https://www.virtualbox.org/wiki/Downloads)

## VM 생성

프로그램이 설치되었으면 \[머신] - \[새로 만들기]를 클릭해줍니다.

![](/assets/post_img/bootdisk-test-with-virtualbox/269493158-6b27ebe7-1533-4e76-a48b-f24591a24e71.png)

이름을 설정해주고, 아래 종류와 버전을 선택합니다. 저는 RHEL을 테스트할 예정이라 아래와 같이 설정했습니다.

![](/assets/post_img/bootdisk-test-with-virtualbox/269493367-d3efbc1c-5fe7-4e09-b811-cc188bbf6f38.png)

가상머신의 사양을 설정해줍니다. 설치 프로세스를 빠르게 넘기기 위해 기본 메모리를 4G, 프로세서는 4 Core로 설정해줍니다.\
UEFI환경에서 테스트하려면 Enable EFI를 체크해줍니다. 최근 리눅스를 설치하는 환경 대부분이 UEFI 환경이기 때문에 저는 체크해주었습니다. 체크하지 않을 경우 Legacy 환경에서 부팅됩니다. 일반적인 경우라면 체크하지않아도 테스트하는데는 지장이 없습니다.

![](/assets/post_img/bootdisk-test-with-virtualbox/269494046-853f58bb-a4d7-40b2-8882-c5eb5132ada9.png)

가상디스크는 넉넉하게 30G로 설정해줍니다. 부팅디스크가 정상적으로 설치되는지 확인하는 목적이므로 30G정도 설정해주면 충분합니다.

![](/assets/post_img/bootdisk-test-with-virtualbox/269495888-f85e83be-1b87-4600-b48f-9325a5c5c889.png)

설정 후 Finish를 눌러 가상머신을 생성합니다.

## USB로 부팅되도록 옵션 설정

VM이 생성되면 우클릭 - \[설정]으로 진입할 수 있습니다.

![](/assets/post_img/bootdisk-test-with-virtualbox/269497102-595b0048-185c-4c29-91c8-47889e38876a.png)

USB 탭을 클릭하고, \[USB 3.0(xxHCI) 컨트롤러] 선택 후 USB에 + 되어있는 아이콘을 클릭합니다.\
현재 디바이스에 연결된 USB의 이름을 클릭하면 USB가 추가되고 확인을 클릭하면 해당 USB로 부팅됩니다.[](https://www.virtualbox.org/wiki/Downloads)

![](/assets/post_img/bootdisk-test-with-virtualbox/269497733-d4c550a4-d6ad-414c-8471-691d239ee88b.png)

[](https://www.virtualbox.org/wiki/Downloads)