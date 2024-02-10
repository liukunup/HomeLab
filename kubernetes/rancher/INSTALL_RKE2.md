# 基于Rancher搭建Kubernetes集群 (RKE2)

RKE2，也称为 RKE Government，是 Rancher 的下一代 Kubernetes 发行版。

## 搭建步骤 [官方安装手册](https://docs.rke2.io/zh/)

> 请先完成[机器准备](VMs.md)工作

### Server节点

1. 安装服务

```shell
# 切换到Root
su -
# 执行安装命令(使用国内镜像)
curl -sfL https://rancher-mirror.rancher.cn/rke2/install.sh | INSTALL_RKE2_MIRROR=cn sh -
# 使能 Server 服务
systemctl enable rke2-server.service
# 启动 Server 服务
systemctl start rke2-server.service
# (可选) 查看 Server 日志
journalctl -u rke2-server -f
```

2. 查看凭证

> 注意保存到本地，以供后续访问集群使用

```shell
cat /etc/rancher/rke2/rke2.yaml
```

3. 查看令牌

```shell
cat /var/lib/rancher/rke2/server/node-token
```

准备好节点接入的配置文件

```yaml
server: https://<server>:9345
token: <token from server node>
```

### Worker节点

```shell
# 切换到Root
su -
# 执行安装命令(使用国内镜像)
curl -sfL https://rancher-mirror.rancher.cn/rke2/install.sh | INSTALL_RKE2_MIRROR=cn INSTALL_RKE2_TYPE="agent" sh -
# 使能 Agent 服务
systemctl enable rke2-agent.service

# 写入上述 Server 的配置信息
mkdir -p /etc/rancher/rke2
vim /etc/rancher/rke2/config.yaml

# 使能 Agent 服务
systemctl start rke2-agent.service
# (可选) 查看 Agent 日志
journalctl -u rke2-agent -f
```

## 其他后续工作

- 修改节点角色名称

```shell
# 将节点 nodeX 标记为 worker 角色
kubectl label nodes nodeX node-role.kubernetes.io/worker=
```

- 安装组件/插件 👉 [安装手册](COMPONENT.md)

- 修改`Nginx Ingress`参数

修改代理上传的大小限制

```shell
# 切换到root
su -
# 准备写入新的配置来覆盖
vim /var/lib/rancher/rke2/server/manifests/rke2-ingress-nginx-config.yaml
```

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      config:
        proxy-body-size: "1024m"
```
