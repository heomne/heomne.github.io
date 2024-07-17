---
title: "vsphere에 설치된 RHEL에 KVM 기동하기 (Nested Virtualization)"
author: heomne
date: 2024-07-14 +/-TTTT
tags: linux blog
categories: Blog
pin: false
---
vsphere에 생성한 VM에서 Pacemaker의 ipmilan STONITH를 테스트할 환경을 만드는 방법을 찾다가 KVM설치 후 VirtualBMC를 통해 ipmilan을 테스트할 수 있는 환경을 구축할 수 있어 내용을 정리했습니다.

설치 프로세스는 다음과 같습니다.
1. vsphere에서 RHEL VM 생성
2. 생성한 RHEL VM에 KVM 설치
3. KVM에 RHEL VM 생성, 생성한 VM에 VirtualBMC 설치

그림으로 정리하면 아래와 같은 아키텍처를 가집니다.
![image](/assets/post_img/nested-virtualization-vsphere-kvm/image.png)


