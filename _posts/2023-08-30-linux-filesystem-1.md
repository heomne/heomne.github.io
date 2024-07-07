---
title: "[Linux] 파일시스템 - 1"
author: heomne
date: 2023-08-30
tags: linux_architecture filesystem
categories: Linux
pin: false
---
# 파일 시스템의 필요성

파일 시스템의 필요성에 대해 알아봅니다.

저장 장치의 기능은 단순하게 말하면 '저장 장치 안에 지정된 주소에 대해 특정 사이즈의 데이터를 읽거나 씀' 입니다. 만약 오피스 프로그램을 사용하여 문서를 작성했다면 메모리에 있는 문서 데이터를 저장 장치에 저장해야합니다. 저장하더라도 다음에 문서를 불러오기위해 데이터를 보관한 주소와 사이즈를 기억해야합니다.

이러한 데이터들이 여러 개 저장되기 때문에 작성했던 문서의 주소정보를 스스로 기록해야하고, 데이터를 넣을만한 공간이 얼마나 있는지 알기 위해 빈 영역을 관리할 필요가 있습니다.

이러한 복잡한 처리들을 관리하는 방법으로 파일시스템이 존재합니다.

파일시스템은 사용자에게 의미있는 하나의 데이터를 이름, 위치, 사이즈 등의 보조 정보를 추가해 파일이라는 단위로 관리합니다. 이 덕분에 사용자는 각 데이터의 이름을 기억하면 저장 장치에서 데이터의 위치나 사이즈 등의 복잡한 정보를 기억할 필요가 없게됩니다.

# 리눅스 파일시스템

리눅스의 파일시스템은 디렉터리라고 부르는 파일을 보관할 수 있는 특수한 파일이 존재합니다. 디렉터리 안에는 일반적인 파일이나 다른 디렉터리를 보관할 수 있으며, 같은 이름을 가진 파일은 각각 다른 디렉터리 안에 존재할 수 있습니다.

리눅스가 다루는 파일시스템은 ext4, xfs, Btrfs등 여러 개의 파일시스템이 있습니다. 각 시스템은 저장 장치의 데이터 구조 및 처리하기위한 프로그램이 다르게 구성되어있습니다. 당연히 구성에 따라 읽기, 쓰기 속도도 다릅니다.

하지만 어떠한 파일시스템이라도 같은 시스템 콜을 호출하여 통일된 인터페이스 접근이 가능합니다.

![](/assets/post_img/342017381-4b127b86-1943-400f-af48-9b2ce95968ad.png)

# 데이터와 메타데이터

파일시스템에는 데이터와 메타데이터라는 두 종류의 데이터가 있습니다.

* 데이터: 사용자가 작성한 문서나 사진, 동영상, 프로그램의 내용
* 메타데이터: **파일의 이름이나 저장 장치 내에 위치 사이즈 등의 보조 정보**

메타데이터는 열거한 부분 외에 다른 것들도 있습니다.

+ 종류: 데이터를 보관하는 일반 파일인지 디렉터리인지, 다른 종류인지 판별할 수 있는 정보

+ 시간 정보: 작성한 시간, 최후에 접근한 시간, 내용이 변경된 시간

+ 권한 정보: 어떤 사용자가 파일에 접근할 수 있는지

