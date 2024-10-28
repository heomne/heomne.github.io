---
title: "구글 서치 콘솔 색인 자동화 방법 (Indexing API)"
author: heomne
date: 2024-08-12 +/-TTTT
tags: blog linux
categories: Blog
pin: false
---

새로운 포스트를 작성할 때마다 구글 서치 콘솔에서 색인 요청을 해야하는데, 매우 번거로운 작업입니다. sitemap을 등록하면 자동으로 크롤링하여 색인을 진행한다고 하지만, 시간이 매우 오래걸리기 때문에 빠르면서 자동으로 색인을 요청하는 방법을 찾게 되었습니다.

## 준비물
구글에서는 Indexing API를 제공하는데, 사이트 소유자가 새로운 포스팅을 추가하거나 포스트를 삭제했을 때 크롤링이나 색인을 직접적으로 구글에 알릴 수 있게 할 수 있습니다. 이 글에서는 리눅스에 파이썬을 설치하고, Indexing API를 사용하여 하루에 한 번 구글에 웹페이지 크롤링/색인을 요청하는 스크립트를 작성합니다.

준비물은 아래와 같습니다.

- Linux
- 구글 서치 콘솔에 사이트가 등록되어있어야함
- 구글 서비스 계정(무료)

## 구글 콘솔에서 서비스 계정 생성
- 먼저 [구글 서비스 계정](https://console.cloud.google.com/iam-admin/serviceaccounts?hl=ko)을 생성해야합니다. 구글 서비스 계정 페이지로 이동한 후, 프로젝트 만들기를 클릭합니다.
![구글 서비스 계정 생성 이미지1](/assets/post_img/automate-google-search-indexing/image.webp)

- 원하는 프로젝트 이름을 입력한 후 [만들기]를 클릭합니다.
![구글 서비스 계정 생성 이미지2](/assets/post_img/automate-google-search-indexing/image-1.webp)

- 프로젝트가 선택된 상태에서 [+ 서비스 계정 만들기]를 클릭합니다.
![구글 서비스 계정 생성 이미지3](/assets/post_img/automate-google-search-indexing/image-2.webp)

- 서비스 계정 이름을 입력하고 하단에 [완료]를 클릭합니다. (선택사항은 건들 필요 없습니다.)
![구글 서비스 계정 생성 이미지4](/assets/post_img/automate-google-search-indexing/image-3.webp)

- 아래와 같이 서비스 계정이 생성되었습니다.
![구글 서비스 계정 생성 이미지5](/assets/post_img/automate-google-search-indexing/image-4.webp)

- 이제 키를 생성해주어야합니다. 우측에 작업에 있는 메뉴 버튼을 누르고, 키 관리를 클릭합니다.
![구글 서비스 계정 생성 이미지6](/assets/post_img/automate-google-search-indexing/image-5.webp)

- 키 추가를 클릭합니다. 새 키 만들기를 클릭합니다. 키 유형은 JSON으로 선택하여 만들기를 클릭하고, 생성된 키는 로컬에 파일로 저장해줍니다.
![구글 서비스 계정 생성 이미지7](/assets/post_img/automate-google-search-indexing/image-6.webp)
> 한번 키 파일이 생성되면 다시 다운로드 하기가 어려우니 잘 보관해야합니다.

- 이제 서비스 계정 생성이 완료되었습니다. 마지막으로 서비스 계정으로 indexing api를 사용할 수 있도록 설정해주어야합니다.
콘솔 검색창에서 indexing api를 검색하여 나오는 제일 첫 번째 항목을 클릭합니다.
![구글 서비스 계정 생성 이미지8](/assets/post_img/automate-google-search-indexing/image-7.webp)

- Web Search Indexing API 사용을 클릭합니다.
![구글 서비스 계정 생성 이미지9](/assets/post_img/automate-google-search-indexing/image-8.webp)

## 구글 서치 콘솔에 소유자 계정 추가
이제 생성한 서비스 계정을 구글 서치 콘솔에 소유자로 추가해주어야합니다. [구글 서치 콘솔](https://search.google.com/search-console/welcome?hl=ko)로 이동하여 속성 선택 후, [설정]에 [사용자 및 권한] 탭에 소유자 권한으로 서비스 계정을 추가해줍니다.
![구글 서치 콘솔 소유자 추가](/assets/post_img/automate-google-search-indexing/image-9.webp)


## 리눅스에 파이썬 설치
indexing api를 자동화 시키는 방법은 여러가지가 있지만, 이 글에서는 리눅스에 파이썬을 설치하여 crontab으로 하루에 한 번 색인 요청을 날리는 방식으로 구현해보도록 하겠습니다.

- 먼저 파이썬을 설치해줍니다. 아래 명령어로 설치합니다.
  - `yum install python3.12`
```terminal
[root@heomne bin]# python3.12
Python 3.12.1 (main, May  3 2024, 00:00:00) [GCC 11.4.1 20231218 (Red Hat 11.4.1-3)] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
```
- indexing api를 사용하기위해 관련된 모듈을 설치해주어야합니다. 아래 명령어를 입력합니다.
  - `pip3 install oauth2client`
  - `pip3 install virtualenv`
  - `pip3 install requests`

- 서비스 계정을 생성할 때 추가했던 JSON 파일 키를 리눅스 서버로 옮깁니다. 원하는 경로에 파일을 추가해줍니다. 저는 `/root/indexapi` 경로에 추가했습니다.

- `/root/indexing/indexing.py` 파일을 생성하고, 아래의 스크립트를 복사/붙여넣기합니다.

```python
#!/usr/bin/python3

import requests
import xml.etree.ElementTree as ET
from oauth2client.service_account import ServiceAccountCredentials
import httplib2

SCOPES = [ "https://www.googleapis.com/auth/indexing" ]
ENDPOINT = "https://indexing.googleapis.com/v3/urlNotifications:publish"

# service_account_file.json is the private key that you created for your service account.
JSON_KEY_FILE = "---.json"

credentials = ServiceAccountCredentials.from_json_keyfile_name(JSON_KEY_FILE, scopes=SCOPES)

http = credentials.authorize(httplib2.Http())

# sitemap URL set
sitemap_url = "https://heomne.github.io/sitemap.xml"

# import sitemap and parsing
sitemap_response = requests.get(sitemap_url)
sitemap_content = sitemap_response.content

# XML parsing
root = ET.fromstring(sitemap_content)

# namepsace set
namespace = {"ns": "http://www.sitemaps.org/schemas/sitemap/0.9"}

# export url on loc tag in url
urls = [loc.text for loc in root.findall(".//ns:loc", namespaces=namespace)]

# Define contents here as a JSON string.
# This example shows a simple update request.
# Other types of requests are described in the next step.

for url in urls:
    indexing_content = f"""\{\{
      "url": "\{url\}",
      "type": "URL_UPDATED"
    \}\}"""

    response, content = http.request(ENDPOINT, method="POST", body=indexing_content)

    print("content:", indexing_content)
    print("Response status:", response.status)
    print("Response content:", content.decode("utf-8"))
```

> 스크립트 기동 중에 문제가 발생하는 경우 `indexing_content`에 있는 역슬래시 `\`를 모두 제거해주세요. (markdown에서 빌드할 때 에러가 발생해서 부득이하게 추가했습니다.)

스크립트는 [구글 indexing api 가이드 페이지](https://developers.google.com/search/apis/indexing-api/v3/prereqs?hl=ko)에 작성된 예시 스크립트를 약간 수정한 스크립트입니다.
사이트맵에 작성된 URL을 크롤링한 후 추출하여 반복문으로 indexing api에 request를 날리는 방식으로 작성되어있습니다.

스크립트가 정상적으로 실행된다면 아래와 같이 200 Response 로그가 출력됩니다.
```terminal
content: {
      "url": "https://heomne.github.io/posts/toast_ui_2/",
      "type": "URL_UPDATED"
    }
Response status: 200
Response content: {
  "urlNotificationMetadata": {
    "url": "https://heomne.github.io/posts/toast_ui_2/",
    "latestUpdate": {
      "url": "https://heomne.github.io/posts/toast_ui_2/",
      "type": "URL_UPDATED",
      "notifyTime": "2024-08-12T05:01:12.270612940Z"
    }
  }
}
```

이제 스크립트를 crontab을 통해 새벽 2시마다 스크립트가 작동되도록 설정해줍니다. [이전에 작성한 crontab글을 참고](https://heomne.github.io/posts/github-push-commit-automate/)하여 원하는 시간대로 설정해주어도 상관없습니다.

- `crontab -e`

```terminal
30 23 * * * /home/user/heomne.github.io/tools/autopush.sh
00 2 * * * /root/indexapi/indexing.py >> /root/indexapi/indexing.log
```

파이썬 스크립트를 실행하면서 나오는 로그를 `indexing.log` 파일에 저장하도록 작성해주었습니다. 문제가 생겼을 경우 로그를 통해 어떤 부분에서 문제가 생겼는지 확인이 가능합니다.


## References
- [Indexing API 사용을 위한 기본 요건](https://developers.google.com/search/apis/indexing-api/v3/prereqs?hl=ko)
- [Indexing API 사용](https://developers.google.com/search/apis/indexing-api/v3/using-api?hl=ko)
