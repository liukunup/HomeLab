#! /bin/bash
# author : Liu Kun
# date   : 2024-02-03 21:17:00

docker run -d \
  -p 1880:1880 \
  -e TZ=Asia/Shanghai
  -e LANG=en_US.UTF-8
  -v nodered:/data \
  --name=nodered \
  nodered/node-red:latest
