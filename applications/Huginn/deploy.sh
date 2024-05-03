#! /bin/bash
# author : Liu Kun
# date   : 2024-05-03 16:00:00

# see https://github.com/huginn/huginn.git
docker run -d \
  --publish 3000:3000 \
  --name=huginn \
  ghcr.io/huginn/huginn
