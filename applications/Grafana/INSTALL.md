# Grafana [官方文档](https://grafana.com/docs/grafana/latest/)

## 安装部署

### Docker

[Run Grafana via Docker CLI](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/#run-grafana-via-docker-cli)

```shell
sh deploy.sh
```

### Docker Compose

[Run Grafana via Docker Compose](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/#run-grafana-via-docker-compose)

```shell
docker-compose up -d
```

### Kubernetes

[Deploy Grafana on Kubernetes](https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/)

1. 创建命名空间

```shell
kubectl create namespace homelab
```

2. 部署或更新

```shell
kubectl apply -f grafana.yaml -n homelab
```
