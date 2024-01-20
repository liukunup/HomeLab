# Kubernetes Dashboard

[Kubernetes Dashboard in GitHub](https://github.com/kubernetes/dashboard)

[Kubernetes Dashboard in ArtifactHub](https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard)

## 安装使用

- 一键部署

```shell
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
```

```shell
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```

```log
Release "kubernetes-dashboard" does not exist. Installing it now.
NAME: kubernetes-dashboard
LAST DEPLOYED: Sat Jan 20 23:32:29 2024
NAMESPACE: kubernetes-dashboard
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
*********************************************************************************
*** PLEASE BE PATIENT: kubernetes-dashboard may take a few minutes to install ***
*********************************************************************************

Get the Kubernetes Dashboard URL by running:
  export POD_NAME=$(kubectl get pods -n kubernetes-dashboard -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
  echo https://127.0.0.1:8443/
  kubectl -n kubernetes-dashboard port-forward $POD_NAME 8443:8443
```

- 获得 Bearer Token

```shell
kubectl create -f admin-user.yaml
```

```shell
kubectl -n kubernetes-dashboard create token admin-user
```

- 创建安全的访问通道

```shell
kubectl -n kubernetes-dashboard port-forward $POD_NAME 8443:8443
```

- 浏览器打开以下链接

> https://127.0.0.1:8443/
