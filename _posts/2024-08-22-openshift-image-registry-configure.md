---
title: "[Openshift] 오픈시프트 클러스터 내부 이미지 레지스트리 구축(CLI)"
author: heomne
date: 2024-08-22 +/-TTTT
tags: openshift
categories: OpenShift
pin: false
---

설치가 끝난 오픈시프트 클러스터에 PV 생성 후 내부 이미지 레지스트리를 구축하는 방법에 대하여 작성합니다. 

현재 구성된 오픈시프트 클러스터는 master노드 3개, worker 노드 3개, infra 노드 2개로 구성되어있습니다.
worker 노드에 Local Storage Operator를 사용해 로컬 볼륨을 프로비저닝 한 후, 생성된 PV를 이미지 레지스트리에 사용하는 방식으로 구축합니다.

## Requirements
이 글에서 오픈시프트 이미지 레지스트리를 구축하기위한 요구사양은 아래와 같습니다.

- Baremetal 설치 기준
- LocalVolume을 생성하기 위한 스토리지
  - 이 글에서는 worker 노드 3대에 100G의 스토리지를 장착했다고 가정합니다.
- `cluster-admin` 역할을 가진 사용자
- 최소 100G 이상 용량을 가진 Persistent Volume


## Local Storage Operator 설치
> Local Storage Operator(LSO)
  LSO는 레드햇에서 제공하는 로컬 스토리지 관리 오퍼레이터로, 아래의 작업을 수행할 수 있도록 해줍니다.
  - 디스크나 파티션 스토리지의 수정 없이 Storage Class에 할당할 수 있습니다.
  - LocalVolume 오브젝트를 통해 PV 및 StorageClass를 **정적**으로 프로비저닝 할 수 있습니다.

먼저 Local Storage Operator(LSO)를 설치합니다. LSO를 설치할 프로젝트를 만들어줍니다.

`oc adm new-project openshift-local-storage`

프로젝트를 생성한 후 아래의 yaml 파일을 생성하여 Local Storage Operator를 설치합니다.

`vi openshift-local-storage.yaml`
```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: local-operator-group
  namespace: openshift-local-storage
spec:
  targetNamespaces:
    - openshift-local-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: local-storage-operator
  namespace: openshift-local-storage
spec:
  channel: stable
  installPlanApproval: Automatic 
  name: local-storage-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```
`oc apply -f openshift-local-storage.yaml`

아래 명령어를 입력하여 서비스가 정상적으로 동작하는지 확인합니다.

`oc get pods -n openshift-local-storage`
```terminal
NAME                                      READY   STATUS    RESTARTS   AGE
local-storage-operator-6b985db688-6gmpb   1/1     Running   0          53m
```

`oc get csvs -n openshift-local-storage`
```terminal
NAME                                          DISPLAY         VERSION               REPLACES   PHASE
local-storage-operator.v4.14.0-202407260844   Local Storage   4.14.0-202407260844              Succeeded
```


## Persistent Volume(PV) 생성
PV를 생성하기 위해서는 오픈시프트의 worker 노드에 Root Volume 외에 PV로 사용할 수 있는 스토리지가 장착되어있어야 합니다. PV 생성을 위해 worker 노드 3대에 각 100G의 스토리지를 추가로 연결해놓았습니다.

### 스토리지 연결 여부 확인
Bastion 노드에서 worker01, worker02, worker03 노드에 각각 연결하여 스토리지가 장착되어있는지 확인합니다.
- `ssh core@worker01`
- `lsblk`
```terminal
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0  100G  0 disk
├─sda1   8:1    0    1M  0 part
├─sda2   8:2    0  127M  0 part
├─sda3   8:3    0  384M  0 part /boot
└─sda4   8:4    0 99.5G  0 part /var/lib/kubelet/pods/da791db1-bffa-4119-8c75-xxxxxxxxxx/volume-subpaths/nginx-conf/monitoring-plugin/1
                                /var
                                /sysroot/ostree/deploy/rhcos/var
                                /usr
                                /etc
                                /
                                /sysroot
sdb      8:16   0  100G  0 disk
```
`/dev/sdb` 블록 스토리지가 100G로 정상적으로 연결된 것을 확인할 수 있습니다. 같은 방법으로 worker02, worker03에서도 스토리지가 잘 연결되었는지 확인합니다.

### 스토리지 WWN 확인
스토리지가 연결되었다면 WWN을 확인해야할 차례입니다. worker 노드에서 다음 명령어를 입력하여 블록 스토리지 id를 확인합니다.

`ls -rtl /dev/disk/by-id/*`
```terminal
lrwxrwxrwx. 1 root root  9 Aug 15 05:30 /dev/disk/by-id/wwn-0x6000c123123123123123123123123134 -> ../../sda
...
lrwxrwxrwx. 1 root root  9 Aug 20 02:04 /dev/disk/by-id/wwn-0x6000c123412341234123412342314321 -> ../../sdb
lrwxrwxrwx. 1 root root  9 Aug 20 02:04 /dev/disk/by-id/scsi-SVMware_Virtual_disk_1234123423421234231234242313 -> ../../sdb
lrwxrwxrwx. 1 root root  9 Aug 20 02:04 /dev/disk/by-id/scsi-36000c123412342134123421341234123 -> ../../sdb
```

