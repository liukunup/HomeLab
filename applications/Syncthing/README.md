# Syncthing

## 如何部署

1. 在宿主机上运行 id $USER 查看你的 UID 和 GID。

```shell
id $USER
```

2. 在 docker-compose.yml 中设置 PUID 和 PGID。

3. 部署

```shell
# 拉取最新的镜像
docker-compose pull

# 重新创建并启动容器
docker-compose -f docker-compose.yaml -p syncthing-infra up -d

# 停止服务
docker-compose down
```

## 如何配置

初始设置：

首次访问 Web GUI（http://ip:8384）时，它会提示你设置用户名和密码。强烈建议设置，否则你的同步服务将对网络上任何人开放。

进入 设置 -> GUI 即可进行认证配置。

添加同步文件夹：

默认已经有一个名为 Sync 的文件夹，它对应你挂载的 /path/to/your/data 目录。

如果你想添加新的同步文件夹，必须先通过 Docker 的 volumes 参数将宿主机的目录挂载到容器内的某个路径，然后再到 Web GUI 中添加这个容器内的路径作为新的同步文件夹。

防火墙：确保你的服务器防火墙（如 ufw）放行了上述端口（8384, 22000, 21027）。
