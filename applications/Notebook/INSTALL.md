# Notebook

提供如下语言的`Notebook`部署方法

- Python
- C++
- SQL

## 安装部署

### Docker

```shell
bash deploy.sh
```

### Docker Compose

```shell
docker-compose up -d
```

### Kubernetes

1. 创建命名空间

```shell
# 如已创建, 请跳过
kubectl create namespace homelab
```

2. 部署或更新

```shell
kubectl apply -f k8s-notebook-python.yaml -n homelab
kubectl apply -f k8s-notebook-cpp.yaml -n homelab
kubectl apply -f k8s-notebook-sql.yaml -n homelab
```

3. 卸载

```shell
kubectl delete -f k8s-notebook-xxx.yaml -n homelab
```

## 体验使用

### 通过 `Docker` or `Docker Compose` 方式部署

请访问`http://{ip}:{port}/`

### 通过 `Kubernetes` 方式部署

- [Python](http://py.notebook.homelab.com/) py.notebook.homelab.com
- [C++](http://cpp.notebook.homelab.com/) cpp.notebook.homelab.com
- [SQL](http://sql.notebook.homelab.com/) sql.notebook.homelab.com
