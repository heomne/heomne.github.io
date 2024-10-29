---
title: "[Linux] 네트워크 NIC에서 NO-CARRIER가 출력되는 이유"
author: heomne
date: 2024-10-29 +/-TTTT
tags: linux network
categories: Linux
pin: false
---

## ISSUE

active-backup으로 본딩이 구성되어있는 고객사의 네트워크 구성에서 한쪽 포트가 접촉불량이 나는지 
일시적으로 연결이 되었다가 Down되는 현상이 지속적으로 발생하여 NIC를 교체하기로 걸정했습니다.

NIC를 교체하게되면 MAC 주소가 달라지기 때문에 OS에서 기존의 bond와 ethernet 인터페이스를 제거 후 서버를 재부팅해야합니다.   
(설정파일 백업은 필수)

문제는 교체한 NIC Ethernet 포트에 랜선 연결 후 `ip link show` 명령어 입력 시 아래 이미지와 같이 상태값이 출력됩니다.

![NO-CARRIER 상태 이미지](/assets/post_img/network-shows-no-carrier/image.webp)

`ens192` `ens224` 두 Ethernet 모두 `NO-CARRIER` 상태가 표시되고있으며, `bond0` 역시 마찬가지로 같은 상태가 표시되고있습니다.

## Solution

`NO-CARRIER` 상태가 뜨는 이유는 다양한데, 대부분 하드웨어 문제로 인해 발생합니다.

`NO-CARRIER` 상태는 하드웨어로부터 신호를 받지 못한다는 것을 의미합니다.  
서버에 장착할 수 있는 포트는 `ens192`, `ens224` 총 2개로, `ip link show` 명령어 입력 시 해당 포트가 감지되어 출력된 것은 맞지만 랜선이나 GBIC 등의 호환 문제로 인해 **하드웨어로 부터 신호를 받지 못하는 경우 `NO-CARRIER` 상태가 출력**됩니다.

서버 장비를 살펴보니 NIC에 GBIC, 랜선을 장착했음에도 불구하고 Link LED에 불이 들어오지 않았고, NIC-GBIC 간 호환 문제로 인식되지 않는 것으로 확인됐습니다.  
기존 NIC는 DELL GBIC과 호환되었으나, 교체한 NIC는 Intel GBIC과 호환되는 장비였습니다.

GBIC을 Intel 제조사로 교체하니 Link LED도 정상적으로 불이 들어왔고, `NO-CARRIRER`도 사라지고 정상적으로 네트워크가 활성화된 모습을 보여주었습니다.

```terminal
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens192: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master bond0 state UP group default qlen 1000
    link/ether 00:50:56:bc:90:de brd ff:ff:ff:ff:ff:ff
    altname enp11s0
3: ens224: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master bond0 state UP group default qlen 1000
    link/ether 00:50:56:bc:90:de brd ff:ff:ff:ff:ff:ff permaddr 00:50:56:bc:8b:82
    altname enp19s0
5: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 00:50:56:bc:90:de brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.69/32 scope global noprefixroute bond0
       valid_lft forever preferred_lft forever
    inet6 fe80::a6fe:3b0c:ecd6:b49/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

결과적으로 NIC 하드웨어 장비 간 호환 이슈로 인해 하드웨어 신호를 잡지 못해 발생한 헤프닝이었네요.

## Note

### `nmcli con up`, `ip link dev set up` 명령어 차이

처음에는 OS문제인가 싶어 `nmcli con up <nic>` 명령어를 사용 후 `nmcli device status`로 조회해봤는데, 아래와 같이 device가 활성화된걸로 보입니다.

```terminal
[root@heomne ~]# nmcli device status
DEVICE  TYPE      STATE                   CONNECTION
bond0   bond      connected               bond0
ens192  ethernet  connected               ens192
ens224  ethernet  connected               ens224
lo      loopback  connected (externally)  lo
```

`nmcli` 명령어를 사용할 경우 `NetworkManager`데몬을 통해 소프트웨어적으로 device를 활성화/비활성화하기 때문에 하드웨어 상황과 관계없이 NIC를 활성화(connected), 비활성화 시킵니다.  
결과적으로 `NO-CARRIER` 상태로 출력되는 것은 똑같았고 통신도 되지 않았습니다. 

명령어 작동 방식을 제대로 알지 못하고 사용하여 트러블슈팅 과정에서 OS 문제인지 하드웨어 문제인지 혼동되는 상황이 발생했는데, 앞으로는 주의해서 명령어를 사용해야겠습니다.

`ip link dev set up <nic>`명령어의 경우 연결된 하드웨어 NIC를 up/down 상태로 전환하는 명령어로,  
명령어를 입력한 후 이더넷 포트를 확인해보면 LED 점등여부를 통해 활성화/비활성화 여부를 확인할 수 있습니다.

## References
- [Why does an interface show NO-CARRIER?](https://access.redhat.com/solutions/4815731)
- [Why does ethtool show 'no link' for ethernet interface even though cable is physically connected?](https://access.redhat.com/solutions/46885)