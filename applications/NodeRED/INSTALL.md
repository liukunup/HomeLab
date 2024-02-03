# NodeRED [官方文档](https://nodered.org/docs/)

## 安装部署

### Docker

[Running under Docker](https://nodered.org/docs/getting-started/docker)

```shell
sh deploy.sh
```

### Docker Compose

[Docker Stack / Docker Compose](https://nodered.org/docs/getting-started/docker)

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
kubectl apply -f nodered.yaml -n homelab
```
