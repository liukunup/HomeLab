# Jupyter Notebook

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
