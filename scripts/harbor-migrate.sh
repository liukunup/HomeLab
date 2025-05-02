#!/bin/bash

# 配置参数
HARBOR_HOST="reg.homelab.lan" # 替换为你的Harbor地址
HARBOR_USER=""                # Harbor用户名
HARBOR_PASS=""                # Harbor密码
IMAGES_FILE="images.txt"      # 镜像列表文件
LOG_FILE="migration.log"      # 迁移日志文件
FAILED_FILE="failed.txt"      # 失败记录文件

# 检查 skopeo 是否安装
if ! command -v skopeo &> /dev/null; then
    echo "错误：skopeo 未安装，请先安装 skopeo"
    echo "Ubuntu/Debian: sudo apt-get install skopeo -y"
    echo "CentOS/RHEL: sudo yum install skopeo -y"
    exit 1
fi

# 检查镜像列表文件是否存在
if [ ! -f "$IMAGES_FILE" ]; then
    echo "错误：镜像列表文件 $IMAGES_FILE 不存在"
    exit 1
fi

# 初始化日志文件
echo "===== 镜像迁移开始 =====" > "$LOG_FILE"
date >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
> "$FAILED_FILE"  # 清空失败记录

# 统计变量
TOTAL=0
SUCCESS=0
FAILED=0

# 逐行处理镜像
while IFS= read -r image; do

    # 跳过空行和注释行
    if [[ -z "$image" || "$image" == \#* ]]; then
        continue
    fi

    ((TOTAL++))

    # 处理镜像标签（如果没指定标签，默认使用latest）
    if [[ "$image" != *:* ]]; then
        image="$image:latest"
    fi

    # 目标镜像地址（默认放到library项目下）
    target_image="$HARBOR_HOST/library/$image"

    echo "正在迁移: $image -> $target_image"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 迁移: docker.io/$image -> $target_image" >> "$LOG_FILE"

    # 执行skopeo复制
    if skopeo copy --insecure-policy \
        --src-tls-verify=false \
        --dest-tls-verify=false \
        --dest-creds "$HARBOR_USER:$HARBOR_PASS" \
        "docker://docker.io/$image" \
        "docker://$target_image" >> "$LOG_FILE" 2>&1; then
        
        echo "迁移成功: $image"
        echo "  状态: 成功" >> "$LOG_FILE"
        ((SUCCESS++))
    else
        echo "迁移失败: $image"
        echo "  状态: 失败" >> "$LOG_FILE"
        echo "$image" >> "$FAILED_FILE"
        ((FAILED++))
    fi

    echo "" >> "$LOG_FILE"
    echo "----------------------------------------"
done < "$IMAGES_FILE"

# 生成统计报告
echo "" >> "$LOG_FILE"
echo "===== 迁移统计 =====" >> "$LOG_FILE"
echo "总镜像数: $TOTAL" >> "$LOG_FILE"
echo "成功数: $SUCCESS" >> "$LOG_FILE"
echo "失败数: $FAILED" >> "$LOG_FILE"
echo "失败镜像已记录到: $FAILED_FILE" >> "$LOG_FILE"
date >> "$LOG_FILE"

# 输出最终结果
echo ""
echo "===== 迁移完成 ====="
echo "查看详细日志: $LOG_FILE"
echo "失败镜像列表: $FAILED_FILE"
echo "统计:"
echo "  总镜像数: $TOTAL"
echo "  成功数: $SUCCESS"
echo "  失败数: $FAILED"