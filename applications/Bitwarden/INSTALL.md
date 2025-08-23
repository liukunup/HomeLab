好的，部署 Bitwarden 用于生产环境是一个非常重要的任务，因为涉及到密码管理，安全性和稳定性是首要考虑因素。我将为您提供一个基于 Docker 和 Docker Compose 的、适合生产环境的详细部署指南。

### 核心建议：使用 Vaultwarden (原 bitwarden_rs)

官方 Bitwarden 服务器组件较多，资源消耗较大。社区有一个非常出色的替代项目 **Vaultwarden** (曾用名 bitwarden_rs)，它使用 Rust 编写，实现了绝大部分 Bitwarden API，但资源占用极低（仅需 ~10MB 内存），非常适合个人、团队甚至小规模企业使用。

**Vaultwarden 的优势：**
*   **轻量高效**：极低的内存和 CPU 占用。
*   **完全兼容**：与官方 Bitwarden 客户端（浏览器插件、桌面端、移动App）完美兼容。
*   **功能丰富**：支持所有核心功能，包括附件、密码库备份与恢复、双因素认证 (2FA)、紧急访问等。
*   **易于部署**：单个 Docker 镜像即可包含所有功能。

---

### 生产环境部署步骤 (使用 Docker Compose)

以下步骤假设您已经有一台安装了 **Docker** 和 **Docker Compose** 的服务器。

#### 第 1 步：创建项目目录结构

在服务器上创建一个独立的目录来存放所有相关文件，这有助于管理和维护。

```bash
mkdir -p /opt/vaultwarden/{data,logs,ssl}
cd /opt/vaultwarden
```
*   `data`: 用于持久化数据库和密码库数据。
*   `logs`: (可选) 用于存放日志。
*   `ssl`: **用于存放 SSL/TLS 证书和私钥（生产环境必需）**。

#### 第 2 步：获取 SSL 证书

生产环境**必须**使用 HTTPS 来加密所有通信。您可以从以下途径获取免费证书：
*   **Let's Encrypt**: 使用 `certbot` 工具申请。
*   **云服务商**：如果您用的云服务器（如阿里云、腾讯云、AWS等），它们通常提供免费的 SSL 证书。

将获取到的证书文件（例如：`fullchain.pem`）和私钥文件（例如：`privkey.pem`）放入刚才创建的 `ssl` 目录中。

**重要**：确保证书文件权限安全，私钥应设为仅 root 可读。
```bash
sudo chmod 600 /opt/vaultwarden/ssl/privkey.pem
```

#### 第 3 步：创建 Docker Compose 文件

创建 `docker-compose.yml` 文件，这是部署的核心配置文件。

```yaml
version: '3.8'

services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: always
    ports:
      - "443:443" # 映射 HTTPS 端口
    environment:
      # 管理员令牌：用于访问 /admin 管理后台，请务必修改成一个非常复杂的长随机字符串
      # 生成命令：openssl rand -base64 48
      ADMIN_TOKEN: "your_super_long_random_and_secure_admin_token_here"
      # 数据库连接：使用 SQLite 简单高效，对于大多数用户足够
      DATABASE_URL: "/data/db.sqlite3"
      # 网站域名：必须设置为您的域名，否则注册等功能会出错
      DOMAIN: "https://vault.your-domain.com"
      # 启用注册（可选）：生产环境建议关闭，手动邀请用户或通过管理后台添加
      SIGNUPS_ALLOWED: "false"
      # 邀请码（可选）：如果 SIGNUPS_ALLOWED 为 true，强烈建议启用
      # INVITATIONS_ALLOWED: "true"
      # 其他配置：如邮件服务器设置（用于通知、2FA等）
      # SMTP_HOST: "smtp.gmail.com"
      # SMTP_FROM: "your-email@gmail.com"
      # SMTP_PORT: 587
      # SMTP_SSL: "true"
      # SMTP_USERNAME: "your-email@gmail.com"
      # SMTP_PASSWORD: "your-app-password" # 注意使用应用专用密码，非邮箱登录密码
    volumes:
      - ./data:/data # 持久化数据
      - ./logs:/logs # (可选) 持久化日志
      - ./ssl:/ssl/:ro # 挂载 SSL 证书目录，只读
    # 使用自定义网络（可选，但更佳）
    networks:
      - vaultwarden-net

# 定义网络（可选）
networks:
  vaultwarden-net:
    driver: bridge
```

