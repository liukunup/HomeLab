#! /bin/bash
# author : Liu Kun
# date   : 2024-02-03 20:24:00

docker run -d \
  -p 3000:3000 \
  -v grafana:/var/lib/grafana \
  --name=grafana \
  grafana/grafana:latest
