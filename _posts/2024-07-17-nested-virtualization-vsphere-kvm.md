---
title: "ESXi에 RHEL VM 생성 후 KVM 기동하기 (Nested Virtualization)"
author: heomne
date: 2024-07-14 +/-TTTT
tags: linux pacemaker
categories: Linux
pin: false
---
ESXi에 생성한 RHEL VM에서 Pacemaker의 ipmilan STONITH를 테스트할 환경을 만드는 방법을 찾다가 KVM설치 후 VirtualBMC를 통해 ipmilan을 테스트할 수 있는 환경을 구축할 수 있어 내용을 정리했습니다.

설치 프로세스는 다음과 같습니다.
1. vsphere에서 RHEL VM 생성
2. 생성한 RHEL VM에 KVM 설치
3. KVM에 RHEL VM 생성, 생성한 VM에 VirtualBMC 설치

그림으로 정리하면 아래와 같은 아키텍처로 구성됩니다.

![image](/assets/post_img/nested-virtualization-vsphere-kvm/image.webp){: width="800"}{: .left}

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
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063159.webp){: width="800"}{: .left}
    

## KVM 네트워크 구성

- 네트워크는 NAT망과 내부망 2개를 생성합니다., [Edit] - [Connection Details]를 클릭합니다.
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063237.webp){: .left}
    
- 네트워크는 현재 default만 존재하는데, 내부망을 생성하기위해 좌측하단에 + 버튼을 클릭합니다.
- Name은 internal, Mode는 Isolated를 선택하고, IPv4 대역폭은 필요하면 설정합니다. (start를 100으로 수정했습니다.)
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063308.webp){: .left}
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063328.webp){: .left}
    

## VM 생성

- Local install media 선택 후 [Forward]를 클릭합니다.
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063409.webp){: width="800"}{: .left}
    
- iso 파일 선택 후 Forward를 클릭합니다. (iso 파일은 다운로드 받아서 KVM 서버에 넣어주어야합니다.)
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063438.webp){: width="800"}{: .left}
    
- 메모리 설정 (Memory 2G, CPU 2), 디스크 설정 (20G), 이름 설정 후 forward를 클릭합니다.
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063506.webp){: width="800"}{: .left}
    
- 생성된 VM을 더블클릭하여 새 창을 띄운 후 전구 버튼 클릭하여 VM 하드웨어 정보를 전환합니다.
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063548.webp){: width="800"}{: .left}
    
- 좌측 하드웨어 목록 우클릭 후 [Add hardware]를 클릭합니다.
- Network에서 internal isolated network 클릭 후 finish를 클릭합니다.
    
    ![image1](/assets/post_img/nested-virtualization-vsphere-kvm/image-20230710-063613.webp){: width="800"}{: .left}
    
이제 KVM에 RHEL VM을 설치할 수 있습니다. 설치 후 NIC가 2개로 나오는지 확인합니다.


## virtualBMC 설치

- virtualBMC를 사용하기위해 다음 명령어를 사용하여 패키지를 설치합니다.
    
    `yum install python3-pip`
    
    `pip3 install -U pip`
    
    `yum install gcc python3-devel ipmitool`
    
    `pip3 install virtualbmc`
    
- vbmc 시스템 데몬을 생성해줍니다.
    
    `vi /usr/lib/systemd/system/vbmcd.service`
    
    ```bash
    [Service]
    BlockIOAccounting = True
    CPUAccounting = True
    ExecReload = /bin/kill -HUP $MAINPID
    ExecStart = /usr/local/bin/vbmcd --foreground
    Group = root
    MemoryAccounting = True
    PrivateDevices = False
    PrivateNetwork = False
    PrivateTmp = False
    PrivateUsers = False
    Restart = on-failure
    RestartSec = 2
    Slice = vbmc.slice
    TasksAccounting = True
    TimeoutSec = 120
    Type = simple
    User = root
    
    [Unit]
    After = libvirtd.service
    After = syslog.target
    After = network.target
    Description = vbmc service
    
    [Install]
    WantedBy=multi-user.target
    ```
    

	`systemctl daemon-reloadsystemctl enable --now vbmcd`

- vbmc 포트를 추가합니다.
    
    `vbmc add --username {username} --password {password} --port {ipmi-port} --libvirt-uri qemu:///system {VM-name}`
    
    `vbmc add --username pacemaker01 --password pacemaker01 --port 6230 --libvirt-uri qemu:///system Pacemaker01`
    
    `vbmc add --username pacemaker02 --password pacemaker02 --port 6231 --libvirt-uri qemu:///system Pacemaker02`
    
- vbmc 리스트를 확인합니다.
    
    `vbmc list`
    
    ```terminal
    [root@PACEMAKERKVM01 ~]# vbmc list
    +-------------+---------+---------+------+
    | Domain name | Status  | Address | Port |
    +-------------+---------+---------+------+
    | Pacemaker01 | running | ::      | 6230 |
    | Pacemaker02 | running | ::      | 6231 |
    +-------------+---------+---------+------+
    ```
    
