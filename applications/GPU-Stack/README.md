# GPU Stack

- [官方网址](https://seal.io/)

## 快速安装

- Linux or Mac
  
```shell
curl -sfL https://get.gpustack.ai | sh -s -
```

- Windows

```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://get.gpustack.ai" -UseBasicParsing).Content
```

## 使用`Docker`安装

```shell
docker run -d --name gpustack \
    --restart=unless-stopped \
    --gpus all \
    --network=host \
    --ipc=host \
    -v /mnt/workspace/data/gpustack:/var/lib/gpustack \
    -e GPUSTACK_HF_TOKEN="token" \
    -e GPUSTACK_HF_ENDPOINT="https://hf-mirror.com" \
    gpustack/gpustack:v0.5.1
```
