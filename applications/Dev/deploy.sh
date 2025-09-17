#!/bin/bash

# Exit on error, undefined variable, or error in pipeline
set -euo pipefail

# ----- Constants -----
readonly SCRIPT_NAME=$(basename "$0")
readonly DOWNLOAD_URL_PREFIX="https://raw.githubusercontent.com/liukunup/HomeLab/refs/heads/main/applications/Dev"
readonly PROJECT_DIR="awesome-dev-stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ----- Functions -----
# Show help message
show_help() {
    cat <<EOF
Usage: $SCRIPT_NAME [options] 

Options:
  --prepare           准备环境
  --deploy=<service>  部署指定服务

  # 默认指令
  -h, --help          显示帮助信息

Examples:
  $SCRIPT_NAME --prepare      # 准备环境
  $SCRIPT_NAME --deploy=all   # 部署所有服务
  $SCRIPT_NAME --deploy=mysql # 只部署 MySQL 服务
EOF
}

# Check if required commands are available
check_dependencies() {
    local dependencies=("sed" "openssl" "curl" "docker")

    for cmd in "${dependencies[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo -e "${RED}Error: please install ${cmd} first.${NC}"
            exit 1
        fi
    done
}

# Get the host machine's IP address
# Supports Linux and macOS
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

    local lowercase="abcdefghijklmnopqrstuvwxyz"
    local uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local digits="0123456789"
    local special="!@#$%^&*()_+-=[]{}|;:,.<>?~"

    local char_pool=""

    if [ -n "$custom_chars" ]; then
        char_pool="$custom_chars"
    else
        [[ "$char_types" == *"l"* ]] && char_pool+="$lowercase"
        [[ "$char_types" == *"u"* ]] && char_pool+="$uppercase"
        [[ "$char_types" == *"d"* ]] && char_pool+="$digits"
        [[ "$char_types" == *"s"* ]] && char_pool+="$special"

        [ -z "$char_pool" ] && char_pool="${lowercase}${uppercase}${digits}"
    fi

    if [ -z "$char_pool" ]; then
        echo "Error: Character pool is empty." >&2
        return 1
    fi

    local password=""
    local pool_length=${#char_pool}

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

# Prepare environment: check dependencies, create project dir, download files, setup .env
prepare_environment() {
    echo -e "${BLUE}🚀 准备环境...${NC}"

    echo -e "${BLUE}🔍 检查依赖...${NC}"
    check_dependencies

    echo -e "${BLUE}📁 创建目录...${NC}"
    [ -d "$PROJECT_DIR" ] || mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"

    echo -e "${BLUE}⬇️ 下载 .env.example ...${NC}"
    if [ ! -f "$PROJECT_DIR/.env.example" ]; then
        curl -O "${DOWNLOAD_URL_PREFIX}/.env.example"
    fi

    echo -e "${BLUE}⬇️ 下载 docker-compose.yml ...${NC}"
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        curl -O "${DOWNLOAD_URL_PREFIX}/docker-compose.yml"
    fi

    if [ -f ".env.example" ] && [ ! -f ".env" ]; then
        setup_environment
    elif [ -f ".env" ]; then
        echo -e "${GREEN}✅ .env 文件已存在${NC}"
    else
        echo -e "${RED}❌ .env.example 文件不存在${NC}"
        exit 1
    fi
}

# Setup .env file with dynamic values
setup_environment() {
    echo -e "${BLUE}📝 创建 .env 环境变量文件...${NC}"
    cp .env.example .env

    HOST_IP=$(get_host_ip)
    echo -e "${GREEN}✅ 检测到本机IP: ${HOST_IP}${NC}"
    if grep -q "HOST_IP=" .env; then
        sed -i "s/HOST_IP=.*/HOST_IP=${HOST_IP}/" .env
        echo -e "${GREEN}✅ 已更新HOST_IP为: ${HOST_IP}${NC}"
    fi

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

    echo -e "${GREEN}✅ 配置文件已创建: .env${NC}"
    echo -e "${YELLOW}⚠️ 请检查并根据需要修改 .env 文件中的配置项${NC}"
}

# Deploy service(s) using Docker Compose
# usage: deploy_service [service]
# service: all (default), mysql, redis, minio, ...
deploy_service() {
    local service=${1:-"all"}

    echo -e "${BLUE}🐳 部署服务: ${service}...${NC}"

    echo -e "${BLUE}⬇️ 拉取镜像...${NC}"
    docker compose --profile "${service}" pull

    echo -e "${BLUE}🚀 启动服务...${NC}"
    docker compose --profile "${service}" up -d

    echo -e "${BLUE}⏳ 等待服务启动...${NC}"
    sleep 10

    echo -e "${BLUE}🔍 检查服务状态...${NC}"
    docker compose --profile "${service}" ps
}

# ----- Main -----
main() {
    # No arguments provided
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --prepare)
                prepare_environment
                ;;
            --deploy=*)
                service="${1#*=}"
                deploy_service "$service"
                ;;
            --deploy)
                deploy_service "all"
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

main "$@"
