---
title: "Pacemaker 클러스터 제거 방법(RHEL8)"
author: heomne
date: 2025-01-12 +/-TTTT
tags: linux pacemaker
categories: Linux
pin: false
---

Pacemaker 클러스터를 제거하고 구성했던 HA 리소스를 롤백하는 방법에 대해 작성합니다.

## Pacemaker 상태 확인
클러스터를 제거하기 전 클러스터에 등록된 리소스를 확인합니다. 각 등록된 리소스에 대해 클러스터 제거 후 어떻게 영향을 받게 될지 미리 확인합니다. 
예시로 공유 볼륨이 구성된 경우 `/etc/lvm/lvm.conf` 설정도 다시 원래 상태로 돌려놓아 pacemaker에서 더 이상 해당 리소스를 관리하지않게 바꾸어주어야 합니다.

## 클러스터 제거 (Active 노드에서만 입력)
다음 명령어를 입력하여 pacemaker 클러스터를 제거할 수 있습니다.
- 클러스터를 종료합니다.  
  `pcs cluster stop --all`

- 클러스터가 활성화 상태로 되어있는 경우 비활성화 합니다.  
  `pcs cluster disable --all`

- (Optional) 클러스터에 공유 볼륨이 구성된 경우 해당 공유 볼륨의 태깅을 제거합니다.  
  `vgchange --systemid "" <vg-name>`

- 클러스터를 제거합니다.  
  `pcs cluster destroy --all`

클러스터가 제거되면 `/etc/corosync/corosync.conf` 파일이 없어지므로 해당 파일 존재여부를 통해 클러스터 구성여부를 확인할 수 있습니다.

## 공유볼륨 설정 해제 (모든 노드에서 입력)
공유 볼륨 설정을 해제하기 위해 `lvm.conf` 파일을 클러스터 구성 전으로 복구합니다.
- `/etc/lvm/lvm.conf` 파일을 수정합니다. `system_id_source` 옵션값을 `uname`에서 `none`으로 변경합니다.
- `volume_list` 또는 `auto_activation_volume_list` 옵션을 사용한 경우 해당 옵션값을 주석처리하거나 사용하는 VG를 리스트에 추가합니다.  
  `vi /etc/lvm/lvm.conf`
```bash
...
system_id_source=none
...
# volume_list = [ "rhel" ]
...
```

- 부팅디스크 이미지를 백업 및 재생성합니다.  
  `cp /boot/initramfs-$(uname -r).img ~/initramfs-$(uname -r).img_bak`  
  `dracut -f -v`

- 서버를 재기동합니다.  
  `reboot`



