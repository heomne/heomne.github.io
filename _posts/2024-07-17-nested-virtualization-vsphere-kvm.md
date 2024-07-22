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

아키텍쳐 설명은 여기까지하고, 이제 설치과정을 보겠습니다.

## ESXi VM 생성 및 RHEL 설치

### KVM으로 사용할 RHEL VM 생성
   
VM을 생성할 때 CPU 항목에 [하드웨어 가상화] - [게스트 운영 체제에 하드웨어 지원 가상화 표시]를 **반드시 체크**합니다. 체크하지않으면 KVM에서 VM을 생성했을 때 부팅이 안될정도로 VM이 매우 느려집니다. 생성하는 VM 사양은 아래와 같습니다.
    
- RHEL 8.6
- CPU: 4 core
- RAM: 32G
- Disk: 250GB (Thin Provisioning)

## RHEL 설치
RHEL 설치 시 주의해야할 내용만 정리합니다.
- 설치 시 Server with GUI를 확인 후 아래 3개 항목을 확인 후 설치합니다.
    - Virtualization Client
    - Virtualization Hypervisor
    - Virtualization Tools
- RHEL 설치 후 터미널에서 Virtualization Technology 지원 여부를 확인합니다.
    - `cat /proc/cpuinfo | grep vmx`    
    ```terminal
    [root@PACEMAKERKVM01 ~]# cat /proc/cpuinfo | grep vmx
    flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush
    mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon nopl xtopology
    tsc_reliable nonstop_tsc cpuid pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe
    popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch
    invpcid_single ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow vnmi ept vpid ept_ad fsgsbase
    tsc_adjust bmi1 avx2 smep bmi2 invpcid avx512f avx512dq rdseed adx smap clflushopt clwb avx512cd
    avx512bw avx512vl xsaveopt xsavec xgetbv1 xsaves arat pku ospke avx512_vnni md_clear flush_l1d
    arch_capabilities
    ...
    ```
flags 출력이 되어야 정상이며, 출력되는 텍스트가 없을 경우 설정에 문제가 있거나 VT를 지원하지 않는 CPU이니 하드웨어 스펙을 확인해야합니다.



## KVM 설치 및 구성

### KVM 설치

- 설치되지 않은 패키지가 있는지 확인합니다.  
    - `yum install qemu-kvm libvirt virt-install virt-manager`
    - 설치 화면에서 virtualization 관련 패키지를 설치했을 경우 Nothing to do가 출력됩니다.
    
- libvirtd를 활성화합니다.
    - `systemctl enable --now libvirtd`
    - `systemctl status libvirtd`
    
    ```terminal
    [root@PACEMAKERKVM01 ~]# systemctl status libvirtd
    ● libvirtd.service - Virtualization daemon
       Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
       Active: active (running) since Tue 2023-05-30 14:07:18 KST; 19h ago
         Docs: man:libvirtd(8)
               https://libvirt.org
     Main PID: 8317 (libvirtd)
        Tasks: 26 (limit: 32768)
       Memory: 114.2M
       CGroup: /system.slice/libvirtd.service
               ├─1981 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
               ├─1982 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
               ├─8317 /usr/sbin/libvirtd --timeout 120
               ├─8735 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/internal.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
               └─8736 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/internal.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
    ```
    
- virt-manager 명령어 입력하여 virtual machine manager를 켭니다.
    - `virt-manager`
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/20f13b1e-385f-4e51-9943-6e23e84678f4/image-20230710-063159.png
    

## KVM 네트워크 구성

- 네트워크는 NAT망과 내부망 2개를 생성합니다., [Edit] - [Connection Details]를 클릭합니다.
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/c87442b9-dfa0-4e86-91f4-ab1254e6949b/image-20230710-063237.png
    
- 네트워크는 현재 default만 존재하는데, 내부망을 생성하기위해 좌측하단에 + 버튼을 클릭합니다.
- Name은 internal, Mode는 Isolated를 선택하고, IPv4 대역폭은 필요하면 설정합니다. (start를 100으로 수정했습니다.)
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/1616204f-8cd6-4230-b151-c1e502ab8481/image-20230710-063308.png
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/ffbcf280-bac5-4e16-908b-df5299c73910/image-20230710-063328.png
    

## VM 생성

- Local install media 선택 후 [Forward]를 클릭합니다.
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/887e8a1e-ff2e-4ecb-ba11-77d39f3a52e6/image-20230710-063409.png
    
- iso 파일 선택 후 Forward를 클릭합니다. (iso 파일은 다운로드 받아서 KVM 서버에 넣어주어야합니다.)
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/32f35cce-624a-41c5-88f0-a9272602ffad/image-20230710-063438.png
    
- 메모리 설정 (Memory 2G, CPU 2), 디스크 설정 (20G), 이름 설정 후 forward를 클릭합니다.
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/bb53d684-24c8-494f-8968-57a91782a010/image-20230710-063506.png
    
- 생성된 VM을 더블클릭하여 새 창을 띄운 후 전구 버튼 클릭하여 VM 하드웨어 정보를 전환합니다.
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/2fc5cb1d-9d9d-480a-97a2-c621e7a37d79/image-20230710-063548.png
    
- 좌측 하드웨어 목록 우클릭 후 [Add hardware]를 클릭합니다.
- Network에서 internal isolated network 클릭 후 finish를 클릭합니다.
    
    !https://prod-files-secure.s3.us-west-2.amazonaws.com/cb52674e-2e4c-4737-9639-d889f2ddb236/e05f025b-8d13-431f-bbf1-0222c0fce471/image-20230710-063613.png
    
이제 KVM에 RHEL VM을 설치할 수 있습니다. 설치 후 NIC가 2개로 나오는지 확인합니다.