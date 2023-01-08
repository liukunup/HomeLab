# MySQL

[phpMyAdmin](https://artifacthub.io/packages/helm/bitnami/phpmyadmin)

## 安装步骤

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install -f values.yaml mysql bitnami/mysql --namespace homelab

helm upgrade -f values.yaml mysql bitnami/mysql --namespace homelab

helm uninstall mysql --namespace homelab
```

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install -f values.yaml phpmyadmin bitnami/phpmyadmin --namespace homelab

helm upgrade -f values.yaml phpmyadmin bitnami/phpmyadmin --namespace homelab

helm uninstall phpmyadmin --namespace homelab
```