`/dev/sdb` 스토리지를 PV로 사용해야하기 때문에 `../../sdb`로 링크되어있는 부분의 wwn을 확인해야합니다. 
위의 출력된 내용으로 보았을 때 `worker01`노드의 `/dev/sdb` WWN은 `wwn-0x6000c123412341234123412342314321`으로 확인됩니다.

같은 방법으로 worker02, worker03 노드도 `/dev/sdb`의 WWN을 확인해줍니다.

### 스토리지 ext4 포맷
이제 `/dev/sdb` 스토리지를 ext4 파일시스템으로 포맷합니다. xfs 파일시스템으로 포맷해보았으나 서비스 pod 생성 과정에서 에러가 발생하기때문에 ext4 파일시스템으로 포맷해주어야합니다.

`sudo mkfs.ext4 /dev/sdb`

모든 worker 노드에 위 명령어를 입력하여 ext4 파일시스템으로 포맷합니다.


### LocalVolume 프로비저닝
이제 설정이 완료된 스토리지를 로컬 볼륨을 통해 프로비저닝 해줍니다. 아래의 yaml 파일을 작성하여 LocalVolume 오브젝트를 생성합니다.

`vi localVolume.yaml`
```yaml
apiVersion: "local.storage.openshift.io/v1"
kind: "LocalVolume"
metadata:
  name: "local-disks"
  namespace: "openshift-local-storage" 
spec:
  nodeSelector: 
    nodeSelectorTerms:
    - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker01
          - worker02
          - worker03
  storageClassDevices:
    - storageClassName: "local-sc" 
      volumeMode: Filesystem
      fsType: ext4
      devicePaths: 
        - /dev/disk/by-id/wwn-0x60001234123412341234123412341234
        - /dev/disk/by-id/wwn-0x60004324231421234123412343234234
        - /dev/disk/by-id/wwn-0x60002423421423432142342323234214
```
- `spec.nodeSelector`의 `values`에는 스토리지를 감지할 노드이름을 적어줘야합니다. worker 노드에 장착된 스토리지를 감지해야하므로 `worker01` `worker02` `worker03`을 작성합니다.
- `spec.storageClassDevices.storageClassName`은 LocalVolume 오브젝트를 생성할 때 스토리지 클래스도 같이 할당하는데, 이후 PVC를 생성할 때는 스토리지클래스를 참조하므로 이름을 기억해야합니다.
- `spec.storageClassDevices.devicePaths`에는 각 노드에 장착된 스토리지의 WWN을 적어줍니다. 오픈시프트에서 worker 노드에 있는 스토리지를 찾을 때 WWN을 참고하게됩니다.

> 생성한 LocalVolume을 오픈시프트 이미지 레지스트리로 사용하려면 `volumeMode`가 `Filesystem`으로 되어있어야하며, `fsType`은 `ext4`로 설정되어있어야합니다.

파일 저장 후, 다음 명령어를 입력하여 적용합니다.

`oc create -f localVolume.yaml`

### Local Storage Operator 상태 확인
LSO가 정상적으로 작동되는지 확인합니다.

`oc get all -n openshift-local-storage`
```terminal
Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
NAME                                          READY   STATUS    RESTARTS   AGE
pod/diskmaker-manager-24abe                   2/2     Running   0          46m
pod/diskmaker-manager-ab23y                   2/2     Running   0          46m
pod/diskmaker-manager-afd31                   2/2     Running   0          46m
pod/local-storage-operator-123412fggh-22fee   1/1     Running   0          4h42m

NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/local-storage-diskmaker-metrics   ClusterIP   172.30.248.143   <none>        8383/TCP   46m

NAME                               DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/diskmaker-manager   3         3         3       3            3           <none>          46m

NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/local-storage-operator   1/1     1            1           4h42m

NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/local-storage-operator-123412fggh   1         1         1       4h42m
```
- `daemonset.apps/diskmaker-manager`에서 `AVAILABLE`이 3개로 나와있는지 확인합니다.
- `pod/diskmakeer-manager`3개가 모두 `Running` 상태인지 확인합니다.
- `pod/local-storage-operator`가 `Running` 상태인지 확인합니다.

PV가 정상적으로 생성되었는지 확인합니다.

`oc get pv`
```terminal
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
local-pv-65xxxxxx   100Gi      RWO            Delete           Available           local-sc                46m
local-pv-88xxxxxx   100Gi      RWO            Delete           Available           local-sc                46m
local-pv-c8xxxxxx   100Gi      RWO            Delete           Available           local-sc                46m
```

모든 PV가 `AVAILABLE` 상태로 출력되고있습니다.

## OpenShift Image Registry 구성
이제 이미지 레지스트리 사용을 위한 PVC를 생성하여 오픈시프트 이미지 레지스트리를 구축해보도록 하겠습니다.

