# Kube Prometheus Stack [GitHub](https://github.com/prometheus-operator/kube-prometheus)

[ArtifactHub](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)

## 安装部署

### Kubernetes

```shell
# 创建命名空间
kubectl create ns monitoring

# 添加仓库并更新
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 安装
helm install -f values.yaml kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring

# 更新
helm upgrade -f values.yaml kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring

# 卸载
helm uninstall kube-prometheus-stack -n monitoring

# 查看
kubectl -n monitoring get pods -l "release=kube-prometheus-stack"
kubectl get all -n monitoring
```

## 体验

- [Grafana](http://grafana.homelab.com/)

默认账号密码如下:

```text
username: admin
password: prom-operator
```

- [AlertManager](http://alertmanager.homelab.com/)