#### 第 4 步：创建环境变量文件 (可选但推荐)

为了不将敏感信息（如 `ADMIN_TOKEN`, `SMTP_PASSWORD`）明文写在 `docker-compose.yml` 中，可以创建一个 `.env` 文件。

1.  创建 `.env` 文件：
    ```bash
    touch .env
    chmod 600 .env # 设置权限，仅当前用户可读
    ```
2.  在 `.env` 文件中定义变量：
    ```ini
    ADMIN_TOKEN=your_super_long_random_and_secure_admin_token_here
    SMTP_PASSWORD=your_app_specific_password
    ```
3.  修改 `docker-compose.yml`，引用环境变量文件：
    ```yaml
    env_file:
      - .env
    ```
    并将 `environment` 部分中的对应值改为变量名：
    ```yaml
    environment:
      ADMIN_TOKEN: ${ADMIN_TOKEN}
      # ... 其他配置
      SMTP_PASSWORD: ${SMTP_PASSWORD}
    ```

#### 第 5 步：启动 Vaultwarden 服务

在 `docker-compose.yml` 所在目录执行以下命令：

```bash
# 拉取镜像并启动服务（ detached 模式，后台运行）
docker compose up -d

# 查看日志，确认没有报错
docker compose logs -f
```

#### 第 6 步：配置反向代理 (推荐做法)

虽然上述配置直接将容器的 443 端口映射到了主机，但在生产环境中，更佳实践是使用一个专门的反向代理（如 **Nginx** 或 **Caddy**）来处理 TLS 终止、访问日志、缓存、安全头等任务。

**使用 Nginx 的示例配置 (`/etc/nginx/conf.d/vaultwarden.conf`):**

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name vault.your-domain.com;

    # 指定 SSL 证书路径
    ssl_certificate /opt/vaultwarden/ssl/fullchain.pem;
    ssl_certificate_key /opt/vaultwarden/ssl/privkey.pem;

    # 安全强化：SSL 配置（可使用 Mozilla SSL 配置生成器生成）
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    client_max_body_size 128M; # 允许上传较大附件

    location / {
        proxy_pass http://localhost:8080; # 假设Vaultwarden运行在8080端口
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTP 强制跳转到 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name vault.your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

如果使用 Nginx，需要：
1.  修改 `docker-compose.yml`，将端口映射改为 `- "8080:80"`（Vaultwarden 容器内部的 HTTP 端口是 80）。
2.  重新部署：`docker compose down && docker compose up -d`。
3.  重载 Nginx 配置：`nginx -s reload`。

#### 第 7 步：初始设置和备份

1.  **访问管理后台**：在浏览器中打开 `https://vault.your-domain.com/admin`，输入您在 `ADMIN_TOKEN` 中设置的令牌。在这里您可以查看统计数据、管理用户、设置系统等。
2.  **创建第一个用户**：由于关闭了公开注册（`SIGNUPS_ALLOWED=false`），您需要在管理后台的 **Users** 选项卡中**邀请**或直接**创建**您的第一个用户账户。
3.  **配置备份策略**：
    *   定期备份 `/opt/vaultwarden/data` 整个目录。这是最重要的，包含了整个密码库。
    *   可以考虑使用 `rsync`, `rclone` 等工具将备份同步到另一个安全的位置。
    *   **注意**：备份时最好停止服务 (`docker compose down`)，以确保数据库文件的完整性，或者确认 Vaultwarden 使用的是 SQLite3，可以直接拷贝。

---

### 重要安全注意事项

1.  **强密码和 2FA**：为您自己的 Vaultwarden 主账户设置一个极其强大的主密码，并务必启用双因素认证 (2FA)。
2.  **保持更新**：定期检查并更新 Vaultwarden 的 Docker 镜像至最新版本，以获取安全补丁。
    ```bash
    docker compose pull
    docker compose up -d
    docker image prune # 清理旧的镜像
    ```
3.  **防火墙**：确保服务器的防火墙只开放必要的端口（如 80, 443）。
4.  **仅限 HTTPS**：确保所有 HTTP 流量都重定向到 HTTPS。
5.  **保护 `.env` 和 `ssl` 目录**：确保这些包含敏感信息的文件权限设置正确，避免未经授权的访问。

按照这个指南，您就可以拥有一个安全、稳定、高效的自托管 Bitwarden (Vaultwarden) 生产环境了。