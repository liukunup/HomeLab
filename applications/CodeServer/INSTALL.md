# CodeServer

## 安装部署

怎么创建一个Hash密码

```shell
echo -n "hard-to-guess" | npx argon2-cli -e
$argon2i$v=19$m=4096,t=3,p=1$kWrzf2c0IKyk8t/LwhEyJg$Ps0yVV637Oy9fv0RxBxhIwhbGweQYNDjOMdy69MGyW4
```

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
