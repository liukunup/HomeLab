#! /bin/bash
# author : Liu Kun
# date   : 2025-05-04 18:12:00

docker run -d \
    -p 9000:9000 \
    -p 9001:9001 \
    -v /share/Container/minio/data:/mnt/data \
    -v /share/Container/minio/certs:/opt/minio/certs \
    -v /share/Container/minio/config.env:/etc/config.env \
    -e MINIO_CONFIG_ENV_FILE=/etc/config.env \
    --restart=unless-stopped \
    --name=minio \
    minio/minio:RELEASE.2025-04-08T15-41-24Z \
    server \
    --address=":9000" \
    --console-address=":9001" \
    --ftp="address=:8021" \
    --ftp="passive-port-range=30000-40000" \
    --certs-dir="/opt/minio/certs"
