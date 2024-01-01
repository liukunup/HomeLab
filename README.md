# HomeLab 家庭实验室

TL;DR

🏡 【家庭】局域网可访问（无法访问就是暂时未部署）

[Jellyfin](https://jellyfin.homelab.com) 免费的多媒体管理软件

[Jupyter Notebook](https://notebook.homelab.com) 基于Web的交互式计算平台

[Visual Studio Code](https://vscode.homelab.com) 免费的开源代码编辑器

✈️ 【外部】公网可访问（服务已做内网穿透）


## 整体方案

### 集群

家庭里的服务器裸机通过 ***RKE*** 来构建成一个`Kubernetes`集群。

> RKE是一款经过CNCF认证、极致简单易用且闪电般快速的Kubernetes安装程序，完全在容器内运行，解决了容器最常见的安装复杂性问题。

使用 ***Rancher*** 可以非常轻松地管理安装在本地或远程开发环境中的`Kubernetes`集群。

### 网络

路由器建议选择千兆

### 存储

通过NFS连接存储来实现数据持久化，将会使用到K8S`nfs-subdir-external-provisioner`控制器。

推荐使用NAS作为集群的存储设备。

- （经济）**蜗牛星际** 4盘位 -> 安装黑群晖即可
- （推荐）**群晖 Synology**
  - DS220+ 2盘位
  - DS920+ 4盘位
- （可选）**威联通 QNAP**


## 机器资源规划

- C4M16
- C48M64G1

| Name     | Roles                      | Sub Domain          | IP Address     | Mac Address       | Device   |
|----------|----------------------------|---------------------|----------------|-------------------|----------|
| Master 1 | worker, etcd, controlplane | master1.homelab.com | 192.168.100.21 | 56:E6:2F:80:80:45 | C4M16    |
| Node 1   | worker, etcd               | node1.homelab.com   | 192.168.100.31 | E6:58:83:E7:33:98 | C4M16    |
| Node 2   | worker, etcd               | node2.homelab.com   | 192.168.100.32 | E2:58:EB:E7:F6:64 | C4M16    |
| Master 2 | worker, etcd, controlplane | master2.homelab.com | 192.168.100.22 | 46:8F:96:DB:F4:FA | C48M64G1 |
| Node 3   | worker, etcd               | node3.homelab.com   | 192.168.100.33 | DE:E4:AF:82:FD:AE | C48M64G1 |
| Node 4   | worker, etcd               | node4.homelab.com   | 192.168.100.34 | 06:A0:F4:94:E1:6D | C48M64G1 |

> 查看集群节点 `kubectl get nodes -o wide`

- 360家庭防火墙·路由器P2`自定义HOST`配置表

```text
192.168.100.21 master1.homelab.com
192.168.100.22 master2.homelab.com
192.168.100.31 node1.homelab.com
192.168.100.32 node2.homelab.com
192.168.100.33 node3.homelab.com
192.168.100.34 node4.homelab.com
```

## 清单
