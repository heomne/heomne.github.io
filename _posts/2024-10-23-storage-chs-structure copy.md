---
title: "[Linux] 스토리지 용량이 동일한데 fdisk에서 End값이 다른 이유"
author: heomne
date: 2024-10-23 +/-TTTT
tags: linux storage
categories: Linux
pin: false
---

## ISSUE

고객사에서 기존에 200G의 스토리지를 확장하여 사용중이었으나, 신규 증설을 위해 200G 디스크를 하나 더 확장하기로 결정했습니다.

스토리지를 확장한 후 기존 스토리지와 신규 스토리지를 `fdisk` 명령어로 확인해보니 Start와 End 값이 다르게 출력됩니다.

```terminal

# 기존 스토리지
Disk /dev/sdb: 214.7 GB, 214749020160 bytes
106 heads, 45 sectors/track, 87931 cylinders
Units = cylinders of 4770 * 512 = 2442240 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x*******

Device Boot        Start   End    Blocks Id System
/dev/sdb1              1 87932 209714816 83  Linux     # <----- End 87932

--------------------------------------------------------------

# 신규 스토리지
Disk /dev/sdc: 214.7 GB, 214749020160 bytes
255 heads, 63 sectors/track, 26108 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes

Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0xc*******

Device Boot        Start   End     Blocks Id System
/dev/sdc1              1 26108 209712478+ 83  Linux    # <----- End 26108

```

## Solution?

결론부터 말하자면 두 스토리지는 모두 정상이며, 전체 스토리지 용량을 사용중인 상태입니다.

기존 스토리지인 `/dev/sdb1`와 End값이 달라서 신규 스토리지`/dev/sdc1`에 이상이 있는 것처럼 보이지만, 디스크의 CHS구조가 다르기 때문에 `End`값이 다르게 출력되는 것을 볼 수 있습니다.

### CHS구조

CHS 구조는 하드 디스크의 물리적인 구조를 헤더(Headers), 섹터(Sectors), 실린더(Cylinders)로 나누어 구분하는 방식을 말합니다. 하드웨어 제조사에서 하드 디스크 구조를 어떻게 설계하느냐에 따라 CHS 값이 결정됩니다.  
(개념이 복잡해 내용이 길어질 수 있어 이 글에서는 생략합니다.)

같은 디스크 용량이더라도 CHS의 물리적인 배치에 따라 `fdisk` 명령어를 입력했을 때 `Start`와 `End`값이 달라질 수 있습니다.

`fdisk`에서 파티션의 `Start`와 `End`값은 하드 디스크의 Cylinder 번호로 출력되며, 파티션을 나누지 않고 스토리지 전체를 사용하는 경우 `Start` 값은 1, Cylinder 값은 마지막 번호가 출력되어야 합니다.

> `End`값이 실린더 번호와 동일하지 않은 경우 LBA방식으로 데이터를 처리하는 디스크로, 정확히 맞지 않더라도 디스크의 모든 공간을 사용한다고 볼 수 있습니다.  
> 최근에 사용되는 디스크는 대부분 LBA 방식으로 데이터를 처리합니다.

하드 디스크를 사용하는 경우 `fdisk` 명령으로 CHS값을 확인할 수 있으므로 Cylinder값과 `End`값이 일치하는지 확인하여 문제가 없는지 살펴봅니다.

```terminal
# 기존 스토리지
106 heads, 45 sectors/track, 87931 cylinders

Device Boot        Start   End    Blocks Id System
/dev/sdb1              1 87932 209714816 83  Linux

# -----> 87931 cylinders, 87932 End

--------------------------------------------------------------

# 신규 스토리지
255 heads, 63 sectors/track, 26108 cylinders

Device Boot        Start   End     Blocks Id System
/dev/sdc1              1 26108 209712478+ 83  Linux

# -----> 26108 cylinders, 26108 End
```

신규 스토리지의 실린더 값과 `End`값이 일치하므로 스토리지는 정상이라고 볼 수 있습니다.

## Reference
- [Cylinder-head-sector](https://en.wikipedia.org/wiki/Cylinder-head-sector)