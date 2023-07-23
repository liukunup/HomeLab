# MinIO

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
    kubectl create namespace devops
    ```

    部署MinIO

    ```shell
    # Password
    kubectl apply -f password.yaml --namespace devops
    # MySQL
    helm install -f values.yaml minio bitnami/minio --namespace devops
    ```

- 更新配置

    ```shell
    helm upgrade -f values.yaml minio bitnami/minio --namespace devops
    ```

- 卸载应用

    ```shell
    helm uninstall minio --namespace devops
    ```

## 体验试用

- 配置`域名`到`IP`的解析映射(内容如下所示，注意换成自己的IP)
  - 配置到本地`hosts`文件
  - 安装`SwitchHosts!`软件进行配置和管理
  - 配置到路由`hosts`文件

```text
192.168.100.x minio.homelab.com
```

敬请体验 [minio.homelab.com](http://minio.homelab.com/)

## 参考资料

[MySQL](https://artifacthub.io/packages/helm/bitnami/mysql)

[phpMyAdmin](https://artifacthub.io/packages/helm/bitnami/phpmyadmin)

```text
NAME: minio
LAST DEPLOYED: Sun Jul 23 13:40:53 2023
NAMESPACE: devops
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: minio
CHART VERSION: 12.6.5
APP VERSION: 2023.6.19

** Please be patient while the chart is being deployed **

MinIO&reg; can be accessed via port  on the following DNS name from within your cluster:

   minio.devops.svc.cluster.local

To get your credentials run:

   export ROOT_USER=$(kubectl get secret --namespace devops minio -o jsonpath="{.data.root-user}" | base64 -d)
   export ROOT_PASSWORD=$(kubectl get secret --namespace devops minio -o jsonpath="{.data.root-password}" | base64 -d)

To connect to your MinIO&reg; server using a client:

- Run a MinIO&reg; Client pod and append the desired command (e.g. 'admin info'):

   kubectl run --namespace devops minio-client \
     --rm --tty -i --restart='Never' \
     --env MINIO_SERVER_ROOT_USER=$ROOT_USER \
     --env MINIO_SERVER_ROOT_PASSWORD=$ROOT_PASSWORD \
     --env MINIO_SERVER_HOST=minio \
     --image docker.io/bitnami/minio-client:2023.6.19-debian-11-r1 -- admin info minio

To access the MinIO&reg; web UI:

- Get the MinIO&reg; URL:

   You should be able to access your new MinIO&reg; web UI through

   http://minio.homelab.com/minio/
```