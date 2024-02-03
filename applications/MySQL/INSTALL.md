# MySQL + phpMyAdmin

关系型数据库`MySQL` + 数据库管理系统`phpMyAdmin` 联合部署指引

## 安装步骤

前置条件:

1. 确保已存在默认的存储类；

2. 确保已配置Ingress控制器；

- 添加仓库

    ```shell
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    ```

- 部署应用

    如果不存在命名空间则需先创建

    ```shell
    kubectl create namespace homelab
    ```

    依次部署MySQL、phpMyAdmin

    ```shell
    # Password
    kubectl apply -f mysql/password.yaml -n homelab
    # MySQL
    helm install -f mysql/values.yaml mysql bitnami/mysql -n homelab
    # phpMyAdmin
    helm install -f phpmyadmin/values.yaml phpmyadmin bitnami/phpmyadmin -n homelab
    ```

- 更新配置

    ```shell
    # MySQL
    helm upgrade -f mysql/values.yaml mysql bitnami/mysql --namespace homelab
    # phpMyAdmin
    helm upgrade -f phpmyadmin/values.yaml phpmyadmin bitnami/phpmyadmin -n homelab
    ```

- 卸载应用

    ```shell
    # phpMyAdmin
    helm uninstall phpmyadmin -n homelab
    # MySQL
    helm uninstall mysql -n homelab
    ```

## 体验试用

- 配置`域名`到`IP`的解析映射(内容如下所示，注意换成自己的IP)
  - 配置到本地`hosts`文件
  - 安装`SwitchHosts!`软件进行配置和管理
  - 配置到路由`hosts`文件

```text
192.168.100.x phpmyadmin.homelab.com
```

敬请体验 [phpmyadmin.homelab.com](http://phpmyadmin.homelab.com/)

## 参考资料

[MySQL](https://artifacthub.io/packages/helm/bitnami/mysql)

[phpMyAdmin](https://artifacthub.io/packages/helm/bitnami/phpmyadmin)
