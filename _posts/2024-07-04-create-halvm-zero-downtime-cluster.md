---
title: "(RHEL) Pacemaker 무중단 상태로 HA-LVM 신규생성 테스트"
author: heomne
date: 2024-07-04
tags: linux troubleshoot
categories: Linux
pin: false
---

[**lvm2-lvmetad 데몬을 비활성화**](https://heomne.github.io/posts/lvm2-lvmetad-disable/)한 노드에 Pacemaker 클러스터를 구성한 경우, 신규 스토리지 리소스를 다운타임없이 생성할 수 있습니다.

## 테스트 환경
- RHEL 7.9 버전 서버 2대
- Pacemaker 클러스터 구성
  - two-node 구성
  - 스토리지 리소스(LVM, Filesystem)가 아래와 같이 이미 구성된 상태로 가정
    ```terminal
    Cluster name: rhelha
    Stack: corosync
    Current DC: hostha02-hb (version 1.1.23-1.el7-9acf116022) - partition with quorum
    Last updated: Thu Jul  4 13:42:23 2024
    Last change: Thu Jul  4 13:33:58 2024 by root via cibadmin on hostha02-hb

    2 nodes configured
    16 resource instances configured

    Online: [ hostha01-hb hostha02-hb ]

    Full list of resources:

    kdump  (stonith:fence_kdump):  Started hostha01-hb
    fence_vmware-01        (stonith:fence_vmware_rest):    Started hostha02-hb
    fence_vmware-02        (stonith:fence_vmware_rest):    Started hostha01-hb
    Resource Group: rhelha
        havg       (ocf::heartbeat:LVM):   Started hostha01-hb
        hafs       (ocf::heartbeat:Filesystem):    Started hostha01-hb
        ha_vip     (ocf::heartbeat:IPaddr2):       Started hostha01-hb
    Resource Group: rhelha2
        havg2      (ocf::heartbeat:LVM):   Started hostha02-hb
        hafs2      (ocf::heartbeat:Filesystem):    Started hostha02-hb
        ha_vip2    (ocf::heartbeat:IPaddr2):       Started hostha02-hb
    Clone Set: ping-clone [ping]
        Started: [ hostha01-hb hostha02-hb ]

    Daemon Status:
      corosync: active/disabled
      pacemaker: active/disabled
      pcsd: active/enabled
    ```
  - `/etc/lvm/lvm.conf` 파일에 `use_lvmetad = 0`, `volume_list = [ "rhel" ]` 설정된 상태
    ```terminal
    [root@hostha01 ~]# cat /etc/lvm/lvm.conf | egrep 'use_lvmetad = 0|volume_list = \[ "rhel" \]'
            use_lvmetad = 0
            volume_list = [ "rhel" ]  # rhel = boot-volume
    ```

## 신규 스토리지 생성(PV, VG, LV)
1. 새로운 하드디스크를 서버 장비에 연결 후, `scsi-rescan` 명령어를 입력하여 스토리지를 재스캔합니다. (모든노드에서 입력)
2. 두 노드 모두 스토리지가 연결되었는지 확인 후, `pvcreate`, `vgcreate` 명령어로 피지컬 볼륨 및 볼륨 그룹 `havg3`을 생성합니다. (1호기에서만 입력)
  - `pvcreate /dev/sdk`
  - `vgcreate havg3 /dev/sdk`
3. `vgs -o+tags` 명령어를 입력하여 양쪽 노드에 볼륨 그룹이 생성되었는지, 용량이 같은지 확인합니다.
  볼륨 그룹 `havg3`은 생성되었지만 페이스메이커에 의해 활성화되지는 않았기 때문에 `pacemaker` 태그가 추가되어있지 않습니다.
```terminal
[root@hostha01 ~]# vgs -o+tags
  VG    #PV #LV #SN Attr   VSize   VFree VG Tags
  havg    5   1   0 wz--n-  29.96g    0  pacemaker
  havg2   2   1   0 wz--n-  14.98g    0  pacemaker
  havg3   3   1   0 wz--n- <14.98g    0               # havg3 -> pacemaker tag not attached
  rhel    1   3   0 wz--n- <99.00g 4.00m
```
4. 1호기에서 `lvcreate` 명령어로 LVM을 생성하려고하면 아래와 같은 텍스트가 출력되며 LV가 생성되지 않습니다.
```terminal
[root@hostha01 ~]# lvcreate -n halv3 -l +100%FREE havg3
  Volume "havg3/halv3" is not active locally (volume_list activation filter?).
  Aborting. Failed to wipe start of new LV.
```
  `/etc/lvm/lvm.conf`에서 설정한 `volume_list` 옵션때문에 로컬환경에서 LV 생성이 불가합니다. 이를 우회하기 위해서는 havg3 VG에 'pacemaker' 태그를 붙여준 후 LV를 생성해주어야합니다.
5. 1호기에서 아래 명령어를 입력하여 `havg3` 볼륨 그룹에 'pacemaker' 태그 추가 후, 볼륨 그룹을 활성화합니다.
  - `vgchange --addtag pacemaker havg3`
  - `vgchange -ay havg3 --config 'activation { volume_list = [ "@pacemaker" ]}'`
```terminal
[root@hostha01 ~]# vgchange --addtag pacemaker havg3
  Volume group "havg3" successfully changed
[root@hostha01 ~]# vgchange -ay havg3 --config 'activation { volume_list = [ "@pacemaker" ]}'
  1 logical volume(s) in volume group "havg3" now active
```
6. 1호기에서 아래 명령어를 입력하여 LV를 다시 생성합니다.
  - `lvcreate -n halv3 -l +100%FREE havg3 --config 'activation { volume_list = [ "@pacemaker" ]}'`
  - `mkfs.xfs /dev/havg3/halv3`
```terminal
[root@hostha01 ~]# lvcreate -n halv3 -l +100%FREE havg3 --config 'activation { volume_list = [ "@pacemaker" ]}'
  Logical volume "halv3" created.
[root@hostha01 ~]# lvs
  LV    VG    Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  halv  havg  -wi-ao----  29.96g
  halv2 havg2 -wi-------  14.98g
  halv3 havg3 -wi-a----- <14.98g
  home  rhel  -wi-ao---- <41.12g
  root  rhel  -wi-ao----  50.00g
  swap  rhel  -wi-ao----  <7.88g
```
7. LV 생성을 위해 일시적으로 `havg3` 볼륨 그룹을 활성화했으므로, 1호기에서 다시 비활성화 시켜줍니다.
  - `vgchange -an havg3`
  - `vgchange --deltag pacemaker havg3`
```terminal
[root@hostha01 ~]# vgchange -an havg3
  0 logical volume(s) in volume group "havg3" now active
[root@hostha01 ~]# vgchange --deltag pacemaker havg3
  Volume group "havg3" successfully changed
[root@hostha01 ~]# vgs -o+tags
  VG    #PV #LV #SN Attr   VSize   VFree VG Tags
  havg    5   1   0 wz--n-  29.96g    0  pacemaker
  havg2   2   1   0 wz--n-  14.98g    0  pacemaker
  havg3   3   1   0 wz--n- <14.98g    0             # inactive
  rhel    1   3   0 wz--n- <99.00g 4.00m
```

## Pacemaker 리소스 생성
페이스메이커 리소스 생성은 기존에 생성했던 명령어 입력과 같습니다. 마운트포인트 지점 생성 후 리소스를 생성합니다.
  - `mkdir /mount/halv3` (모든 노드)
  - `pcs resource create havg3 LVM volgrpname=havg3 exclusive=true --group rhelha3` (1호기)
  - `pcs resource create halv3 Filesystem device=/dev/havg3/halv3 directory=/mount/halv3 fstype=xfs run_fsck=no --rhelha3` (1호기)

  서비스가 정상적으로 실행되어있는지 확인합니다.
```terminal
Cluster name: rhelha
Stack: corosync
Current DC: hostha02-hb (version 1.1.23-1.el7-9acf116022) - partition with quorum
Last updated: Thu Jul  4 14:40:35 2024
Last change: Thu Jul  4 14:40:17 2024 by root via crm_resource on hostha01-hb

2 nodes configured
18 resource instances configured

Online: [ hostha01-hb hostha02-hb ]

Full list of resources:

kdump  (stonith:fence_kdump):  Started hostha01-hb
fence_vmware-01        (stonith:fence_vmware_rest):    Started hostha02-hb
fence_vmware-02        (stonith:fence_vmware_rest):    Started hostha01-hb
Resource Group: rhelha
    havg       (ocf::heartbeat:LVM):   Started hostha01-hb
    hafs       (ocf::heartbeat:Filesystem):    Started hostha01-hb
    ha_vip     (ocf::heartbeat:IPaddr2):       Started hostha01-hb
Resource Group: rhelha2
    havg2      (ocf::heartbeat:LVM):   Started hostha02-hb
    hafs2      (ocf::heartbeat:Filesystem):    Started hostha02-hb
    ha_vip2    (ocf::heartbeat:IPaddr2):       Started hostha02-hb
Clone Set: ping-clone [ping]
    Started: [ hostha01-hb hostha02-hb ]
Resource Group: rhelha3
    havg3      (ocf::heartbeat:LVM):   Started hostha01-hb
    hafs3      (ocf::heartbeat:Filesystem):    Started hostha01-hb
    
Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
```
