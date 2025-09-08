# Docker Compose 项目模板

这是一个使用 Docker Compose 和环境变量配置的简单项目模板。

## 项目概述

简要描述您的项目功能和用途。

## 功能特性

- 使用 Docker Compose 进行容器编排
- 支持环境变量配置
- 包含 Web 服务和数据库服务
- 数据持久化配置
- 自动重启策略

## 快速开始

### 前置要求

- Docker
- Docker Compose

### 安装和运行

1. 克隆项目仓库：
```bash
git clone <repository-url>
cd <project-directory>
```

2. 配置环境变量：
```bash
cp .env.example .env
# 编辑 .env 文件，根据您的需求修改配置
```

3. 启动服务：
```bash
docker-compose up -d
```

4. 查看服务状态：
```bash
docker-compose ps
```

5. 查看日志：
```bash
docker-compose logs -f
```

## 环境配置

### .env 文件说明

项目使用 `.env` 文件管理环境变量，主要配置包括：

#### Web 服务配置
- `WEB_IMAGE`: Web 服务使用的镜像（默认: nginx:alpine）
- `WEB_CONTAINER_NAME`: Web 容器名称
- `HOST_PORT`: 主机端口（默认: 8080）
- `CONTAINER_PORT`: 容器端口（默认: 80）
- `APP_ENV`: 应用环境（默认: development）
- `HOST_VOLUME`: 主机挂载目录

#### 数据库配置
- `DB_IMAGE`: 数据库镜像（默认: postgres:13）
- `DB_CONTAINER_NAME`: 数据库容器名称
- `DB_USER`: 数据库用户名
- `DB_PASSWORD`: 数据库密码
- `DB_NAME`: 数据库名称
- `DB_HOST`: 数据库主机地址

#### 通用配置
- `RESTART_POLICY`: 容器重启策略（默认: unless-stopped）

### 多环境配置

支持不同环境配置文件：

```bash
# 使用生产环境配置
docker-compose --env-file .env.production up -d

# 使用开发环境配置
docker-compose --env-file .env.development up -d
```

## 服务说明

### Web 服务
- 服务名称: web
- 端口映射: ${HOST_PORT}:${CONTAINER_PORT}
- 环境变量: APP_ENV, DB_HOST
- 数据卷: ${HOST_VOLUME}:/app/data

### 数据库服务
- 服务名称: db
- 数据库: PostgreSQL
- 数据持久化: 使用命名卷 db_data
- 环境变量: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

## 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs [service]

# 执行命令
docker-compose exec [service] [command]

# 构建镜像（如果使用 build 选项）
docker-compose build

# 查看解析后的配置
docker-compose config
```

## 数据持久化

项目配置了数据持久化：
- 数据库数据存储在 `db_data` 卷中
- Web 应用数据挂载到主机目录 `${HOST_VOLUME}`

### 备份和恢复

```bash
# 备份数据库
docker-compose exec db pg_dump -U ${DB_USER} ${DB_NAME} > backup.sql

# 恢复数据库
cat backup.sql | docker-compose exec -T db psql -U ${DB_USER} -d ${DB_NAME}
```

## 故障排除

### 常见问题

1. **端口冲突**
   - 解决方案：修改 `.env` 文件中的 `HOST_PORT` 值

2. **权限问题**
   - 解决方案：确保挂载目录有适当权限

3. **环境变量未生效**
   - 解决方案：检查 `.env` 文件格式，确保没有空格 around `=`

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs web

# 实时日志监控
docker-compose logs -f
```

## 安全注意事项

1. 不要将 `.env` 文件提交到版本控制系统
2. 在生产环境中使用强密码
3. 定期更新基础镜像以获取安全补丁
4. 限制不必要的端口暴露

## 扩展和自定义

### 添加新服务

在 `docker-compose.yml` 中添加新服务定义：

```yaml
new-service:
  image: ${NEW_SERVICE_IMAGE}
  environment:
    - CONFIG_VALUE=${NEW_CONFIG}
  # 其他配置...
```

### 自定义网络

可以创建自定义网络以提高安全性：

```yaml
networks:
  app-network:
    driver: bridge

services:
  web:
    networks:
      - app-network
  db:
    networks:
      - app-network
```

## 许可证

[在此添加项目许可证信息]

## 贡献指南

[在此添加项目贡献指南]

## 更新日志

### [版本号] - 日期
- 功能更新或修复说明

---

如有问题，请提交 Issue 或联系维护团队。