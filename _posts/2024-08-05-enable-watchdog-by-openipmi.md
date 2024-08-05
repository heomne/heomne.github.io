---
title: "[Linux] Watchdog 활성화 방법 (feat.OpenIpmI)"
author: heomne
date: 2024-08-05 +/-TTTT
tags: linux
categories: Linux
pin: false
---

SBD STONITH를 사용하는 Pacemaker 클러스터 구축을 위해서는 각 노드에 Watchdog 활성화가 필요합니다. 

## Watchdog
Watchdog은 시스템의 동작을 모니터링하고, 시스템이 응답하지 않거나 정지한 경우에 자동으로 재부팅을 트리거하며, 시스템의 가용성과 안정성을 높이는 하드웨어, 소프트웨어 모니터링 매커니즘입니다. 서버의 고가용성 구축에 반드시 필요한 요소이며, 하드웨어를 감시하면서 응답이 없는 경우 해당 서버의 재부팅을 트리거하는데 중요한 역할을 담당합니다.

## Watchdog 지원여부 확인
Watchdog은 하드웨어를 감시하는 툴이기때문에 베어메탈 환경에서 사용되는게 일반적이며, 베어메탈 환경에 IPMI(Intelligent Paltform Management Interface)가 설치되어있다면 손쉽게 활성화할 수 있습니다. 아래 명령어를 입력하여 서버에서 IPMI를 지원하는지 확인해볼 수 있습니다.

- `deidecode | grep -A 10 IPMI`

> IPMI는
  서버를 포함한 컴퓨터를 관리하고 모니터링 할 수 있는 기능을 제공하는 표준 플랫폼을 말합니다. 제조사에 상관없이 하드웨어가 IPMI를 지원하는 경우 동일한 방식의 관리와 모니터링을 할 수 있습니다. 

> IPMI가 설치되어있으면 서버의 CPU, FAN, 파워, 메모리, 온도 등 센서 정보를 모니터링 할 수 있으며, syslog와 연계하여 이벤트가 발생된 로그를 확인할 수 있습니다. IPMI의 중요한 기능 중에 하나로 원격으로 서버 기동 및 콘솔화면 출력 기능을 사용할 수도 있습니다.

## 활성화 방법

### 커널 파라미터 활성화

먼저 NMI Watchdog 커널 파라미터를 활성화합니다. 파라미터 이름은 `kernel.nmi_watchdog`입니다.

NMI Watchdog은 리눅스 커널에서 제공하는 Non-Maskable Interrupt Watchdog 기능으로, 시스템이 응답하지 않을 때 비마스크 인터럽트를 발생시켜 커널 덤프를 생성하거나 시스템 재부팅을 트리거할 수 있도록하여 시스템 모니터링에 유용한 기능을 제공합니다.

- `vi /etc/sysctl.conf`

  ```bash
  # sysctl settings are defined through files in
  # /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
  #
  # Vendors settings live in /usr/lib/sysctl.d/.
  # To override a whole file, create a new file with the same in
  # /etc/sysctl.d/ and put new settings there. To override
  # only specific settings, add a file with a lexically later
  # name in /etc/sysctl.d/ and put new settings there.
  #
  # For more information, see sysctl.conf(5) and sysctl.d(5).
  #

  kernel.nmi_watchdog = 1
  ```
파일 저장 후, 커널 파라미터를 적용합니다.
- `sysctl -p`

### OpenIpmI 패키지 설치 및 구성

`openipmi` 패키지를 설치합니다.
- `yum install openipmi ipmitool`

현재 설정되어있는 Watchdog이 있는지 확인합니다.
- `lsmod | grep iTCO`
```terminal
iTCO_wdt 13480 0
iTCO_vendor_support 1378 1 iTCO_wdt
```

`iTCO_wdt` `iTCO_vendor_support` 모듈은 UCS 및 HPE SDFlex 시스템에서 지원되지 않는 모듈이기 때문에 사용하지 않도록 설정해줍니다.
- `modprobe -r iTCO_wdt iTCO_vendor_support`

모듈을 비활성화했지만 시스템을 재부팅할 경우 다시 모듈이 활성화될 수 있으니 블랙리스트에 모듈을 추가해줍니다.
- `vi /etc/modprobe.d/50-blacklist.conf`
```bash
blacklist iTCO_wdt
blacklist iTCO_vendor_support
```

`ipmitool` 명령어를 사용하여 watchdog 정보를 확인해봅니다.
- `ipmitool mc watchdog get`
```terminal
Watchdog Timer Use: BIOS FRB2 (0x01)
Watchdog Timer Is: Stopped
Watchdog Timer Actions: No action (0x00)
Pre-timeout interval: 0 seconds
Timer Expiration Flags: 0x00
Initial Countdown: 0 sec
Present Countdown: 0 sec
```
Watchdog을 구성하지않았고 사용중이지 않기 때문에 `Watchdog Timer Is`는 `Stopped`로 출력되고 있습니다.

### IPMI Watchdog 구성
`/etc/sysconfig/ipmi` 파일에서 watchdog을 사용하도록 파일을 구성해봅니다.
- `mv /etc/sysconfig/ipmi /etc/sysconfig/ipmi.org`
- `vi /etc/sysconfig/ipmi`
```bash
IPMI_SI=yes
DEV_IPMI=yes
IPMI_WATCHDOG=yes
IPMI_WATCHDOG_OPTIONS="timeout=20 action=reset nowayout=0 panic_wdt_timeout=15"
IPMI_POWEROFF=no
IPMI_POWERCYCLE=no
IPMI_IMB=no
```

파일 저장 후, `ipmi` 데몬을 시작합니다.
- `systemctl enable --now ipmi`
- `systemctl status ipmi`

Watchdog이 생성되었는지 확인합니다.
- `ls -rtl /dev/watchdog*`
```terminal
ls: cannot access /dev/watchdog: No such file or directory
```

생성이 되지 않았다고 출력되는 경우 `watchdog` 패키지를 설치한 다음 다시 확인해봅니다.
- `yum install watchdog`
- `systemctl enable --now watchdog`
- `ls -rtl /dev/watchdog*`
```terminal
crw-------. 1 root root 10, 130 Jan  8 10:28 /dev/watchdog
```

이제 Watchdog이 활성화 되었으니, Pacemaker에 SBD를 구성하여 활성화 할 수 있습니다. SBD를 활성화한 다음 SBD STONITH를 구축하여 스토리지 펜싱을 구성할 수 있습니다.

## Reference
- [RHEL의 SAP를 위한 Azure 대규모 인스턴스 고가용성](https://learn.microsoft.com/ko-kr/azure/sap/large-instances/large-instance-high-availability-rhel)
- [Administrative Procedures for RHEL High Availability Clusters - Validating a Watchdog Timer Device (WDT) to Use with sbd](https://access.redhat.com/articles/2941231)
- [Design Guidance for RHEL High Availability Clusters - sbd Considerations](https://access.redhat.com/articles/2941601)