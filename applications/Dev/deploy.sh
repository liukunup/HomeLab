#!/bin/bash

# Exit on error, undefined variable, or error in pipeline
set -euo pipefail

# ----- Configuration -----
PROJECT_DIR="awesome-dev-stack"

# ----- Constants -----
DOWNLOAD_URL_PREFIX="https://raw.githubusercontent.com/liukunup/HomeLab/refs/heads/main/applications/Dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ----- Functions -----
check_dependencies() {
    local dependencies=("sed" "openssl" "curl" "docker")

    for cmd in "${dependencies[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo -e "${RED}Error: please install ${cmd} first.${NC}"
            exit 1
        fi
    done
}

get_host_ip() {
    if command -v ip > /dev/null 2>&1; then
        ip route get 1 | awk '{print $7;exit}' 2>/dev/null || echo "127.0.0.1"
    elif command -v ifconfig > /dev/null 2>&1; then
        ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1
    else
        echo "127.0.0.1"
    fi
}

# Enhanced password generator
# usage       : generate_random_password [length] [char_types] [custom_chars]
# length      : password length (default: 16)
# types       : l (lowercase), u (uppercase), d (digits), s (special)
# custom_chars: if provided, use this set of characters instead of predefined sets
generate_random_password() {
    local length=${1:-16}
    local char_types=${2:-"lud"}  # 默认包含小写、大写、数字
    local custom_chars=${3:-""}

    # 定义字符集
    local lowercase="abcdefghijklmnopqrstuvwxyz"
    local uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local digits="0123456789"
    local special="!@#$%^&*()_+-=[]{}|;:,.<>?~"

    # 构建字符池
    local char_pool=""

    # 如果指定了自定义字符集，则优先使用
    if [ -n "$custom_chars" ]; then
        char_pool="$custom_chars"
    else
        # 根据字符类型组合构建字符池
        [[ "$char_types" == *"l"* ]] && char_pool+="$lowercase"
        [[ "$char_types" == *"u"* ]] && char_pool+="$uppercase"
        [[ "$char_types" == *"d"* ]] && char_pool+="$digits"
        [[ "$char_types" == *"s"* ]] && char_pool+="$special"

        # 如果没有指定任何字符类型，使用默认字符集
        [ -z "$char_pool" ] && char_pool="${lowercase}${uppercase}${digits}"
    fi

    # 确保字符池不为空
    if [ -z "$char_pool" ]; then
        echo "错误: 字符池为空，请指定有效的字符类型" >&2
        return 1
    fi

    # 生成密码
    local password=""
    local pool_length=${#char_pool}

    # 使用 openssl 生成随机密码
    password=$(openssl rand -base64 32 | tr -dc "$char_pool" | head -c "$length")
    echo "$password"
}

# Argon2 password generator using Docker
# usage: generate_argon2_password "your_password"
generate_argon2_password() {
    local password=${1:-"123456"}
    python3 -c "
from argon2 import PasswordHasher
ph = PasswordHasher(time_cost=10, memory_cost=10240, parallelism=8)
print(ph.hash('${password}'))
" 2>/dev/null
}

# ----- Main -----
echo -e "${BLUE}🚀 开始一键部署...${NC}"

echo -e "${BLUE}🔍 检查依赖...${NC}"

check_dependencies

echo -e "${BLUE}📁 拉取配置文件...${NC}"

[ -d "$PROJECT_DIR" ] || mkdir -p "$PROJECT_DIR"

cd "$PROJECT_DIR"

if [ ! -f "$PROJECT_DIR/.env.example" ]; then
    curl -O "${DOWNLOAD_URL_PREFIX}/.env.example"
fi

if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    curl -O "${DOWNLOAD_URL_PREFIX}/docker-compose.yml"
fi

echo -e "${BLUE}🛠️ 配置环境变量...${NC}"

if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo -e "${BLUE}📝 创建配置文件...${NC}"
    cp .env.example .env

    # 获取本机IP并替换HOST_IP
    HOST_IP=$(get_host_ip)
    echo -e "${GREEN}✅ 检测到本机IP: ${HOST_IP}${NC}"

    if grep -q "HOST_IP=" .env; then
        sed -i "s/HOST_IP=.*/HOST_IP=${HOST_IP}/" .env
        echo -e "${GREEN}✅ 已更新HOST_IP为: ${HOST_IP}${NC}"
    fi

    # 生成随机密码并填充.env中的变量
    password_fields=(
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_PASSWORD"
        "REDIS_PASSWORD"
        "MINIO_ROOT_PASSWORD"
        "GRAFANA_ADMIN_PASSWORD"
        "INFLUXDB_ADMIN_PASSWORD"
        "CLICKHOUSE_PASSWORD"
    )
    for field in "${password_fields[@]}"; do
        if grep -q "${field}=" .env; then
            rand_password=$(generate_random_password 16 "lud")
            sed -i "s/${field}=.*/${field}=${rand_password}/" .env
            echo -e "${GREEN}✅ 已生成随机密码 for ${field}${NC}"
        fi
    done

    # 生成随机密钥并填充.env中的变量
    secret_fields=(
        "INFLUXDB_TOKEN"
        "APISIX_API_KEY"
    )
    for field in "${secret_fields[@]}"; do
        if grep -q "${field}=" .env; then
            rand_secret=$(generate_random_password 32 "ld")
            sed -i "s/${field}=.*/${field}=${rand_secret}/" .env
            echo -e "${GREEN}✅ 已生成随机密钥 for ${field}${NC}"
        fi
    done

    # 生成 Argon2 加密的密码并填充 .env 中的变量
    if command -v python3 >/dev/null 2>&1; then
        argon2_fields=(
            "NOTEBOOK_PYTHON_PASSWORD"
            "NOTEBOOK_CPP_PASSWORD"
            "NOTEBOOK_SQL_PASSWORD"
        )
        for field in "${argon2_fields[@]}"; do
            if grep -q "${field}=" .env; then
                rand_password=$(generate_random_password 8 "lud")
                argon2_password=$(generate_argon2_password "${rand_password}")
                sed -i "s|${field}=.*|${field}='${argon2_password}' # ${rand_password}|" .env
                echo -e "${GREEN}✅ 已生成随机密码 for ${field}${NC}"
            fi
        done
    fi

    echo -e "${YELLOW}⚠️  请检查 .env 文件中的配置，然后重新运行部署${NC}"
    echo -e "${YELLOW}   或者直接继续部署（使用默认生成的密码）${NC}"
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
elif [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env 文件已存在${NC}"
else
    echo -e "${RED}❌ .env.example 文件不存在${NC}"
    exit 1
fi

# Start services
echo -e "${BLUE}🐳 启动服务中...${NC}"
docker-compose --profile all pull
docker-compose --profile all up -d

# Wait for services to initialize
echo -e "${BLUE}⏳ 等待服务启动...${NC}"
sleep 15

# Check status
echo -e "${BLUE}🔍 检查服务状态...${NC}"
if docker-compose ps | grep -q "Exit"; then
    echo -e "${YELLOW}⚠️  有些服务可能启动异常，请查看日志: docker-compose logs${NC}"
else
    echo -e "${GREEN}✅ 所有服务启动成功！${NC}"
fi

# Summary
echo -e "\n${GREEN}🌈 部署完成！${NC}"
echo -e "${BLUE}=========================${NC}"
echo -e "${GREEN}服务访问信息以及账密请在 .env 文件中进行查看${NC}"
