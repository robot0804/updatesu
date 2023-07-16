#!/bin/bash

# 提醒用户使用脚本具有一定危险性
echo "警告：使用本脚本可能会造成系统操作错误或数据丢失，请确保您理解脚本的功能和风险，并愿意自行承担责任。"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi

# 1. 停止 Supervisor 服务
echo "步骤 1：停止 Supervisor 服务"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi
systemctl stop hassio-supervisor.service
systemctl stop hassio-apparmor.service
echo "已停止 Supervisor 服务."

# 2. 禁止 Supervisor 自动启动
echo "步骤 2：禁止 Supervisor 自动启动"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi
systemctl disable hassio-supervisor.service
systemctl disable hassio-apparmor.service
echo "已禁止 Supervisor 自动启动."

# 3. 检查并停止/删除 hassio_supervisor 容器
echo "步骤 3：检查并停止/删除 hassio_supervisor 容器"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi
if docker ps -a --format "{{.Names}}" | grep -q "hassio_supervisor"; then
    echo "停止 hassio_supervisor 容器..."
    docker stop hassio_supervisor
    echo "已停止 hassio_supervisor 容器."
    
    echo "删除 hassio_supervisor 容器..."
    docker rm hassio_supervisor
    echo "已删除 hassio_supervisor 容器."
else
    echo "hassio_supervisor 容器未找到，无需操作."
fi

# 4. 删除 ghcr.io/home-assistant/aarch64-hassio-supervisor 镜像
echo "步骤 4：删除 ghcr.io/home-assistant/aarch64-hassio-supervisor 镜像"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi
if docker images --format "{{.Repository}}" | grep -q "ghcr.io/home-assistant/aarch64-hassio-supervisor"; then
    echo "删除 ghcr.io/home-assistant/aarch64-hassio-supervisor 镜像..."
    docker rmi ghcr.io/home-assistant/aarch64-hassio-supervisor
    echo "已删除 ghcr.io/home-assistant/aarch64-hassio-supervisor 镜像."
else
    echo "ghcr.io/home-assistant/aarch64-hassio-supervisor 镜像未找到，无需操作."
fi

# 5. 检查并输出文件信息
echo "步骤 5：检查并输出文件信息"
file_counter=0
file_numbers=()
file_paths=()
file_names=()
file_sizes=()
file_creation_times=()

check_directory() {
    local directory=$1
    local file_pattern=$2

    for file_path in "$directory"/*"$file_pattern"*.tar.gz; do
        if [ -f "$file_path" ]; then
            file_counter=$((file_counter+1))
            file_numbers+=($file_counter)
            file_paths+=("$file_path")
            file_names+=("$(basename "$file_path")")
            file_sizes+=("$(du -h "$file_path" | awk '{print $1}')")
            file_creation_times+=("$(stat -c "%y" "$file_path")")
            
            echo "[$file_counter] 文件路径: $file_path"
            echo "    文件名: ${file_names[$file_counter-1]}"
            echo "    创建时间: ${file_creation_times[$file_counter-1]}"
            echo "    文件大小: ${file_sizes[$file_counter-1]}"
        fi
    done
}

check_directory "/home/update" "hassio-supervisor"
check_directory "/usr/share/hassio/share" "hassio-supervisor"

if [ $file_counter -eq 0 ]; then
    echo "未找到含有 'hassio-supervisor' 字样的 tar.gz 文件。"
    exit 0
fi

echo "请输入文件编号以继续操作: "
read selected_file_number

if [[ "${file_numbers[*]}" =~ (^|[[:space:]])"$selected_file_number"($|[[:space:]]) ]]; then
    selected_index=$((selected_file_number-1))
    selected_file_path="${file_paths[$selected_index]}"

    echo "已选择文件: ${file_paths[$selected_index]}"
    echo "文件名: ${file_names[$selected_index]}"
    echo "创建时间: ${file_creation_times[$selected_index]}"
    echo "文件大小: ${file_sizes[$selected_index]}"

    echo "开始加载镜像..."
    docker load < "$selected_file_path"
    echo "镜像加载完成."
else
    echo "输入的文件编号不正确。"
    exit 0
fi

# 6. 启动加载的镜像
echo "步骤 6：启动加载的镜像"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi
systemctl start hassio-supervisor.service
systemctl start hassio-apparmor.service
echo "已启动加载的镜像."

# 7. 启用自动重启服务
echo "步骤 7：启用自动重启服务"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi
systemctl enable hassio-supervisor.service
systemctl enable hassio-apparmor.service
echo "已启用自动重启服务."

# 8. 重启整个系统
echo "步骤 8：重启整个系统"
read -p "继续操作吗？(y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "已取消操作."
    exit 0
fi
echo "重启整个系统..."
reboot
