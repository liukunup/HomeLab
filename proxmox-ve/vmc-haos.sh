#!/bin/bash
# author: liukunup
# version: 1.0
# date: 2025-04-06
# description: Create a Home-Assistant (VM) in Proxmox VE

# 欢迎语
echo
echo "This script is designed to assist you in creating a Home-Assistant (VM) in Proxmox VE."
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


# 输入版本号
read -p "Enter the version of the HA (default: 15.2): " version
version=${version:-15.2}

# 输入虚拟机ID
read -p "Enter the vmid of the HA (default: 8888): " vmid
vmid=${vmid:-8888}

# 输入虚拟机名称
read -p "Enter the name of the HA (default: Home-Assistant): " name
name=${name:-"Home-Assistant"}

# 输入虚拟机内存大小
read -p "Enter the memory size of the HA (default: 2048, in MB): " memory
memory=${memory:-2048}

# 输入虚拟机CPU数量
read -p "Enter the number of CPUs for the HA (default: 2): " cores
cores=${cores:-2}

# 输入存储池
read -p "Enter the storage pool for the HA (default: local-lvm): " storage
storage=${storage:-"local-lvm"}

# 输入标签列表
read -p "Enter the tags for the HA (comma-separated): " tags
tags=${tags:-haos}
echo


# 拼凑镜像信息
image="haos_ova-$version.qcow2"
image_url="https://github.com/home-assistant/operating-system/releases/download/$version/haos_ova-$version.qcow2.xz"

# 检查镜像是否存在，不存在则下载
if [ ! -f "$image" ]; then
    wget "$image_url"
    unxz "$image.xz"
else
    echo "Warning: The target image already exists."
    echo
fi

# 检查镜像是否下载成功
if [ $? -ne 0 ]; then
    echo "Error: Failed to download image."
    exit 1
fi

# 将标签信息合并到tags变量中
tags="$tags,$version"


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
qm set $vmid --efidisk0 $storage:0,efitype=4m,pre-enrolled-keys=0,size=4M

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

# 启用虚拟机代理(同时开启克隆磁盘的fstrim功能)
qm set $vmid --agent enabled=1,fstrim_cloned_disks=1

# 设置标签
qm set $vmid --tags "$tags"

echo "======================"
echo "HA creation completed."
echo "======================"
echo "VM ID: $vmid"
echo "VM Name: $name"
echo "======================"