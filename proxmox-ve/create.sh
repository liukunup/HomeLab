#!/bin/bash
# author: liukunup
# version: 1.0
# date: 2025-03-21
# description: Create a virtual machine (VM) in Proxmox VE

# 欢迎语
echo
echo "This script is designed to assist you in creating a virtual machine (VM) in Proxmox VE."
echo

# 检查是否安装了 Proxmox VE
if ! command -v pveversion > /dev/null 2>&1; then
    echo "Proxmox VE is not installed. Please install it first."
    exit 1
fi

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with root privileges."
    exit 1
fi

# 检查是否安装了 wget
if ! command -v wget > /dev/null 2>&1; then
    echo "wget is not installed. Please install it first."
    exit 1
fi

# 输入发行版本
echo "Which distribution do you want to use?"
echo "1. Debian 12"
echo "2. Debian 11"
echo "3. Ubuntu 24.04"
echo "4. Ubuntu 22.04"
echo "5. Ubuntu 20.04"
read -p "Enter your choice (default: Debian 12): " distribution
distribution=${distribution:-1}
echo

# 输入架构
echo "Which architecture do you want to use?"
echo "1. amd64"
echo "2. arm64"
read -p "Enter your choice (default: amd64): " architecture
architecture=${architecture:-1}
echo

# 输入虚拟机ID
read -p "Enter the vmid of the VM (default: 8888): " vmid
vmid=${vmid:-8888}
# 输入虚拟机名称
read -p "Enter the name of the VM (default: vm-template): " name
name=${name:-"vm-template"}
# 输入虚拟机内存大小
read -p "Enter the memory size of the VM (default: 4096, in MB): " memory
memory=${memory:-4096}
# 输入虚拟机CPU数量
read -p "Enter the number of CPUs for the VM (default: 2): " cores
cores=${cores:-2}
# 输入存储池
read -p "Enter the storage pool for the VM (default: local-lvm): " storage
storage=${storage:-"local-lvm"}
# 输入虚拟机磁盘扩容大小
read -p "Enter the disk size to expand for the VM (default: 60, in GB): " disksize
disksize=${disksize:-60}
# 输入标签列表
read -p "Enter the tags for the VM (comma-separated): " tags
tags=${tags:-linux}
echo

# 输入 Cloud-Init 用户名
read -p "Enter the username for the Cloud-Init (default: root): " ciuser
ciuser=${ciuser:-root}
# 输入 Cloud-Init SSH公钥
read -p "Enter the SSH public key file for the Cloud-Init (~/.ssh/id_rsa.pub): " sshkeys
sshkeys=${sshkeys:-"~/.ssh/id_rsa.pub"}
# 输入自定义 Cloud-Init 配置
read -p "Enter the custom configuration for the Cloud-Init (e.g. user=QuTS:snippets/user-data.yaml): " cicustom
cicustom=${cicustom:-""}
echo

# 是否转换成模板
read -p "Do you want to convert this VM to a template? (y/n, default: n): " convert_to_template
convert_to_template=${convert_to_template:-n}
echo

# 按照选择的发行版本和架构下载镜像
download_image() {

    local distribution=$1
    local architecture=$2

    local image_url=""
    local image_filename=""
    local image_tags=""

    case $distribution in
        1)
            # Debian 12
            case $architecture in
                1)
                    image_filename="debian-12-genericcloud-amd64.qcow2"
                    image_url="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
                    image_tags="debian,12,bookworm,amd64"
                    ;;
                2)
                    image_filename="debian-12-genericcloud-arm64.qcow2"
                    image_url="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.qcow2"
                    image_tags="debian,12,bookworm,arm64"
                    ;;
                *)
                    echo "Error: Invalid architecture. code: $architecture"
                    exit 1
                    ;;
            esac
            ;;
        2)
            # Debian 11
            case $architecture in
                1)
                    image_filename="debian-11-genericcloud-amd64.qcow2"
                    image_url="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
                    image_tags="debian,11,bullseye,amd64"
                    ;;
                2)
                    image_filename="debian-11-genericcloud-arm64.qcow2"
                    image_url="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-arm64.qcow2"
                    image_tags="debian,11,bullseye,arm64"
                    ;;
                *)
                    echo "Error: Invalid architecture. code: $architecture"
                    exit 1
                    ;;
            esac
            ;;
        3)
            # Ubuntu 24.04
            case $architecture in
                1)
                    image_filename="noble-server-cloudimg-amd64.img"
                    image_url="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
                    image_tags="ubuntu,24.04,noble,amd64"
                    ;;
                2)
                    image_filename="noble-server-cloudimg-arm64.img"
                    image_url="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-arm64.img"
                    image_tags="ubuntu,24.04,noble,arm64"
                    ;;
                *)
                    echo "Error: Invalid architecture. code: $architecture"
                    exit 1
                    ;;
            esac
            ;;
        4)
            # Ubuntu 22.04
            case $architecture in
                1)
                    image_filename="jammy-server-cloudimg-amd64.img"
                    image_url="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
                    image_tags="ubuntu,22.04,jammy,amd64"
                    ;;
                2)
                    image_filename="jammy-server-cloudimg-arm64.img"
                    image_url="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img"
                    image_tags="ubuntu,22.04,jammy,arm64"
                    ;;
                *)
                    echo "Error: Invalid architecture. code: $architecture"
                    exit 1
                    ;;
            esac
            ;;
        5)
            # Ubuntu 20.04
            case $architecture in
                1)
                    image_filename="focal-server-cloudimg-amd64.img"
                    image_url="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
                    image_tags="ubuntu,20.04,focal,amd64"
                    ;;
                2)
                    image_filename="focal-server-cloudimg-arm64.img"
                    image_url="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-arm64.img"
                    image_tags="ubuntu,20.04,focal,arm64"
                    ;;
                *)
                    echo "Error: Invalid architecture. code: $architecture"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Invalid distribution. code: $distribution"
            exit 1
            ;;
    esac

    # 检查镜像是否存在，不存在则下载
    if [ ! -f "$image_filename" ]; then
        wget "$image_url"
    else
        echo "Warning: The target image already exists."
        echo
    fi
    # 检查镜像是否下载成功
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download image."
        exit 1
    fi
    # 将镜像文件名赋值给image变量
    image=$image_filename

    # 将标签信息合并到tags变量中
    if [ -n "$image_tags" ]; then
        tags="$tags,$image_tags"
    fi
}