보통 스토리지의 사용정보를 조회할 때 \`df\` 명령어를 사용합니다, 해당 명령어는 파일시스템에 작성한 모든 파일과 메타데이텉의 사이즈도 더해지므로 참고해야합니다.

메타데이터는 큰 사이즈는 아니지만 작은 파일을 많이 작성하는 시스템에서는 파이르이 총 용량에 비해 사용량이 적은 일이 발생할 수 있습니다. 이는 메타데이터의 사이즈가 많이 차지하고 있을 때 발생합니다.

# 용량 제한
리눅스는 여러 사용자가 사용할 수 있습니다. 만약 특정 사용자가 파일시스템의 용량을 무제한으로 사용한다면 다른 사용자가 사용할 용량이 부족해지는 상황이 발생합니다. 특히 root 권한으로 동작해야하는 프로세스가 용량이 부족하여 시스템 처리를 못하게되면 시스템 전체가 동작할 수 없게 됩니다.

이러한 상황을 방지하기위해 파일시스템의 용량을 제한하는 기능이 있습니다. 이를 '쿼터'라고 부릅니다. 쿼터의 종류는 다음과 같습니다.
- 사용자 쿼터: 파일의 소유자인 사용자별로 용량을 제한합니다. 예를 들어 특정 사용자가 `/home` 디렉토리를 모두 사용하는 것을 방지합니다. XFS, ext4는 이 기능을 사용할 수 있습니다.

- 디렉터리 쿼터: 특정 디렉터리 별로 용량을 제한합니다. 예를 들어 프로젝트 멤버가 공유하는 디렉터리에 용량을 제한할 수 있습니다. 마찬가지로 XFS, ext4는 이 기능을 사용할 수 있습니다.

- 서브 볼륨 쿼터: 디렉터리 쿼터와 유사하게 파일시스템 내의 서브 볼륨이라는 단위별 용량을 제한합니다. Btrfs에서 사용할 수 있습니다.

# 파일시스템이 깨진 경우
파일시스템의 데이터를 스토리지에 쓰고 있는 도중 시스템 전원이 갑자기 끊어졌을 때와 같이 파일시스템 내용이 깨지는 경우가 있을 수 있습니다.

파일시스템이 깨지는 것을 막기 위한 기술로 저널링, Copy on Write 두 가지 방식이 널리 사용되고 있습니다. 저널링은 ext4와 XFS, Copy on Write는 Btrfs 방식에서 주로 사용합니다.

- 저널링
  - 파일시스템 업데이트에 필요한 처리목록을 일단 저널 영역에 작성합니다. 이를 저널 로그라고 부릅니다. 작성한 저널 영역에 내용을 바탕으로 실제 파일시스템의 내용을 업데이트합니다.

  - 만약 저널로그 업데이트중 강제로 전원을 끊게될 경우 단순히 저널 영역의 데이터를 지울 뿐, 실제 데이터는 처리하기 전과 같게됩니다.

  - 실제 데이터를 업데이트하는 중에 강제로 전원이 끊어진 경우, 저널로그를 처음부터 다시 수행하여 파일시스템의 처리를 완료합니다.

  두 가지 경우 중 어느 쪽이든 파일 시스템은 깨지지 않고, 처리 전이나 처리 후 상태가 됩니다.

- Copy on Write

  - Copy on Write 방식은 파일을 업데이트하기 전에 다른 장소에 작성을 모두 한 다음 링크를 바꾸는 방식으로 동작합니다.

  - 다른 파일시스템은 파일을 생성하면 해당 파일의 배치장소는 원칙적으로 변경되지 않으며, 같은 주소에 있는 파일을 계속 덮어쓰면서 업데이트가 이루어집니다.

  - 만약 업데이트 파일을 작성 중 시스템에 문제가 발생하면 작성하던 파일을 지우기만 하면 문제가 없이 작동하기 때문에 파일시스템이 깨지는 것을 방지할 수 있습니다.

# 파일시스템이 깨졌을 때 대책
저널링과 Copy on Write 방식을 통해 파일시스템이 깨지는 현상은 줄어들고 있으나, 파일시스템에 버그가 생기거나, 디스크에 손상이 발생하는 경우에는 어떠한 대책이 있을까요?

파일시스템을 주기적으로 백업하는 것이 대책이 될 수 있으나, 정기적으로 백업을 할 수 없는 경우에는 파일시스템에 준비된 복구용 명령어를 이용합니다.

어떤 파일시스템이더라도 공통적으로 존재하는 명령어가 있는데, `fsck` 입니다. (ext4 - `fsck.ext4`, XFS - `xfs_repair`, Btrfs - `btrfs check`) 해당 명령어를 사용하면 시스템을 깨지지 않은 상태로 고칠 수 있습니다. 하지만 다음의 단점을 가지고 있으니 유의하여 사용해야합니다.

+ 파일시스템 전체를 조사하기 때문에 파일시스템 규모에 따라 오랜 시간이 소요될 수 있습니다.

+ 해당 명령어를 사용하더라도 실패하는 경우가 많습니다.

+ **사용자가 원하는 상태로 복원된다고 보장할 수 없습니다.** `fsck` 명령어는 데이터가 깨진 파일 시스템을 무리해서라도 마운트하려는 명령어에 지나지않습니다. **처리하면서 깨진 데이터는 내용과 관계없이 삭제됩니다.**
