---
title: "페이지 색인 생성 - 찾을 수 없음(404)으로 나오는 링크 리다이렉트 시키기"
author: heomne
date: 2024-08-21 +/-TTTT
tags: blog
categories: Blog
pin: false
---

최근에 [indexing API를 사용하여 자동 색인 요청](https://heomne.github.io/posts/automate-google-search-indexing) 스크립트를 만든 이후로 구글 서치 콘솔에 색인된 페이지가 늘어나게 되었습니다. 그러다가 한 가지 문제를 찾게 됐는데..

![not found link image - google search console](/assets/post_img/gitblog-redirect-post-url/image.webp)

크롤링 할 때 페이지 하나가 찾을 수 없음으로 나오는 것 같습니다. 자세히 들어가서 어떤 URL을 찾을 수 없다고 나오는지 찾아봅니다.

![not found link URL - google search console](/assets/post_img/gitblog-redirect-post-url/image-1.webp)

[https://heomne.github.io/posts/linux-메모리의-통계-정보/](#) 링크를 찾을 수 없다고 나오고 있습니다.

색인이 잘 되지 않는 것 같아 최근에 포스팅하는 글 링크를 전부 영어로 바꿨는데 이게 문제가 되는 것 같습니다. 해당 게시글은 현재 [https://heomne.github.io/posts/linux-memory-management/](https://heomne.github.io/posts/linux-memory-management/)로 링크가 변경된 상태입니다.

'posts/linux-메모리의-통계-정보/' 링크는 현재 구글 색인에 등록이 되어있어 검색이 가능한 것으로 보이니, 해당 링크로 접속할 경우 'posts/linux-memory-management/'링크로 리다이렉트할 수 있도록 조치가 필요해보입니다.

## 특정 URL로 리다이렉트 방법
이전에 사용한 포스트 링크를 변경한 링크로 리다이렉트 시키는 것이 목적으로, 정리하면 아래와 같습니다.

- 클라이언트가 [https://heomne.github.io/posts/linux-메모리의-통계-정보/](https://heomne.github.io/posts/linux-메모리의-통계-정보/) 링크 클릭
- 링크를 클릭하면 404 에러가 뜨지 않도록 [https://heomne.github.io/posts/linux-memory-management/](https://heomne.github.io/posts/linux-memory-management/) 주소로 리다이렉트

chirpy jekyll 테마를 사용중인 경우, 간단하게 파일 하나만 추가해주면 반영이 가능했습니다.

### 파일 생성

1. 깃헙 레포지토리에서 `assets/linux-메모리의-통계-정보.html` 파일을 생성합니다. 파일 이름은 가급적이면 링크 이름을 적어주는게 좋습니다.

2. 파일에 아래와 같이 작성합니다.
```html
---
layout: page
title: "Redirect..."
redirect_from: 
  - /posts/linux-메모리의-통계-정보/
redirect_to:
  - /posts/linux-memory-management/
---
```

`redirect_from` 링크로 접속했을 때 `redirect_to` 링크로 리다이렉트 한다고 생각하면서 링크를 작성합니다. 메인 도메인까지 작성할 필요없이 포스트가 작성된 경로까지만 작성해줍니다.

주의할 점은 맨 뒤에있는 슬래시 `/`가 있는지 없는지 확인해야합니다. 없을 경우 정상적으로 리다이렉트가 되지 않으니, 구글 서치 콘솔에 등록된 URL을 확인하여 정확하게 작성해줍니다.

### git config 설정

정상적으로 되나 싶었는데, `git commit` 명령어를 입력할 때 한글 파일이 깨지는 현상이 발생하여 아래 명령어를 입력한 다음 다시 커밋을 진행했습니다.

`git config core.quotepath false`

커밋 진행 후 [링크](https://heomne.github.io/posts/linux-%EB%A9%94%EB%AA%A8%EB%A6%AC%EC%9D%98-%ED%86%B5%EA%B3%84-%EC%A0%95%EB%B3%B4/) 클릭 시 정상적으로 리다이렉트 되는지 확인합니다.

리다이렉트가 정상적으로 되는 걸 확인했으니 구글 서치 콘솔에서 수정 결과 확인을 누르고 결과가 나오길 기다립니다.

![Confirm modification results - google search console](/assets/post_img/gitblog-redirect-post-url/image-2.webp)

워드프레스나 티스토리에서 블로그를 이전할 경우 위와 같은 방법을 사용하면 정상적으로 리다이렉트가 될 것 같긴합니다. 외부 링크를 입력했을 때도 정상적으로 작동이 되는지는 테스트가 필요할 것 같긴하네요.