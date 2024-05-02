#! /bin/bash
# author : Liu Kun
# date   : 2024-04-30 11:58:00

# https://github.com/1Panel-dev/MaxKB
# 用户名: admin
# 密码: MaxKB@123..
docker run -d \
  --publish 8080:8080 \
  --volume maxkb:/var/lib/postgresql/data \
  --name=maxkb \
  1panel/maxkb

# https://github.com/ollama/ollama
# docker exec -it ollama ollama run llama2
docker run -d \
  --publish 11434:11434 \
  --volume ollama:/root/.ollama \
  --name=ollama \
  ollama/ollama
