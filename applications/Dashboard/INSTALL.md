# Kubernetes Dashboard

[Kubernetes Dashboard](https://github.com/kubernetes/dashboard)

## 安装使用

- 一键部署

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

- 获取Token

```shell
kubectl describe $(kubectl get secret -n kube-system -o name | grep namespace) -n kube-system | grep token
```

- 创建安全的访问通道

```shell
kubectl proxy
```

- 浏览器打开以下链接

> http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
