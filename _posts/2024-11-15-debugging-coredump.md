---
title: "[Linux] coredump 분석 환경 구성, 분석 방법"
author: heomne
date: 2024-11-15 +/-TTTT
tags: linux coredump
categories: Linux
pin: false
---

> RHEL 계열 리눅스를 기준으로 작성된 글입니다.

kdump 데몬을 활성화한 리눅스 서버는 커널 패닉과같은 OS에러가 발생 했을 때 자동으로 coredump를 생성하게됩니다. 생성된 coredump를 분석하려면 coredump 분석 툴과 분석에 필요한 debug 커널을 설치해야합니다.

## Crash Utility 설치
Crash Utility는 오픈소스 진영에서 사용되는 디버깅 툴로, coredump에 담긴 프로세스 정보를 확인할 수 있습니다. `crash` 패키지 설치로 사용이 가능합니다. OS에 설정된 기본 레포지토리에서 `crash` 패키지가  되어있습니다.

- 다음 명령어를 입력하여 `crash` 패키지를 설치합니다.
```terminal
yum install crash
```

- 설치 후 `crash` 명령어를 입력합니다. 아래와 같은 문구가 출력됩니다.  
  ```terminal
  crash 7.0.9-4.el7
  Copyright (C) 2002-2014  Red Hat, Inc.
  Copyright (C) 2004, 2005, 2006, 2010  IBM Corporation
  Copyright (C) 1999-2006  Hewlett-Packard Co
  Copyright (C) 2005, 2006, 2011, 2012  Fujitsu Limited
  Copyright (C) 2006, 2007  VA Linux Systems Japan K.K.
  Copyright (C) 2005, 2011  NEC Corporation
  Copyright (C) 1999, 2002, 2007  Silicon Graphics, Inc.
  Copyright (C) 1999, 2000, 2001, 2002  Mission Critical Linux, Inc.
  This program is free software, covered by the GNU General Public License,
  and you are welcome to change it and/or distribute copies of it under
  certain conditions.  Enter "help copying" to see the conditions.
  This program has absolutely no warranty.  Enter "help warranty" for details.  

  crash: cannot find booted kernel -- please enter namelist argument

  Usage:

  crash [OPTION]... NAMELIST MEMORY-IMAGE[@ADDRESS]     (dumpfile form)
  crash [OPTION]... [NAMELIST]                          (live system form)

  Enter "crash -h" for details.
  ```

## memory-image (vmlinux) 설치
`crash` 명령어를 사용하기 위해서는 coredump와 memory-image가 필요합니다. 일번적으로 memory-image로는 `vmlinux` 파일을 사용합니다.

> **vmlinux**  
  coredump는 OS 에러가 발생한 시점의 데이터 스냅샷이 담긴 파일입니다. coredump를 해석하기위해서는 커널 함수, 변수, 데이터 구조의 위치나 이름을 알아내기위한 심볼 정보가 필요한데, vmlinux는 분석에 필요한 심볼 정보를 제공하는 역할을 합니다. 이를 통해 coredump에 주소와 함수를 매핑하고 backtrace를 추적하여 트러블 슈팅을 할 수 있는데 도움을 줄 수 있습니다.
  {: .prompt-tip }

- vmlinux를 설치하기 전 생성된 coredump의 `os-release` 버전을 확인합니다. 예시로 출력된 내용은 아래와 같습니다.  
  `# crash --osrelease <coredump>`
  ```terminal
  [root@heomne ~]# crash --osrelease vmcore_241106
  3.10.0-1160.el7.x86_64
  ```

- `3.10.0-1160.el7.x86_64` 버전과 일치하는 `vmlinux` 파일을 설치합니다.  
  - `kernel-debuginfo` 패키지를 설치하여 `vmlinux` 파일을 얻을 수 있는데, RHEL 기준 `rhel-7-server-debug-rpms` 레포지토리를 통해 다운로드 받을 수 있습니다.  
  `# yum install kernel-debuginfo-3.10.0-1160.el7.x86_64`
  - 패키지 설치 후 `/usr/lib/debug/usr/lib/modules/3.10.0-1160.el7.x86_64/` 경로에 `vmlinux` 파일이 있는지 확인합니다.
  ```terminal
  [root@heomne ~]# ls -rtl /usr/lib/debug/usr/lib/modules/3.10.0-1160.el7.x86_64/
  total 452568
  -rwxr-xr-x  1 root root 463427736 Nov  6  2023 vmlinux
  drwxr-xr-x 12 root root       128 Nov  7 15:04 kernel
  drwxr-xr-x  2 root root       119 Nov  7 15:04 vdso
  ```

## coredump 분석 방법
모든 환경이 구성되었으면 `crash` 명령어를 실행하여 coredump를 분석할 수 있습니다.

`# crash /usr/lib/debug/usr/lib/modules/3.10.0-1160.el7.x86_64/vmlinux <coredump>`

```terminal
...

GNU gdb (GDB) 7.6
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-unknown-linux-gnu"...

WARNING: kernel relocated [154MB]: patching 87497 gdb minimal_symbol values

      KERNEL: /usr/lib/debug/lib/modules/3.10.0-1160.el7.x86_64/vmlinux
    DUMPFILE: xxxxxxxx_xxxxxx  [PARTIAL DUMP]
        CPUS: x
        DATE: xxx xxx  6 xx:xx:xx 20xx
      UPTIME: xxx days, xx:xx:xx
LOAD AVERAGE: x.xx, x.xx x.xx
       TASKS: xxx
    NODENAME: xxxxxxxxxx
     RELEASE: 3.10.0-1160.el7.x86_64
     VERSION: #x xxx xxx xxx x xx:xx:xx EST 20xx
     MACHINE: x86_64  (xxxx Mhz)
      MEMORY: xx GB
       PANIC: "Kernel panic - xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
         PID: x
     COMMAND: "xxxxxxx/xx"
        TASK: xxxxxxxxxxxxxxxxxxx (x of x)  [THREAD_INFO: xxxxxxxxxxxxxxxx]
         CPU: x
       STATE: xxxx_xxxxxxxxx (xxxxx)

crash>
```

coredump를 분석하기위해 주로 사용되는 명령어는 다음과 같습니다.

- 프로세스 확인은 주로 `ps` 명령어를 사용합니다.  
`man ps`를 통해 옵션을 확인하고 응용하면 패닉 상태에서 어떤 프로세스에 문제가 있었는지 확인할 수 있습니다.
  - `ps -m | grep UN` : Uninterruptbile 상태인 프로세스를 확인하며, 타임스탬프를 시/분/초로 표기합니다.
  - `ps -p | grep <pid>` : 특정 프로세스의 부모 프로세스를 확인할 수 있는 명령어입니다.

- TASK의 상태를 확인하려면 `struct` 명령어를 사용합니다.
  - `struct task_struct <task>`

- 특정 TASK의 backtrace를 확인하려면 `bt` 명령어를 사용합니다.
  - `bt <task>`

특정 프로세스의 상태, TASK, Backtrace를 통해 어떤 함수를 호출하고 종료되었는지 추적하여 어떤 프로세스에서 문제가 발생했는지 원인 파악을 할 수 있습니다.