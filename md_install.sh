#!/bin/bash


# 检查是否以 root 用户身份执行
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

# 切换到 /root 目录
cd /root || { echo "Error: Failed to change directory to /root."; exit 1; }

# 检查参数是否正确
if [[ $# -lt 1 ]]; then
    echo "Error: Missing required parameter."
    echo "Usage: $0 {npt|inpt|ops}"
    exit 1
fi

# 第一个参数
install_env=$1

# 验证参数是否为 npt, inpt 或 ops 之一
if [[ "$install_env" != "npt" && "$install_env" != "inpt" && "$install_env" != "ops" ]]; then
    echo "Error: Invalid parameter '$install_env'."
    echo "The first parameter must be one of: npt, inpt, ops."
    exit 1
fi


# 处理 CentOS 系统的函数
handle_centos() {
    echo "This is a CentOS system."
    
    # 备份现有的 /etc/yum.repos.d/CentOS-Base.repo 文件
    if [[ -f /etc/yum.repos.d/CentOS-Base.repo ]]; then
        cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
        echo "Backup of CentOS-Base.repo created."
    else
        echo "CentOS-Base.repo not found, no backup created."
    fi

    # 创建新的 /etc/yum.repos.d/CentOS-Base.repo 文件
    cat > /etc/yum.repos.d/CentOS-Base.repo <<EOL
[base]
name=CentOS-\$releasever - Base
baseurl=http://vault.centos.org/7.9.2009/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-\$releasever - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-\$releasever - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-\$releasever - Plus
baseurl=http://vault.centos.org/7.9.2009/centosplus/\$basearch/
gpgcheck=1
enabled=0
EOL

    echo "New CentOS-Base.repo file created with specified content."

    yum install yum-utils -y
    yum-config-manager --add-repo=https://packages.microsoft.com/config/rhel/7/prod.repo

}

# 处理 Rocky Linux 系统的函数
handle_rocky_linux() {
    echo "This is a Rocky Linux system."
    
    # 执行 Rocky Linux 指定的命令
    yum install -y yum-utils
    yum-config-manager --add-repo=https://packages.microsoft.com/config/rocky/8/prod.repo
    rpm --import https://packages.microsoft.com/keys/microsoft.asc

    echo "Microsoft repository added for Rocky Linux."
}

# 主逻辑 - 获取操作系统信息并调用相应函数
os_info=$(cat /etc/os-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null)

if [[ $os_info == *"CentOS"* ]]; then
    handle_centos
elif [[ $os_info == *"Rocky Linux"* ]]; then
    handle_rocky_linux
else
    echo "Operating system is neither CentOS nor Rocky Linux."
    exit 1
fi

# 安装
yum install mdatp -y
curl -LO "https://raw.githubusercontent.com/benrootkit/mydoc/main/linux_onboarding_${install_env}.py"
python linux_onboarding_${install_env}.py

sleep 2

mdatp config real-time-protection --value enabled
mdatp config behavior-monitoring --value  enabled
mdatp scan full &
echo "MDATP scan started in the background. "
mdatp health


  

