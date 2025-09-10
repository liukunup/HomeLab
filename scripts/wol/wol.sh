#!/bin/bash

# 预定义的设备列表（格式：编号) 设备名称|MAC地址）
DEVICES=(
    "1) QuTS|24:5E:BE:67:CC:7D"
    "2) DS218 Plus|00:11:32:95:02:2D"
    "3) PVE|00:E0:5A:68:01:31"
    "4) CWWK|A8:B8:E0:08:20:92"
)

# 自动安装依赖（如果缺失）
check_deps() {
    if ! command -v wakeonlan &>/dev/null; then
        echo "检测到未安装 wakeonlan，尝试自动安装..."
        
        # 根据系统类型选择安装命令
        if [[ -f /etc/os-release ]]; then
            # Linux (Debian/Ubuntu)
            if command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y wakeonlan
            # Linux (RedHat/CentOS)
            elif command -v yum &>/dev/null; then
                sudo yum install -y wakeonlan
            # Linux (Arch)
            elif command -v pacman &>/dev/null; then
                sudo pacman -Sy --noconfirm wakeonlan
            else
                echo "错误：不支持的 Linux 发行版，请手动安装 wakeonlan！"
                exit 1
            fi
        # macOS
        elif [[ "$(uname)" == "Darwin" ]]; then
            if command -v brew &>/dev/null; then
                brew install wakeonlan
            else
                echo "错误：请先安装 Homebrew (https://brew.sh)，然后运行: brew install wakeonlan"
                exit 1
            fi
        else
            echo "错误：不支持的操作系统，请手动安装 wakeonlan！"
            exit 1
        fi

        # 验证安装是否成功
        if ! command -v wakeonlan &>/dev/null; then
            echo "安装失败，请手动安装 wakeonlan！"
            exit 1
        fi
        echo "✅ wakeonlan 安装成功！"
    fi
}

# 显示菜单并唤醒设备
wake_device() {
    echo "请选择要唤醒的设备："
    for device in "${DEVICES[@]}"; do
        echo "  $device"
    done

    read -p "输入设备编号: " choice
    for device in "${DEVICES[@]}"; do
        if [[ "$device" == "$choice)"* ]]; then
            IFS="|" read -r name mac <<< "${device#*) }"
            echo "唤醒 $name ($mac)..."
            wakeonlan "$mac"
            exit 0
        fi
    done
    echo "错误：无效编号！"
    exit 1
}

# 主流程
check_deps
wake_device