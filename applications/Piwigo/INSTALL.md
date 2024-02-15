# Piwigo

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
kubectl create namespace piwigo
```

2. 部署或更新

```shell
#
kubectl apply -f mysql/password.yaml -n piwigo
#
helm install -f mysql/values.yaml mysql bitnami/mysql -n piwigo

#
kubectl apply -f piwigo.yaml -n piwigo
```