- vbmc 상세정보를 확인할 수 있습니다.
`vbmc show Pacemaker01`
    
    ```terminal
    [root@PACEMAKERKVM01 ~]# vbmc show Pacemaker01
    +-----------------------+----------------+
    | Property              | Value          |
    +-----------------------+----------------+
    | active                | True           |
    | address               | ::             |
    | domain_name           | Pacemaker01    |
    | libvirt_sasl_password | ***            |
    | libvirt_sasl_username | None           |
    | libvirt_uri           | qemu:///system |
    | password              | ***            |
    | port                  | 6230           |
    | status                | running        |
    | username              | pacemaker01    |
    +-----------------------+----------------+
    ```
    
- vmbc를 설치하면 네트워크 브릿지(virbr1)가 하나 생성됩니다. (virbr0은 KVM브릿지) KVM 게스트에서는 virbr1의 아이피를 통해 ipmi를 확인할 수 있습니다.
`ip a`
    
    ```terminal
    [root@PACEMAKERKVM01 ~]# ip a
    ...
    3: virbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 52:54:00:15:a6:42 brd ff:ff:ff:ff:ff:ff
        inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
           valid_lft forever preferred_lft forever
    4: virbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 52:54:00:f7:aa:4b brd ff:ff:ff:ff:ff:ff
        inet 192.168.100.1/24 brd 192.168.100.255 scope global virbr1
           valid_lft forever preferred_lft forever
    ...
    ```
    
- ipmitool로 노드 상태를 확인합니다.
`ipmitool -I lanplus -U pacemaker01 -P pacemaker01 -H 192.168.100.1 -p 6230 chassis status`
    
    ```terminal
    [root@PACEMAKERKVM01 ~]# ipmitool -I lanplus -U pacemaker01 -P pacemaker01 \
    -H 192.168.100.1 -p 6230 chassis status
    System Power         : on
    Power Overload       : false
    Power Interlock      : inactive
    Main Power Fault     : false
    Power Control Fault  : false
    Power Restore Policy : always-off
    Last Power Event     :
    Chassis Intrusion    : inactive
    Front-Panel Lockout  : inactive
    Drive Fault          : false
    Cooling/Fan Fault    : false
    ```
    
- 노드 시작, 종료, 재시작 테스트 명령어는 아래를 참고합니다.
`ipmitool -I lanplus -U pacemaker01 -P pacemaker01 -H 172.16.0.65 -p 6230 chassis power on`
    
    `ipmitool -I lanplus -U pacemaker01 -P pacemaker01 -H 172.16.0.65 -p 6230 chassis power off`
    
    `ipmitool -I lanplus -U pacemaker01 -P pacemaker01 -H 172.16.0.65 -p 6230 chassis power reset`
    

## ipmitool STONITH 생성 후 테스트

- Pacemaker 설치 과정은 생략하고, ipmilan STONITH 구성 후 정상적으로 작동하는지 테스트 해봅니다.
- 각 노드에서 `ipmitool` 명령어로 통신되는지 확인합니다.
    
    `ipmitool -I lanplus -U pacemaker01 -P pacemaker01 -H 192.168.100.1 -p 6230 chassis power on`
    
    `ipmitool -I lanplus -U pacemaker02 -P pacemaker02 -H 192.168.100.1 -p 6231 chassis power on`
    
    ```terminal
    [root@PACEMAKER01 ~]# ipmitool -I lanplus -U pacemaker01 -P pacemaker01 -H 192.168.100.1 -p 6230 chassis power on
    Chassis Power Control: Up/On
    [root@PACEMAKER01 ~]# ipmitool -I lanplus -U pacemaker02 -P pacemaker02 -H 192.168.100.1 -p 6231 chassis power on
    Chassis Power Control: Up/On
    ```
    
- fence_ipmilan 생성합니다.
    
    `pcs stonith create fence_ipmilan-01 fence_ipmilan lanplus=1 username=pacemaker01 password=pacemaker01 ip=192.168.100.1 ipport=6230 pcmk_host_list="PACEMAKER01 PACEMAKER02" pcmk_delay_base=5s`
    
    `pcs stonith create fence_ipmilan-02 fence_ipmilan lanplus=1 username=pacemaker02 password=pacemaker02 ip=192.168.100.1 ipport=6231 pcmk_host_list="PACEMAKER01 PACEMAKER02"`
    
- Fencing Test를 진행합니다.
    
    PACEMAKER01# `pcs stonith fence PACEMAKER02`
    
    ```java
    Node: PACEMAKER02 fenced
    ```
    
    PACEMAKER02# `pcs stonith fence PACEMAKER01`
    
    ```java
    Node: PACEMAKER02 fenced
    ```