#! /bin/bash
# author : Liu Kun
# date   : 2022-11-20 22:00:00

docker run -d \
  -p 8444:8443 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -e HASHED_PASSWORD='$argon2i$v=19$m=4096,t=3,p=1$kWrzf2c0IKyk8t/LwhEyJg$Ps0yVV637Oy9fv0RxBxhIwhbGweQYNDjOMdy69MGyW4' \
  -e SUDO_PASSWORD_HASH='$argon2i$v=19$m=4096,t=3,p=1$kWrzf2c0IKyk8t/LwhEyJg$Ps0yVV637Oy9fv0RxBxhIwhbGweQYNDjOMdy69MGyW4' \
  -e PROXY_DOMAIN=prod.liukun.com \
  -e DEFAULT_WORKSPACE=/config/workspace \
  -v code-server-config:/config \
  --restart=unless-stopped \
  --name=code-server \
  lscr.io/linuxserver/code-server:latest
