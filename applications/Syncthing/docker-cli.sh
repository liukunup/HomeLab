#! /bin/bash
# author : Liu Kun
# date   : 2025-08-23

docker run -d \
  --name=syncthing \
  -p 8384:8384 \
  -p 22000:22000/tcp \
  -p 22000:22000/udp \
  -p 21027:21027/udp \
  -v /path/to/your/appdata/config:/var/syncthing \
  -v /path/to/your/data:/var/syncthing/Sync \
  --restart unless-stopped \
  syncthing/syncthing:latest
