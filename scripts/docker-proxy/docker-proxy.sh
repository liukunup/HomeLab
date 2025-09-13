#!/bin/bash
#
# brief  : Docker 代理配置
# author : LiuKun
# email  : liukunup@outlook.com
# date   : 2025-09-10
# version: 1.0.0

# 确保出错时立即退出
set -euo pipefail

# 获取脚本名称
readonly SCRIPT_NAME=$(basename "$0")
# 默认配置文件
readonly DEFAULT_PROXY_FILE="docker-proxy.txt"
readonly DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"

# 显示帮助信息
show_help() {
    echo "使用方法: ${SCRIPT_NAME} [选项]"
    echo "选项:"
    echo "  -i, --include PROXIES    包含的代理地址（英文逗号分隔）"
    echo "  -e, --exclude PROXIES    排除的代理地址（英文逗号分隔）"
    echo "  -f, --file FILE          代理列表文件路径（默认: docker-proxy.txt）"
    echo "  -h, --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ${SCRIPT_NAME} -i proxy1.com,proxy2.com -e bad-proxy.com"
    echo "  ${SCRIPT_NAME} -f my-proxies.txt"
}

# 处理代理列表
process_proxies() {
    local included_proxies=()
    local excluded_proxies=()
    local final_proxies=()

    # 解析包含的代理
    if [ -n "$INCLUDE_PROXIES" ]; then
        IFS=',' read -ra included_proxies <<< "$INCLUDE_PROXIES"
    fi

    # 解析排除的代理
    if [ -n "$EXCLUDE_PROXIES" ]; then
        IFS=',' read -ra excluded_proxies <<< "$EXCLUDE_PROXIES"
    fi

    # 从文件读取代理（如果指定了文件）
    if [ -n "$PROXY_FILE" ] && [ -f "$PROXY_FILE" ]; then
        # 使用外部文件
        while IFS= read -r line || [ -n "$line" ]; do
            # 跳过空行和注释行 + 去除前后空格
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$line" ] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
                included_proxies+=("$line")
            fi
        done < "$PROXY_FILE"
    elif [ -z "$INCLUDE_PROXIES" ] && [ -f "$DEFAULT_PROXY_FILE" ]; then
        # 使用默认文件
        while IFS= read -r line || [ -n "$line" ]; do
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$line" ] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
                included_proxies+=("$line")
            fi
        done < "$DEFAULT_PROXY_FILE"
    fi

    # 过滤掉排除的代理和重复项
    for proxy in "${included_proxies[@]}"; do
        local skip=0

        # 检查是否在排除列表中
        for excluded in "${excluded_proxies[@]}"; do
            if [ "$proxy" = "$excluded" ]; then
                skip=1
                break
            fi
        done
        if [ $skip -eq 1 ]; then
            continue
        fi

        # 检查是否已存在
        for existing in "${final_proxies[@]}"; do
            if [ "$proxy" = "$existing" ]; then
                skip=1
                break
            fi
        done
        if [ $skip -eq 1 ]; then
            continue
        fi

        # 检查是否可用
        if ! docker pull "${proxy}/hello-world" &> /dev/null; then
            continue
        fi

        # 添加
        final_proxies+=("${proxy}")
    done

    # 返回最终的代理数组
    echo "${final_proxies[@]}"
}

# 修改配置文件
configure_docker_daemon_json() {
    local proxies=("$@")
    local insecure_registries="[]"

    # 构建 insecure-registries 数组
    if [ ${#proxies[@]} -gt 0 ]; then
        insecure_registries="["
        for proxy in "${proxies[@]}"; do
            insecure_registries+="\"$proxy\","
        done
        insecure_registries="${insecure_registries%,}]"
    else
        echo "警告: 未配置任何不安全的镜像注册表"
    fi

    # 创建备份
    if [ -f "$DOCKER_DAEMON_CONFIG" ] && [ ! -f "${DOCKER_DAEMON_CONFIG}.bak" ]; then
        cp "$DOCKER_DAEMON_CONFIG" "${DOCKER_DAEMON_CONFIG}.bak"
        echo "已创建备份: ${DOCKER_DAEMON_CONFIG}.bak"
    fi

    # 处理JSON文件
    if [ -f "$DOCKER_DAEMON_CONFIG" ]; then        
        # 首先验证JSON文件格式是否正确
        if ! jq empty "$DOCKER_DAEMON_CONFIG" 2>/dev/null; then
            echo "❌ 错误: 配置文件不是有效的JSON格式"
            exit 1
        fi

        # 使用jq更新insecure-registries字段
        jq --argjson new_registries "$insecure_registries" '.["insecure-registries"] = $new_registries' \
            "$DOCKER_DAEMON_CONFIG" > "${DOCKER_DAEMON_CONFIG}.tmp"

        # 检查jq命令是否执行成功
        if [ $? -eq 0 ]; then
            mv "${DOCKER_DAEMON_CONFIG}.tmp" "$DOCKER_DAEMON_CONFIG"
            echo "✅ 成功更新现有配置文件"
        else
            echo "❌ 错误: jq命令执行失败"
            rm -f "${DOCKER_DAEMON_CONFIG}.tmp"
            exit 1
        fi
    else
        # 文件不存在，创建新的JSON文件
        cat > "$DOCKER_DAEMON_CONFIG" << EOF
{
  "insecure-registries": $insecure_registries
}
EOF
        echo "✅ 成功创建新配置文件"
    fi

    # 验证最终配置文件格式
    if jq empty "$DOCKER_DAEMON_CONFIG" 2>/dev/null; then
        echo "已更新 Docker 配置文件: $DOCKER_DAEMON_CONFIG"
        echo "最终配置内容:"
        jq . "$DOCKER_DAEMON_CONFIG"
    else
        echo "❌ 错误: 最终配置文件格式不正确"
        exit 1
    fi
}

# 重启 Docker 服务
restart_docker() {
    echo "重启 Docker 服务..."
    systemctl daemon-reload
    systemctl restart docker

    if systemctl is-active --quiet docker; then
        echo "✅ Docker服务已成功重启"
    else
        echo "❌ Docker服务重启失败"
        exit 1
    fi
}

# 测试镜像拉取
test_image_pull() {
    echo "测试镜像拉取..."
    if docker pull hello-world &> /dev/null; then
        echo "✅ 镜像拉取测试成功"
    else
        echo "❌ 镜像拉取测试失败"
        exit 1
    fi
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ 错误: 未找到 $1 命令，请先安装"
        exit 1
    fi
}

# 主函数
main() {
    # 检查必要命令
    check_command curl
    check_command sed
    check_command jq
    check_command docker

    # 初始化变量
    local INCLUDE_PROXIES=""
    local EXCLUDE_PROXIES=""
    local PROXY_FILE=""

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--include)
                INCLUDE_PROXIES="$2"
                shift 2
                ;;
            -e|--exclude)
                EXCLUDE_PROXIES="$2"
                shift 2
                ;;
            -f|--file)
                PROXY_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo "开始配置 Docker 代理..."

    # 处理代理列表
    read -ra valid_proxies <<< "$(process_proxies)"

    if [ ${#valid_proxies[@]} -eq 0 ] && [ -z "$INCLUDE_PROXIES" ]; then
        echo "警告: 未找到任何可用的代理，将继续使用现有配置"
    else
        # 配置代理
        configure_docker_daemon_json "${valid_proxies[@]}"
        # 重启 Docker 服务
        restart_docker
    fi

    # 测试镜像拉取
    test_image_pull

    echo "✅ 配置完成"
}

# 运行主函数
main "$@"