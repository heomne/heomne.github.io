---
title: "(RHEL) lvm2-lvmetad 비활성화"
author: heomne
date: 2024-07-03
tags: linux troubleshooting
categories: Linux
pin: false
---

> **참고: RHEL8 버전부터는 `lvm2-lvmetad`데몬이 존재하지 않으므로, 해당 옵션을 사용할 필요가 없습니다.**
{: .prompt-tip }

lvm2-lvmetad 비활성화를 위해서는 `/etc/lvm/lvm.conf` 파일을 변경 후, 데몬 중지 및 비활성화 작업을 진행해주어야합니다.

`/etc/lvm/lvm.conf` 파일에서 'use_lvmetad =' 검색 후 1을 0으로 변경합니다.
```bash
        # See the use_lvmetad comment for a special case regarding filters.
        #     This is incompatible with lvmetad. If use_lvmetad is enabled,
        # Configuration option global/use_lvmetad.
        # while use_lvmetad was disabled, it must be stopped, use_lvmetad
        use_lvmetad = 0
```

파일 저장 후 lvm2-lvmetad 데몬을 중지합니다.
```
systemctl stop lvm2-lvmetad
systemctl disable lvm2-lvmetad
```
데몬이 비활성화 되었는지 확인합니다.
```terminal
[root@localhost ~]# systemctl is-enabled lvm2-lvmetad
static
```

데몬이 자동으로 실행되는 케이스가 있기 때문에 가능하면 OS를 재부팅 해주는게 좋습니다.

## lvm2-lvmetad

`lvm2-lvmetad`는 LVM의 메타데이터를 관리하는 데몬으로, LVM의 메타데이터를 최적화하고 성능을 향상시키는 역할을 하는 데몬입니다.
보통 RHEL 7 버전에서 주로 많이 사용되는 데몬으로, 메타데이터를 캐싱하여 스토리지 디바이스 스캔을 감소시키는 역할을 메인으로 수행합니다.

해당 데몬을 비활성화하는 이유는 여러가지가 있는데, 그 중 하나는 HA를 구성할 때 `lvm2-lvmetad`로 인해 공유볼륨 스캔이 정상적으로 반영되지 않는 이슈를 방지하기위해서입니다.
HA 클러스터를 구성하고 기존 스토리지 리소스의 볼륨을 증설했는데 1호기에서는 증설한 용량이 반영되고 2호기에서는 증설된 용량이 반영안되는 문제가 발생하게되며, 이로인해 failover가 정상적으로 수행되지 않는 문제가 발생합니다.

따라서 `lvm2-lvmetad`가 활성화 되어있는 상태에서는 클러스터가 Online인 상황에서 무중단으로 스토리지 리소스를 확장하기가 어려운 부분이 있을 수 있어 `lvm2-lvmetad` 데몬을 비활성화하기도 합니다. 클러스터 구성 전에 `lvm2-lvmetad` 데몬을 비활성화하고 HA 클러스터를 구축하는 케이스가 있으며, 데몬을 비활성화하게되면 스토리지를 증설해도 상대방 노드에 증설된 용량이 바로 반영되기때문에 위 문제를 해결할 수 있습니다.