# Syncthing

# 拉取最新的镜像
docker-compose pull
# 重新创建并启动容器
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 清理旧的镜像
docker image prune


# 停止并删除旧容器
docker stop syncthing
docker rm syncthing
# 然后重新运行本文开头的 `docker run ...` 命令，它会自动拉取最新镜像。



重要提示和配置步骤
权限问题：如果遇到文件权限错误（例如，容器内进程没有权限写入挂载的目录），请确保目录对于 Docker 容器是可写的。使用 PUID 和 PGID 环境变量是一种好习惯，它们让容器以指定的非 root 用户运行，与你宿主机上的用户权限匹配。

在宿主机上运行 id $USER 查看你的 UID 和 GID。

在 docker-compose.yml 中设置 PUID 和 PGID。

初始设置：

首次访问 Web GUI（http://ip:8384）时，它会提示你设置用户名和密码。强烈建议设置，否则你的同步服务将对网络上任何人开放。

进入 设置 -> GUI 即可进行认证配置。

添加同步文件夹：

默认已经有一个名为 Sync 的文件夹，它对应你挂载的 /path/to/your/data 目录。

如果你想添加新的同步文件夹，必须先通过 Docker 的 volumes 参数将宿主机的目录挂载到容器内的某个路径，然后再到 Web GUI 中添加这个容器内的路径作为新的同步文件夹。

防火墙：确保你的服务器防火墙（如 ufw）放行了上述端口（8384, 22000, 21027）。
