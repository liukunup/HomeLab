# Xinference

![https://inference.readthedocs.io/zh-cn/latest/index.html](https://xorbits.cn/assets/images/xinference.jpg)

## 部署指导

- Docker

> 记得替换成自己的`HF_TOKEN`

```shell
docker run -d \
  -p 9997:9997 \
  -e HF_ENDPOINT=https://hf-mirror.com \
  -e HF_TOKEN=<token> \
  -v /mnt/workspace/data/xprobe/.xinference:/root/.xinference \
  -v /mnt/workspace/data/xprobe/.cache/huggingface:/root/.cache/huggingface \
  -v /mnt/workspace/data/xprobe/.cache/modelscope:/root/.cache/modelscope \
  --gpus all \
  --restart=unless-stopped \
  --name=xinference \
  docker.io/xprobe/xinference:v1.5.0 \
  xinference-local --host 0.0.0.0
```

## 使用[HF-Mirror](https://hf-mirror.com/)下载

1. 安装工具

```shell
sudo apt install -y aria2 jq
```

2. 下载hfd

```shell
wget https://hf-mirror.com/hfd/hfd.sh
chmod a+x hfd.sh
```

3. 设置环境变量

- Linux

```shell
export HF_ENDPOINT=https://hf-mirror.com
```

- Windows

```powershell
$env:HF_ENDPOINT = "https://hf-mirror.com"
```

4.1 下载模型

```shell
./hfd.sh gpt2
```

4.2 下载数据集

```shell
./hfd.sh wikitext --dataset
```
