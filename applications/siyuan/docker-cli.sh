#! /bin/bash
# author : Liu Kun
# date   : 2025-08-23

docker run -d \
  -v /share/Container/siyuan/workspace:/siyuan/workspace \
  -p 6806:6806 \
  --restart=unless-stopped \
  --name=siyuan \
  b3log/siyuan:latest \
  --workspace=/siyuan/workspace/ \
  --accessAuthCode="your_access_auth_code"