# 调用函数
download_image $distribution $architecture

# 创建虚拟机
create_vm() {

    local vmid=$1
    local name=$2
    local memory=$3
    local cores=$4
    local image=$5
    local storage=$6
    local tags=$7

    local ciuser=$8
    local sshkeys=$9
    local cicustom=${10}

    local disksize=${11}

    echo "VM Params: $vmid $name $memory $cores $image $storage $tags $ciuser $sshkeys $cicustom $disksize"
    echo

    # 如果 vmid 已存在则提示用户先停止并删除对应虚拟机
    if qm list | grep -q " $vmid "; then
        echo "Error: VM ID $vmid exists."
        echo "Stop the target VM ? qm stop $vmid"
        echo "Delete the target VM ? qm destroy $vmid"
        exit 1
    fi

    # 创建虚拟机
    qm create $vmid --name $name --memory $memory --cores $cores

    # 导入镜像到虚拟机
    qm importdisk $vmid $image $storage

    # 设置操作系统类型
    qm set $vmid --ostype l26

    # 设置SCSI硬件类型
    qm set $vmid --scsihw virtio-scsi-single

    # 设置BIOS类型
    qm set $vmid --bios ovmf
    # 设置EFI磁盘
    qm set $vmid --efidisk0 $storage:0,efitype=4m,pre-enrolled-keys=1,size=4M
    # 设置TPM状态
    qm set $vmid --tpmstate0 $storage:0,size=4M,version=v2.0

    # 设置CPU插槽数
    qm set $vmid --sockets 1
    # 设置CPU型号
    qm set $vmid --cpu x86-64-v2-AES
    # 启用NUMA支持
    qm set $vmid --numa 1

    # 设置网络接口
    qm set $vmid --net0 virtio,bridge=vmbr0,firewall=1

    # 设置SCSI磁盘
    qm set $vmid --scsi0 $storage:vm-$vmid-disk-0,iothread=1,ssd=1

    # 设置启动选项
    qm set $vmid --boot order=scsi0

    # 设置串口
    qm set $vmid --serial0 socket

    # 设置 Cloud-Init SCSI磁盘
    qm set $vmid --scsi1 $storage:cloudinit
    # 设置 Cloud-Init 用户
    qm set $vmid --ciuser $ciuser
    # 设置 Cloud-Init SSH公钥
    qm set $vmid --sshkeys $sshkeys
    # 设置网络配置
    qm set $vmid --ipconfig0 ip=dhcp,ip6=dhcp
    # 设置 Cloud-Init 自定义配置(user,network,meta)
    qm set $vmid --cicustom $cicustom

    # 调整虚拟机磁盘大小
    qm resize $vmid scsi0 +${disksize}G

    # 启用虚拟机代理(同时开启克隆磁盘的fstrim功能)
    qm set $vmid --agent enabled=1,fstrim_cloned_disks=1
    # 设置标签
    qm set $vmid --tags "$tags"
}

# 调用函数
create_vm $vmid $name $memory $cores $image $storage $tags $ciuser $sshkeys $cicustom $disksize

# 转换为模板
if [ "$convert_to_template" = "y" ] || [ "$convert_to_template" = "Y" ]; then
    qm template $vmid
fi

echo "======================"
echo "VM creation completed."
echo "======================"
echo "VM ID: $vmid"
echo "VM Name: $name"
echo "======================"