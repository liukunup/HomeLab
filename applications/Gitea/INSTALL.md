# Gitea

版本控制系统`Gitea`部署指引

## 安装步骤

前置条件:

1. 确保已存在默认的存储类；
2. 确保已配置Ingress控制器；
3. 确保已创建待用的数据库；

- 添加仓库

    ```shell
    helm repo add bitnami https://charts.bitnami.com/bitnami
    ```

- 部署应用

    如果不存在命名空间则需先创建

    ```shell
    kubectl create namespace homelab
    ```

    部署Gitea

    ```shell
    helm install -f k8s/values.yaml gitea bitnami/gitea --namespace homelab
    ```

- 更新配置

    ```shell
    helm upgrade -f k8s/values.yaml gitea bitnami/gitea --namespace homelab
    ```

- 卸载应用

    ```shell
    helm uninstall gitea --namespace homelab
    ```

## 体验试用

- 配置`域名`到`IP`的解析映射(内容如下所示，注意换成自己的IP)
  - 配置到本地`hosts`文件
  - 安装`SwitchHosts!`软件进行配置和管理
  - 配置到路由`hosts`文件

```text
192.168.100.x gitea.homelab.com
```

敬请体验 [gitea.homelab.com](http://gitea.homelab.com/)

## 参考资料

[Gitea](https://artifacthub.io/packages/helm/bitnami/gitea)
