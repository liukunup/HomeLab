# HomeLab 我的家庭实验室

你想过在家里搭建一个属于自己的实验室吗？独属于自己的小空间～

本仓库将记录我在搭建家庭实验室过程中一些经验和心得，供大家参考。

我的诉求:

1. 持续运营时节能（迷你服务器）
2. 强大的算力和存储（计算平台+NAS）
3. 灵活的资源管理能力（JumpServer+Kubernetes）
4. (可选)非必要服务随时可部署
5. (可选)对外提供简单的服务能力（花生壳+蒲公英）

## 整体方案

TL;DR

🏡 【家庭】局域网可访问（无法访问就是暂时未部署）

[Jellyfin](https://jellyfin.homelab.com) 免费的多媒体管理软件

[Jupyter Notebook](https://notebook.homelab.com) 基于Web的交互式计算平台

[Visual Studio Code](https://vscode.homelab.com) 免费的开源代码编辑器

✈️ 【外部】公网可访问（服务已做内网穿透）

### 集群

家庭里的服务器裸机通过 ***RKE2*** 来构建成一个`Kubernetes`集群。

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
