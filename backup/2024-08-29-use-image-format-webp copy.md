---
title: "블로그 이미지를 webp 포맷으로 변환 후 성능 테스트해보기"
author: heomne
date: 2024-08-29 +/-TTTT
tags: blog
categories: Blog
pin: false
---

블로그 포스팅할 때 화면 캡처를 하게되면 png 형식의 이미지 파일을 사용하게됩니다. 작성한 포스트를 lighthouse로 속도측정을 할 경우 아래와 같은 항목이 출력됩니다.

![need to reduce image capacity](/assets/post_img/image-to-webp/image.webp)

이미지가 많이 들어갈수록 웹페이지 로딩 속도는 느려질 수 밖에 없는데, 이를 개선하기 위해 구글에서는 webp 형식의 이미지를 사용할 것을 권장하고 있습니다.

## webp 이미지
webp 이미지는 구글에서 무료로 공개하는 이미지 포맷으로, 웹사이트에서 효율적으로 사용이 가능합니다. 구글은 자사 서비스를 운영하면서 발생하는 트래픽 처리에 필요한 비용을 효율적으로 줄이기 위해 이미지 포맷을 무료로 개방했다고 알려져있습니다.

gif, png, jpeg 형식의 이미지를 호환하는 것이 특징이며, 포맷을 webp로 변환할 경우 약 30%의 용량을 줄일 수 있는 것으로 설명하고 있습니다. 용량이 줄어들면 웹페이지 로딩 속도도 자연스럽게 빨라집니다.

현 시점 webp 이미지는 대부분의 브라우저에서 지원하고있고, 이미지 트래픽 처리가 중요한 웹사이트 대부분에서 webp를 지원하기 때문에 호환성 문제도 크지 않아 webp를 사용하지 않을 이유가 없는 상황입니다.

## cwebp 설치 - Linux
먼저 webp 이미지 포맷으로 변환하기위해서는 구글에서 배포하는 cwebp라는 패키지 설치가 필요합니다. 이 글에서는 Linux 기준으로 cwebp 사용방법을 설명합니다.

- [cwebp 다운로드 링크](https://developers.google.com/speed/webp/download?hl=ko)로 이동하여 사용중인 OS에 맞는 cwebp 패키지를 다운로드합니다. (이 글에서는 [Linux_x86_64](https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.4.0-linux-x86-64.tar.gz) 버전을 다운로드합니다.)
  ![cwebp download page](/assets/post_img/image-to-webp/image-1.webp)

- 다운받은 `libwebp-1.4.0-linux-x86-64.tar.gz` 파일을 압축해제합니다.

  - `tar -xvf libwebp-1.4.0-linux-x86-64.tar.gz`

- 압축이 해제되면 `libwebp-1.4.0-linux-x86-64` 디렉토리가 생성됩니다. 디렉토리 내부에는 실행바이너리 파일, 문서, API 라이브러리 등의 파일이 있습니다. 여기에서 `bin/cwebp` 파일을 `/usr/local/bin` 폴더로 복사/붙여넣기합니다.

  - `cp libwebp-1.4.0-linux-x86-64/bin/cwebp /usr/local/bin`

- `cwebp` 명령어 입력 후 Usage 텍스트가 출력되는지 확인합니다.

  ```terminal
  [root@heomne ~]# cwebp
  Usage:

    cwebp [options] -q quality input.png -o output.webp

  where quality is between 0 (poor) to 100 (very good).
  Typical value is around 80.

  Try -longhelp for an exhaustive list of advanced options.
  ```

## 이미지 변환하기

- `cwebp` 명령어는 `cwebp -q <quality> /path/to/image.png -o /path/to/output.webp` 방식으로 사용합니다.
  - `-q` 옵션은 변환되는 이미지의 품질을 의미합니다. 80으로 설정하는게 가장 효율적입니다.
  - `/path/to/image.png`는 변환해야하는 이미지경로를 입력합니다.
  - `-o /path/to/output.webp`는 변환한 이미지를 어디에 저장할지 입력하는 옵션으로, 경로와 이미지 이름을 같이 적어줍니다. webp 이미지로 변환되므로 확장자명은 webp로 고정해줍니다.

- 변환하려는 이미지 경로를 확인 후 명령어를 입력합니다. 아래 명령어를 참조합니다.
  - `IMG_PATH=/home/user/heomne.github.io/assets/post_img`
  - `cwebp -q 80 $IMG_PATH/image-to-webp/image-1.png -o $IMG_PATH/image-to-webp/image-1.webp`
  - 명령어를 입력하게되면 아래와 같이 이미지 변환 결과 텍스트가 출력됩니다.
  
  ```terminal
  Saving file '/home/user/heomne.github.io/assets/post_img/image-to-webp/image-1.webp'
  File:      /home/user/heomne.github.io/assets/post_img/image-to-webp/image-1.webp
  Dimension: 1256 x 527 (with alpha)
  Output:    44998 bytes Y-U-V-All-PSNR 45.60 44.13 44.43   45.11 dB
            (0.54 bpp)
  block count:  intra4:        736  (28.23%)
                intra16:      1871  (71.77%)
                skipped:      1830  (70.20%)
  bytes used:  header:            465  (1.0%)
              mode-partition:   3967  (8.8%)
              transparency:      181 (99.0 dB)
  Residuals bytes  |segment 1|segment 2|segment 3|segment 4|  total
      macroblocks:  |       5%|       8%|      17%|      70%|    2607
        quantizer:  |      27 |      26 |      22 |      17 |
    filter level:  |       8 |       5 |       4 |       2 |
  Lossless-alpha compressed size: 180 bytes
    * Header size: 43 bytes, image data size: 137
    * Lossless features used: PALETTE
    * Precision Bits: histogram=5 transform=5 cache=0
    * Palette size:   7
  ```

- 변환된 이미지를 확인합니다. 이미지를 두 개 변환해봤는데, 각각 30%, 50% 가까이 용량이 줄은 것을 확인할 수 있습니다.

  ```terminal
  -rw-r--r--. 1 root root 29K Aug 29 15:15 image.png
  -rw-r--r--. 1 root root 87K Aug 29 15:29 image-1.png
  -rw-r--r--. 1 root root 20K Aug 29 15:51 image.webp
  -rw-r--r--. 1 root root 44K Aug 29 15:52 image-1.webp
  ```

## 로딩속도 차이 확인하기

이제 png 이미지를 썼을 때, webp 이미지를 썼을 때 로딩속도 차이가 있는지 비교해봅니다. lighthouse를 통해 웹페이지 성능 비교로 확인해봅니다.

- png 이미지 사용

  ![png lighthouse test](/assets/post_img/image-to-webp/use-png.webp)

- webp 이미지 사용

  ![webp lighthouse test](/assets/post_img/image-to-webp/use-webp.webp)


webp 이미지를 사용했을 때 10% 정도 성능이 향상되는 결과가 나옵니다. 

큰 차이가 없어보이지만 블로그 품질에 따라 구글 검색 순위에 영향을 미칠 수 있고, 웹사이트 성능도 품질에 영향을 미치니 앞으로 블로그 작성 시 이미지는 가능하면 webp 이미지로 변환하여 사용하는 걸로..
