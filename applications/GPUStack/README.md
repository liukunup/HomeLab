# GPU Stack

![https://seal.io/](https://gpustack.ai/wp-content/uploads/2024/01/GPUStack-logo.png)

## 快速安装

- Linux or Mac
  
```shell
curl -sfL https://get.gpustack.ai | sh -s -
```

如何获取密码?

```shell
cat /var/lib/gpustack/initial_admin_password
```

- Windows

```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://get.gpustack.ai" -UseBasicParsing).Content
```

如何获取密码?

```powershell
Get-Content -Path "$env:APPDATA\gpustack\initial_admin_password" -Raw
```

- Docker

> 记得替换成自己的`HF_TOKEN`

```shell
docker run -d \
  -e GPUSTACK_HF_TOKEN="<token>" \
  -e GPUSTACK_HF_ENDPOINT="https://hf-mirror.com" \
  -v /mnt/workspace/data/gpustack:/var/lib/gpustack \
  --gpus all \
  --network=host \
  --ipc=host \
  --restart=unless-stopped \
  --name=gpustack \
  gpustack/gpustack:v0.5.1
```

如何获取密码?

```shell
docker exec -it gpustack cat /var/lib/gpustack/initial_admin_password
```

## 其他配套

- DCGM Exporter 显卡监控

```shell
docker run -d \
  -p 9400:9400 \
  --gpus all \
  --cap-add SYS_ADMIN \
  --restart=unless-stopped \
  --name=dcgm-exporter \
  nvcr.io/nvidia/k8s/dcgm-exporter:4.2.0-4.1.0-ubuntu22.04
```

- Node Exporter 主机监控

```shell
docker run -d \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  --restart=unless-stopped \
  --name=node-exporter \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host
```

- cAdvisor 容器监控

```shell
docker run -d \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  --restart=unless-stopped \
  gcr.io/cadvisor/cadvisor:latest
```
