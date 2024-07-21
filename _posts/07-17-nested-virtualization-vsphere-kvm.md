---
title: "ESXi에 RHEL VM 생성 후 KVM 기동하기 (Nested Virtualization)"
author: heomne
date: 2024-07-14 +/-TTTT
tags: linux blog
categories: Blog
pin: false
---
ESXi에 생성한 RHEL VM에서 Pacemaker의 ipmilan STONITH를 테스트할 환경을 만드는 방법을 찾다가 KVM설치 후 VirtualBMC를 통해 ipmilan을 테스트할 수 있는 환경을 구축할 수 있어 내용을 정리했습니다.

설치 프로세스는 다음과 같습니다.
1. vsphere에서 RHEL VM 생성
2. 생성한 RHEL VM에 KVM 설치
3. KVM에 RHEL VM 생성, 생성한 VM에 VirtualBMC 설치

그림으로 정리하면 아래와 같은 아키텍처로 구성됩니다.

![image](/assets/post_img/nested-virtualization-vsphere-kvm/image.png){: width="800"}{: .left}

하이퍼바이저로 설치된 ESXi에 RHEL VM을 생성 후, RHEL에 KVM을 생성하여 VM을 하나 더 생성합니다. 다양한 환경에서의 테스트를 목적으로 하기 때문에 위와 같은 아키텍처를 구성했고, 운영환경에서는 당연히 사용하는 케이스가 없을 것으로 생각됩니다. 내용을 찾아보니 이러한 구성을 중첩된 가상화(Nested Virtualization)라고 부르는 듯 합니다.

아무튼 아키텍쳐 설명은 여기까지하고, 이제 설치과정을 보도록 합시다.