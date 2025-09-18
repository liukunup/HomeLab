# [Harbor](https://goharbor.io/)

## 安装步骤

### 前置准备

#### PostgreSQL

> 使用内置`PostgreSQL`可以跳过此步骤

#### Redis

> 使用内置`Redis`可以跳过此步骤

#### MinIO

> 使用文件存储可以跳过此步骤

#### 证书文件

> 不使用`HTTPs`可以跳过此步骤

- 根证书 + 中间证书(可选)
- 服务端证书
- 服务端密钥

### Docker Compose

1. 下载安装包

选择需要的安装包版本，中国大陆地区下载建议使用代理加速。

```shell
export VERSION="v2.14.0"
export GITHUB_PROXY="https://gh-proxy.com/"
wget "${GITHUB_PROXY}https://github.com/goharbor/harbor/releases/download/${VERSION}/harbor-offline-installer-${VERSION}.tgz"
```

2. 解压&配置

- 解压

```shell
tar xzvf harbor-offline-installer-${VERSION}.tgz
```

- 配置

```shell
sudo ./prepare
```

3. 部署

```shell
sudo ./install.sh --with-trivy
```

### Helm

## 配置与使用

### 测试一下

> 使用 Docker 客户端测试镜像的拉取和推送

1. 准备好证书文件

- 根证书 + 中间证书(可选)
- 服务端证书
- 服务端密钥

```plaintext
/etc/docker/certs.d/
    └── yourdomain.com:port
       ├── yourdomain.com.cert  <-- Server certificate signed by CA
       ├── yourdomain.com.key   <-- Server key signed by CA
       └── ca.crt               <-- Certificate authority that signed the registry certificate
```

2. 登录认证

```shell
docker login -u <username> https://reg.homelab.lan
# 接着按提示输入密码，即可看到登录成功
```

3. 推拉镜像

```shell
docker pull hello-world
docker tag  hello-world:latest reg.homelab.lan/hello-world:latest
docker push reg.homelab.lan/hello-world:latest
```

### 反向代理

> 为什么需要配置反向代理？如果不使用反向代理，Harbor通常会占用掉80和443端口，这样你就需要一台额外的主机，否则最后使用时镜像前缀会变成`<host>:<port>/library/nginx:latest`这样的形式。

> 调整`client_max_body_size`限制，解决大文件推拉受限的问题

### 外部认证源

- 支持在命令行中通过`cURL`请求进行配置的读写

> https://goharbor.io/docs/2.13.0/install-config/configure-system-settings-cli/

```shell
# 读取
curl -u "<username>:<password>" -H "Content-Type: application/json" -ki <Harbor Server URL>/api/v2.0/configurations
# 写入
curl -X PUT -u "<username>:<password>" -H "Content-Type: application/json" -ki <Harbor Server URL>/api/v2.0/configurations -d'{"<item_name>":"<item_value>"}'
# 样例
curl -X PUT -u "<username>:<password>" -H "Content-Type: application/json" -ki https://harbor.sample.domain/api/v2.0/configurations -d'{"auth_mode":"ldap_auth"}'
```

#### LDAP

前置条件：已经安装了LDAP提供服务，这里以`Authentik`为例。

#### OIDC

前置条件: 已经安装了OIDC提供服务，这里以`Authentik`为例。

> [Integrate with Harbor](https://integrations.goauthentik.io/infrastructure/harbor/)

前提假设:

- `reg.homelab.lan`       → 你的 Harbor 访问域名（如：`harbor.example.com`）
- `authentik.homelab.lan` → 你的 authentik 访问域名（如：`sso.example.com`）

---

##### 第一步：在`authentik`中创建应用和`OIDC`提供者

    1. 登录 authentik 管理后台。
    2. 进入 **Applications > Applications**，点击 **“Create with Provider”**。
    3. 填写以下内容：

        - **Application Name**：自定义名称（如 “Harbor SSO”）
        - **Provider Type**：选择 **OAuth2/OpenID Connect**
        - **Provider 配置**：
            - **Redirect URI**（必须严格匹配）：
            ```
            https://reg.homelab.lan/c/oidc/callback/
            ```
            - **Signing Key**：任选一个可用密钥
            - **Scopes**：勾选 `openid`, `profile`, `email`, `offline_access`
            - **Username Claim**：填写 `preferred_username`（重要！）

    4. 点击 **Submit** 保存。

    ✅ 记下生成的 **Client ID** 和 **Client Secret**，下一步要用！

---

##### 第二步：在 Harbor 中配置 OIDC 认证

    1. 以管理员身份登录 Harbor 控制台。
    2. 进入 **Configuration > Authentication**。
    3. 设置如下参数：

        - **Auth Mode**：选择 `OIDC`
        - **OIDC Provider Name**：`authentik`（可自定义）
        - **OIDC Endpoint**：
            ```
            https://authentik.homelab.lan/application/o/harbor/
            ```
        - **OIDC Client ID**：填入上一步 authentik 生成的 Client ID
        - **OIDC Client Secret**：填入上一步 authentik 生成的 Client Secret
        - **OIDC Scope**：`openid,profile,email,offline_access`
        - **Username Claim**：`preferred_username`

    4. 点击 **Save** 保存配置。

    > ⚠️ **注意**：如果遇到重定向错误，请检查 Harbor 的 `harbor.yml` 配置文件：
    > - 确保 `hostname` 和 `external_url` 设置正确
    > - 保存后重新运行 `./prepare` 和 `docker-compose up -d`

---

##### 第三步：验证登录

    1. 退出 Harbor 当前登录状态。
    2. 在登录页面点击 **“LOGIN VIA OIDC PROVIDER”**。
    3. 应跳转到 authentik 登录页，登录成功后自动返回 Harbor。

---

## 💡 小贴士

- 用户名映射必须使用 `preferred_username`，否则登录后可能无法识别用户。
- 确保 Harbor 与 authentik 的域名可互相访问，且 HTTPS 证书有效。
- 如需精细权限控制，可在 authentik 中为该应用绑定策略或用户组。

### 镜像仓库

> 通过在局域网内部署镜像仓库，实现对`docker.io`这类公网仓库进行缓冲，二次拉取时下载速度能大大提高。

> 结合镜像代理域名，解决GFW限制