### PVC 생성
PVC를 생성하기위해 아래의 yaml 파일을 작성합니다.

`vi pvc.yaml`
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: image-registry-storage 
  namespace: openshift-image-registry 
spec:
  storageClassName: local-sc
  accessModes:
  - ReadWriteOnce 
  resources:
    requests:
      storage: 100Gi
```
- `spec.accessModes`는 반드시 `RWO`로 설정합니다. 베어메탈 설치 기준 오픈시프트 이미지 레지스트리는 `RWX`를 지원하지 않습니다.
- `spec.storageClassName`은 LocalVolume 생성에 사용한 스토리지 클래스 이름을 적어줍니다.

생성 후 파일을 적용합니다.

`oc create -f pvc.yaml`

### Openshift Image Registry Operator 설정 변경
오픈시프트 클러스터를 구성하게되면 오픈시프트 이미지 레지스트리 오퍼레이터는 기본적으로 설치가 되어있습니다. 
이미지 레지스트리를 사용할 스토리지가 없거나 완전히 구성이 되지 않은 상태에서는 관리되지않음 상태로 지정되기 때문에 사용할 수 없도록 설정되어있습니다. 

스토리지를 구성했으니 이제 오픈시프트 이미지 레지스트리를 관리하도록 오퍼레이터 설정을 변경해주어야합니다. 기존에 생성된 이미지 레지스트리 오퍼레이터의 구성을 변경합니다.

`oc edit config.imageregistry.operator.openshift.io -o yaml`

```yaml
...
spec:
  httpSecret: 45337753a6067334112664a2d7xxxxxxxxxxxxxxxxxxxxxxxxxx
  logLevel: Normal
  managementState: Managed
  observedConfig: null
  operatorLogLevel: Normal
  proxy: {}
  replicas: 1
  requests:
    read:
      maxWaitInQueue: 0s
    write:
      maxWaitInQueue: 0s
  rolloutStrategy: Recreate
  storage:
    managementState: Unmanaged
    pvc:
      claim: image-registry-storage
  unsupportedConfigOverrides: null
```
- `spec.managementState`를 `Removed`에서 `Managed`로 변경합니다.
- `spec.replicas`를 2에서 1로 변경합니다.
- `spec.rolloutStrategy`를 `RollingUpdate`에서 `Recreate`로 변경합니다.
- `spec.storage`를 `{}`에서 다음과 같이 변경합니다.
```yaml
  storage:
    pvc:
      claim:
```
  - `claim`을 공백으로 두는 이유는 PVC 이름을 `image-registry-storage`로 지정했기 때문에 오퍼레이터에서 자동으로 PVC를 찾아 claim을 작성하는지 확인하기위해서입니다.

모든 항목을 수정한 후 저장한다음 다시 같은 명령어를 입력하여 yaml 파일을 살펴보았을 때 `claim: image-registry-storage`로 지정되어있으면 정상입니다.

### OpenShift Image Registry 설치 확인

모든 오브젝트가 정상적으로 동작하는지 확인합니다.

`oc get pods -n openshift-image-registry`
```terminal
NAME
...                                              READY   STATUS      RESTARTS   AGE
image-registry-5ccccccc-cccc4                    1/1     Running     0          93s
...
```
- `image-registry-xxxxxxxx-xxxxx` pod가 Running 상태인지 확인합니다.

`oc get pvc -n openshift-image-registry`
```terminal
NAME                     STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
image-registry-storage   Bound    local-pv-65xxxxxx   100Gi      RWO            local-sc       3m15s
```
- PVC가 `Bound` 상태인지, `STORAGECLASS`가 `local-sc`로 되어있는지 확인합니다.

`oc get pv`
```terminal
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                                  STORAGECLASS   REASON   AGE
local-pv-65xxxxxx   100Gi      RWO            Delete           Bound       openshift-image-registry/image-registry-storage        local-sc                46m
local-pv-88xxxxxx   100Gi      RWO            Delete           Available                                                          local-sc                46m
local-pv-c8xxxxxx   100Gi      RWO            Delete           Available                                                          local-sc                46m
```
- PV중 하나가 `Bound` 상태이며, 오픈시프트 이미지 레지스트리의 PVC에 바운드 되어있는 것을 확인합니다.

`oc get clusteroperator image-registry`
```terminal
NAME             VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
image-registry   4.14.15   True        False         False      46h
```
- image-registry의 클러스터 오퍼레이터 상태가 `AVAILABLE: TRUE` 상태인지 확인합니다.



## References
- [Persistent storage using local volumes](https://docs.openshift.com/container-platform/4.14/storage/persistent_storage/persistent_storage_local/persistent-storage-local.html)
- [Configuring the registry for bare metal](https://docs.openshift.com/container-platform/4.14/registry/configuring_registry_storage/configuring-registry-storage-baremetal.html#configuring-registry-storage-baremetal)


![alt text](/assets/post_img/openshift-image-registry-configure/image.png)