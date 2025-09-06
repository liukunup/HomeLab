# iVentoy

容器部署 + iKuai

## 安装步骤

1. 到[iVentoy官网](https://www.iventoy.com/cn/download.html)下载`iventoy-<version>-linux-free.tar.gz`，并解压

2. 部署容器

> 记得提前准备镜像放到`iso`目录下哦

将`data`目录下的数据进行拷贝，否则会启动失败

当然，也建议拷贝`user`目录下的脚本

```shell
docker compose up -d
```

3. 设置路由器 DHCP 服务端

http://<路由器IP>/#/network-setting/dhcp-server

配置如下

Next Server: <部署iVentoy容器的宿主机IP地址>

option67: iventoy_loader_16000 字符串

> 记得保存

4. 设置 iVentoy

参数配置

- DHCP 服务器模式：External
- EFI 启动文件：ipex.efi

启动信息

点击按钮启动服务器

5. 测试一下

PVE创建空的虚拟机(即不使用系统镜像)，然后将`网络启动`选项移动到最前面，开机等待加载即可
