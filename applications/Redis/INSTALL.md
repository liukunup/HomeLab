# Redis Cluster

KV数据库`Redis`集群部署指引

## 安装步骤

前置条件:
1. 确保已存在默认的存储类；
2. 确保已配置Ingress控制器；

- 添加仓库

    ```shell
    helm repo add bitnami https://charts.bitnami.com/bitnami
    ```

- 部署应用

    如果不存在命名空间则需先创建

    ```shell
    kubectl create namespace homelab
    ```

    部署Redis

    ```shell
    helm install -f k8s/values.yaml redis-cluster bitnami/redis-cluster --namespace homelab
    ```

- 更新配置

    ```shell
    helm upgrade -f k8s/values.yaml redis-cluster bitnami/redis-cluster --namespace homelab
    ```

- 卸载应用

    ```shell
    helm uninstall redis-cluster --namespace homelab
    ```

## 体验试用

不涉及

## 参考资料

[Redis Cluster](https://artifacthub.io/packages/helm/bitnami/redis-cluster)
