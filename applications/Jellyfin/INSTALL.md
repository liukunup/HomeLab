# Jellyfin

## 安装部署

### Docker

```shell
sh deploy.sh
```

### Docker Compose

```shell
docker-compose up -d
```

### Kubernetes

1. 创建命名空间

```shell
kubectl create namespace homelab
```

2. 部署或更新

```shell
kubectl apply -f k8s -n homelab
```

## 中文支持镜像

- 构建

```shell
docker build -t liukunup/jellyfin:10.10.3 .
```

- 推送

```shell
docker push liukunup/jellyfin:10.10.3
```
