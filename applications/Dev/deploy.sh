#!/bin/bash

set -e

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 开始一键部署...${NC}"

# 检查依赖
check_dep() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}错误: 请先安装 $1${NC}"
        exit 1
    fi
}

check_dep docker
check_dep docker-compose

# 设置项目目录
PROJECT_DIR="./docker-stack"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}📦 项目已存在，更新中...${NC}"
    cd "$PROJECT_DIR"
    git pull
else
    echo -e "${BLUE}📥 克隆项目中...${NC}"
    git clone https://github.com/your-username/your-repo.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

# 检查必要文件
if [ ! -f "docker-compose.yaml" ]; then
    echo -e "${RED}错误: 未找到 docker-compose.yaml${NC}"
    exit 1
fi

# 处理环境变量
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo -e "${BLUE}📝 创建环境配置文件...${NC}"
    cp .env.example .env
    
    # 生成随机密码
    generate_password() {
        openssl rand -base64 12 | tr -d '/+=' | cut -c1-16
    }
    
    # 替换密码字段
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

# 创建数据目录
echo -e "${BLUE}📁 创建数据目录...${NC}"
mkdir -p data/{mysql,redis,minio,kafka,etcd}
mkdir -p certs

# 拉取镜像并启动
echo -e "${BLUE}🐳 启动服务中...${NC}"
docker-compose pull
docker-compose up -d

# 等待服务启动
echo -e "${BLUE}⏳ 等待服务启动...${NC}"
sleep 15

# 检查状态
echo -e "${BLUE}🔍 检查服务状态...${NC}"
if docker-compose ps | grep -q "Exit"; then
    echo -e "${YELLOW}⚠️  有些服务可能启动异常，请查看日志: docker-compose logs${NC}"
else
    echo -e "${GREEN}✅ 所有服务启动成功！${NC}"
fi

# 显示访问信息
echo -e "\n${GREEN}🌈 部署完成！${NC}"
echo -e "${BLUE}=========================${NC}"
echo -e "${GREEN}服务访问信息:${NC}"
echo -e "MySQL: localhost:3306"
echo -e "Redis: localhost:6379" 
echo -e "MinIO: http://localhost:9000"
echo -e "MinIO控制台: http://localhost:9001"
echo -e "APISIX: http://localhost:9080"
echo -e "APISIX管理: http://localhost:9180"
echo -e "${BLUE}=========================${NC}"
echo -e "\n${YELLOW}📋 常用命令:${NC}"
echo -e "查看日志: docker-compose logs"
echo -e "停止服务: docker-compose stop"
echo -e "重启服务: docker-compose restart"
echo -e "删除服务: docker-compose down"
