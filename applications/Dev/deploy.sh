#!/bin/bash

set -euo pipefail

# Project directory
PROJECT_DIR="dev-stack"

# Subdirectory for application (DO NOT MODIFY!)
SUB_DIR="applications/Dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 开始一键部署...${NC}"

# Check dependencies
check_dep() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}错误: 请先安装 $1${NC}"
        exit 1
    fi
}

check_dep sed
check_dep git
check_dep docker
check_dep openssl

# Prepare project directory
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}📦 项目已存在，更新中...${NC}"
    cd "$PROJECT_DIR/$SUB_DIR"
    git pull
else
    echo -e "${BLUE}📥 克隆项目中...${NC}"
    git clone https://github.com/liukunup/HomeLab.git "$PROJECT_DIR"
    cd "$PROJECT_DIR/$SUB_DIR"
fi

# Check docker-compose.yaml
if [ ! -f "docker-compose.yaml" ]; then
    echo -e "${RED}错误: 未找到 docker-compose.yaml${NC}"
    exit 1
fi

# Create .env from .env.example if not exists
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo -e "${BLUE}📝 创建环境配置文件...${NC}"
    cp .env.example .env
    
    # Generate random password
    generate_password() {
        openssl rand -base64 12 | tr -d '/+=' | cut -c1-16
    }

    # Replace with generated passwords
    if grep -q "MYSQL_ROOT_PASSWORD=" .env; then
        sed -i "s/MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=$(generate_password)/" .env
    fi
    
    if grep -q "REDIS_PASSWORD=" .env; then
        sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$(generate_password)/" .env
    fi
    
    if grep -q "MINIO_ROOT_PASSWORD=" .env; then
        sed -i "s/MINIO_ROOT_PASSWORD=.*/MINIO_ROOT_PASSWORD=$(generate_password)/" .env
    fi
    
    echo -e "${YELLOW}⚠️  请检查 .env 文件中的配置，然后重新运行部署${NC}"
    echo -e "${YELLOW}   或者直接继续部署（使用默认生成的密码）${NC}"
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Start services
echo -e "${BLUE}🐳 启动服务中...${NC}"
docker-compose pull
docker-compose up -d

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
