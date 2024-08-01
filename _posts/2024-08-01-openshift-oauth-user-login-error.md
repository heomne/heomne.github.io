---
title: "[OpenShift] oc login internal error 500 해결 방법"
author: heomne
date: 2024-07-14 +/-TTTT
tags: openshift
categories: OpenShift
pin: false
---

## ISSUE

OpenShift에서 HTPasswd를 사용하여 유저를 생성했는데 `oc login` 명령어를 사용하면 아래와 같이 `unexpected response: 500` 에러가 발생하면서 로그인되지 않습니다.

```terminal
[root@bastion ~]# oc login -u admin -p admin
Error from server (InternalError): Internal error occurred: unexpected response: 500
```

`oc login -u admin -p admin --log-level=10` 명령어를 입력하여 출력되는 로그를 더 자세히 살펴봅니다. 아래와 같은 로그가 출력되고있습니다.

```terminal
...
I0801 16:05:07.214927  441187 request.go:1188] Response Body: {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"configmaps \"motd\" is forbidden: User \"system:anonymous\" cannot get resource \"configmaps\" in API group \"\" in the namespace \"openshift\"","reason":"Forbidden","details":{"name":"motd","kind":"configmaps"},"code":403}
I0801 16:05:07.215517  441187 helpers.go:246] server response object: [{
  "metadata": {},
  "status": "Failure",
  "message": "Internal error occurred: unexpected response: 500",
  "reason": "InternalError",
  "details": {
    "causes": [
      {
        "message": "unexpected response: 500"
      }
    ]
  },
  "code": 500
}]
Error from server (InternalError): Internal error occurred: unexpected response: 500
```

Response Body를 보면 `"status":"Failure"` 상태와 함께 `configmaps motd is forbidden: User "system:anonymous" cannot get resource "configmaps" in API group in the namespace openshift, "reason":"Forbidden"` 메시지가 출력되고 있습니다.


## Solution

OpenShift의 identity를 확인하여 해당되는 사용자를 삭제합니다.

- `oc get identities` 명령어를 입력하여 로그인하려고 했던 사용자가 있는지 확인합니다.
```terminal
[root@bastion ~]# oc get identities
NAME          IDP NAME   IDP USER NAME   USER NAME   USER UID
admin:admin   admin      admin           admin       f88af8db-f3d8-abcd-abcd-abcd123456789
```

- identity를 백업합니다. 다음 명령어를 입력합니다.
`oc describe identity admin:admin -o yaml > admin.yaml`

- identity는 사용자로 로그인할 때마다 자동으로 재동기화 됩니다. identity를 삭제한 다음, 다시 로그인을 시도해봅니다.
  - `oc delete identity admin:admin`
  - `oc login -u admin -p admin`

  ```terminal
  [root@bastion ~]# oc delete identity admin:admin
  identity.user.openshift.io "admin:admin" deleted

  [root@bastion ~]# oc login -u admin -p admin
  Login successful.

  You have access to 68 projects, the list has been suppressed. You can list all projects with 'oc projects'

  Using project "default".
  ```



## Reference

- [Single user from LDAP or OIDC cannot login with error "unexpected response: 500" in OCP](https://access.redhat.com/solutions/5525831)

