#!/bin/bash

# 初始化变量为默认值
SOURCE_REPO="docker.io"
TARGET_REPO="reg.homelab.lan"
IMAGES_FILE="images.txt"

# 检查是否提供了命令行参数来覆盖默认值
while getopts ":s:t:i:" opt; do
  case ${opt} in
    s )
      SOURCE_REPO=$OPTARG
      ;;
    t )
      TARGET_REPO=$OPTARG
      ;;
    i )
      IMAGES_FILE=$OPTARG
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    : )
      echo "Invalid option: -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# 显示最终使用的值（可选）
echo "Using source repository: $SOURCE_REPO"
echo "Using target repository: $TARGET_REPO"
echo "Using image file: $IMAGES_FILE"

# 登录 Docker（如果需要的话，可以注释掉或改为使用 Docker Config 或其他安全方式）
# echo "Logging in to Docker Hub..."
# docker login --username=your_username --password=your_password

# 遍历 images.txt 文件中的每一行
while IFS= read -r IMAGE; do
  # 提取镜像名称和标签
  REPO=$(echo "$IMAGE" | cut -d'/' -f1)
  IMG_NAME_TAG=$(echo "$IMAGE" | cut -d'/' -f2)
  IMG_NAME=$(echo "$IMG_NAME_TAG" | cut -d':' -f1)
  TAG=${IMG_NAME_TAG#*:}
  TAG=${TAG##*:} # 去除可能的空白字符

  # 构造源镜像和目标镜像名称
  SOURCE_IMAGE="${SOURCE_REPO}/${IMG_NAME}:${TAG}"
  TARGET_IMAGE="${TARGET_REPO}/${IMG_NAME}:${TAG}"

  # 拉取镜像
  echo "Pulling image: $SOURCE_IMAGE"
  docker pull "$SOURCE_IMAGE"
  if [ $? -ne 0 ]; then
    echo "Failed to pull image: $SOURCE_IMAGE"
    exit 1
  fi

  # 标记镜像为新的仓库路径
  echo "Tagging image: $SOURCE_IMAGE as $TARGET_IMAGE"
  docker tag "$SOURCE_IMAGE" "$TARGET_IMAGE"
  if [ $? -ne 0 ]; then
    echo "Failed to tag image: $SOURCE_IMAGE"
    exit 1
  fi

  # 推送到新的镜像仓库
  echo "Pushing to target repository: $TARGET_IMAGE"
  docker push "$TARGET_IMAGE"
  if [ $? -ne 0 ]; then
    echo "Failed to push image: $TARGET_IMAGE"
    exit 1
  fi

  echo "Image migrated successfully: $TARGET_IMAGE"
done < "$IMAGES_FILE"

# 如果需要，登出 Docker（可选）
# docker logout

echo "All images migrated successfully."
