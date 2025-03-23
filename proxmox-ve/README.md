# Proxmox VE 如何快速创建并配置虚拟机

## 使用说明

准备工作:
1. 搭建 Proxmox VE 环境
2. 准备好 user-data.yaml 配置文件（以供Cloud-Init使用）
    a. 准备好 openssl passwd -6 密码
    b. 准备好 ssh 公钥

```bash
curl -fsSL https://get.homelab.lan/vm/create | sh
```

在虚拟机中

```bash
cloud-init status
```
## 参考链接
https://cloudinit.readthedocs.io/en/latest/howto/debugging.html
