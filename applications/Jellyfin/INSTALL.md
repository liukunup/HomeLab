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

## HTTPS支持

1. 生成pfx证书

如果设置了密码，在使用的时候也需要提供!

```shell
openssl pkcs12 -export -out jellyfin.homelab.lan.pfx -inkey jellyfin.homelab.lan.key -in jellyfin.homelab.lan.crt -passout pass:<changeit>
```

2. 启动容器时将证书映射进去

/share/Container/jellyfin/certs:/certs:ro

3. 在配置里使用证书并开启https
