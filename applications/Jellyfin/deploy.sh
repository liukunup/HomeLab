#! /bin/bash
# author : Liu Kun
# date   : 2022-11-20 21:30:00

docker run -d \
  --volume jellyfin-config:/config \
  --volume jellyfin-cache:/cache \
  --mount type=bind,source=/path/to/media1,target=/media1 \
  --mount type=bind,source=/path/to/media2,target=/media2,readonly \
  --name=jellyfin \
  --restart=always \
  --user=1000:1000 \
  --net=host \
  jellyfin/jellyfin
