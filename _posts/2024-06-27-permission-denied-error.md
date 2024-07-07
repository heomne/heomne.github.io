---
title: "hostnamectl, timedatectl 명령어 작동하지 않는 현상"
author: heomne
date: 2024-06-27
tags: linux troubleshoot
categories: Linux
pin: false
---
## ISSUE
`hostnamectl` `timedatectl` 명령어를 입력하면 아래와 같은 메시지가 나오면서 명령어 실행에 실패합니다.
```terminal
root@hello /root # hostnamectl
Failed to query system properties: The name org.freedesktop.hostname1 was not provided by any .service files
root@hello /root # timedatectl
Failed to query server: The name org.freedesktop.timedate1 was not provided by any .service files
```

해당 에러와 관련된 데몬을 찾던 중, `dbus-daemon`에서 아래와 같은 에러 메시지가 나오고 있습니다.

```terminal
root@hello /root # systemctl status dbus
● dbus.service - D-Bus System Message Bus
   Loaded: loaded (/usr/lib/systemd/system/dbus.service; static; vendor preset: disabled)
   Active: active (running) since Wed 2024-06-26 09:38:48 KST; 6h ago
     Docs: man:dbus-daemon(1)
 Main PID: 988 (dbus-daemon)
    Tasks: 1 (limit: 101147)
   Memory: 14.3M
   CGroup: /system.slice/dbus.service
           └─988 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only

Jun 26 09:38:48 hello dbus-daemon[988]: Cannot setup inotify for '/usr/share/dbus-1/system.d'; error 'Permission denied'
```

## Solution
최상위 디렉토리에서 디렉토리 권한이 올바르게 되어있는지 확인합니다.
`ls -rtl /`
```terminal
root@hello /root # ls -rtl /
total 14604
drwxr-xr-x.   2 root root       6 Apr 23  2020 srv
lrwxrwxrwx.   1 root root       8 Apr 23  2020 sbin -> usr/sbin
drwxr-xr-x.   2 root root       6 Apr 23  2020 opt
drwxr-xr-x.   2 root root       6 Apr 23  2020 mnt
drwxr-xr-x.   2 root root       6 Apr 23  2020 media
lrwxrwxrwx.   1 root root       9 Apr 23  2020 lib64 -> usr/lib64
lrwxrwxrwx.   1 root root       7 Apr 23  2020 lib -> usr/lib
lrwxrwxrwx.   1 root root       7 Apr 23  2020 bin -> usr/bin
drwxr-x---.  12 root root     144 Aug 24  2023 usr
dr-xr-xr-x.   5 root root    4096 Jun 25 14:56 boot
drwxr-xr-x.  22 root root    4096 Jun 25 14:59 var
drwxr-xr-x.   3 root root      17 Jun 25 15:13 home
dr-xr-xr-x  264 root root       0 Jun 26 09:37 proc
dr-xr-xr-x   13 root root       0 Jun 26 09:37 sys
drwxr-xr-x   19 root root    3060 Jun 26 09:38 dev
drwxr-xr-x   41 root root    1160 Jun 26 13:42 run
drwxr-x---. 163 root root   12288 Jun 26 16:28 etc
dr-xr-x---.   4 root root     221 Jun 27 11:07 root
drwxrwxrwt.  14 root root    4096 Jun 27 11:07 tmp
```
`/etc`와 `/usr` 디렉토리가 750 권한으로 설정되어있습니다. 이 경우 일반 유저가 해당 디렉토리에 엑세스할 수 없기 때문에 명령어 사용이나 데몬의 원할한 프로세스 작동에 문제가 생길 수 있습니다. 아래와 같이 디렉토리의 권한을 755로 변경해줍니다.

`chmod 755 /etc`
`chmod 755 /usr`

권한 변경 후 `hostnamectl` `timedatectl` 명령어가 올바르게 명령어가 작동하는지 확인합니다.

Permission denied가 출력되는 경우 데몬 자체 문제가 아니라 권한 설정에 오류가 있어서 생기는 에러이므로 최상위 디렉토리에 올바른 권한이 설정되어있는지 확인하는 작업이 필요합니다.