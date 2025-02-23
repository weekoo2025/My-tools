#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 时区和时间同步功能
setup_timezone() {
    echo -e "${BLUE}开始配置系统时区和时间...${NC}"
    
    # 设置时区为上海
    sudo timedatectl set-timezone Asia/Shanghai
    
    # 停止现有的时间同步服务
    sudo systemctl stop systemd-timesyncd 2>/dev/null
    sudo systemctl stop ntp 2>/dev/null
    
    # 安装 NTP 服务
    sudo apt update
    sudo apt install -y ntp
    
    # 配置NTP服务器
    echo -e "${BLUE}配置NTP服务器...${NC}"
    sudo bash -c 'cat > /etc/ntp.conf << EOF
# 中国的 NTP 服务器
server ntp.aliyun.com prefer
server ntp1.aliyun.com
server ntp2.aliyun.com
server ntp3.aliyun.com

# 允许系统时间做大幅度调整
tinker panic 0

driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable
EOF'
    
    # 重启 NTP 服务
    sudo systemctl stop ntp
    sudo systemctl disable systemd-timesyncd
    sudo systemctl enable ntp
    sudo systemctl start ntp
    
    # 等待NTP服务启动
    echo -e "${BLUE}等待NTP服务启动...${NC}"
    sleep 5
    
    # 强制同步时间
    sudo ntpq -p
    
    # 显示当前时间信息
    echo -e "${GREEN}当前系统时间信息：${NC}"
    timedatectl
    
    # 验证NTP服务状态
    echo -e "${GREEN}NTP服务状态：${NC}"
    systemctl status ntp --no-pager
}

# Python升级功能
upgrade_python() {
    echo -e "${BLUE}开始Python版本检测和升级...${NC}"
    
    # 修复 apt_pkg 问题
    if ! python3 -c "import apt_pkg" 2>/dev/null; then
        echo -e "${BLUE}修复 apt_pkg 模块...${NC}"
        sudo apt-get install --reinstall python3-apt
    fi
    
    # 检查当前Python版本
    current_version=$(python3 --version 2>&1)
    echo "当前Python版本: $current_version"

    # 检查是否已安装Python 3.12
    if command -v python3.12 &> /dev/null; then
        echo -e "${GREEN}Python 3.12 已经安装${NC}"
    else
        echo -e "${GREEN}开始安装Python 3.12...${NC}"
        
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt update
        
        sudo apt install -y python3.12 python3.12-venv
        
        curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.12
        
        sudo python3.12 -m pip install --upgrade setuptools
    fi

    # 设置Python 3.12为默认版本
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 100
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 100

    # 重新安装 apt_pkg（如果需要）
    if ! python3 -c "import apt_pkg" 2>/dev/null; then
        echo -e "${BLUE}重新配置 python3-apt...${NC}"
        sudo apt-get install --reinstall python3-apt
    fi

    # 验证安装
    new_version=$(python3 --version 2>&1)
    echo -e "${GREEN}Python版本已更新为: $new_version${NC}"
    
    pip_version=$(python3 -m pip --version 2>&1)
    echo -e "${GREEN}Pip版本: $pip_version${NC}"
}

# Docker安装功能
install_docker() {
    echo -e "${BLUE}开始检测和安装Docker...${NC}"
    
    # 检查是否已安装Docker
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker已安装，版本信息：${NC}"
        docker --version
    else
        echo -e "${GREEN}开始安装Docker...${NC}"
        
        # 安装依赖
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

        # 添加Docker官方GPG密钥
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

        # 添加Docker仓库
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # 安装Docker
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io

        # 启动Docker服务
        sudo systemctl start docker
        sudo systemctl enable docker
    fi

    # 检查是否已安装Docker Compose
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}Docker Compose已安装，版本信息：${NC}"
        docker-compose --version
    else
        echo -e "${GREEN}开始安装Docker Compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker安装完成！请注销并重新登录以应用组权限更改${NC}"
}

# 前端工具安装功能
install_frontend_tools() {
    echo -e "${BLUE}开始安装前端开发工具...${NC}"
    
    # 安装Node.js
    if command -v node &> /dev/null; then
        echo -e "${GREEN}Node.js已安装，版本信息：${NC}"
        node --version
    else
        echo -e "${GREEN}开始安装Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    fi

    # 更新npm到最新版本
    echo -e "${GREEN}更新npm到最新版本...${NC}"
    sudo npm install -g npm@latest

    # 安装yarn
    if command -v yarn &> /dev/null; then
        echo -e "${GREEN}Yarn已安装，版本信息：${NC}"
        yarn --version
    else
        echo -e "${GREEN}开始安装Yarn...${NC}"
        sudo npm install -g yarn
    fi

    # 显示版本信息
    echo -e "${GREEN}安装完成，版本信息：${NC}"
    echo "Node.js: $(node --version)"
    echo "NPM: $(npm --version)"
    echo "Yarn: $(yarn --version)"
}

# 安装Docker版V2rayA
install_v2raya() {
    echo -e "${BLUE}开始安装Docker版V2rayA...${NC}"
    
    # 检查Docker是否已安装
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker未安装，请先安装Docker${NC}"
        install_docker
    fi
    
    # 拉取最新版本V2rayA
    echo -e "${GREEN}拉取V2rayA镜像...${NC}"
    docker pull mzz2017/v2raya
    
    # 停止并删除已存在的容器
    docker container stop v2raya 2>/dev/null
    docker container rm v2raya 2>/dev/null
    
    # 运行V2rayA容器
    echo -e "${GREEN}启动V2rayA...${NC}"
    docker run -d \
        --restart=always \
        --privileged \
        --network=host \
        --name v2raya \
        -e V2RAYA_LOG_FILE=/tmp/v2raya.log \
        -e V2RAYA_V2RAY_BIN=/usr/local/bin/v2ray \
        -e V2RAYA_NFTABLES_SUPPORT=off \
        -e IPTABLES_MODE=legacy \
        -v /lib/modules:/lib/modules:ro \
        -v /etc/resolv.conf:/etc/resolv.conf \
        -v /etc/v2raya:/etc/v2raya \
        mzz2017/v2raya
        
    echo -e "${GREEN}V2rayA安装完成！${NC}"
    echo -e "${GREEN}请访问 http://localhost:2017 进行配置${NC}"
}

# 安装VPS代理
install_vps_proxy() {
    while true; do
        echo -e "${BLUE}=== VPS代理安装方式 ===${NC}"
        echo "1. Sing-box官方V1.10.0系列正式版"
        echo "2. Serv00一键三协议共存脚本"
        echo "0. 返回上级菜单"
        echo -e "${BLUE}===================${NC}"
        
        read -p "请选择安装方式 (0-2): " choice
        
        case $choice in
            1)
                echo -e "${GREEN}开始安装Sing-box官方版本...${NC}"
                bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
                ;;
            2)
                echo -e "${GREEN}开始安装Serv00三协议共存版本...${NC}"
                echo -e "${BLUE}支持：vless-reality、vmess-ws(argo)、hysteria2${NC}"
                bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重试${NC}"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
        clear
    done
}

# 科学上网菜单
proxy_menu() {
    while true; do
        echo -e "${BLUE}=== 科学上网工具安装 ===${NC}"
        echo "1. 安装Docker版V2rayA"
        echo "2. VPS专用代理搭建"
        echo "0. 返回主菜单"
        echo -e "${BLUE}===================${NC}"
        
        read -p "请选择功能 (0-2): " choice
        
        case $choice in
            1)
                install_v2raya
                ;;
            2)
                install_vps_proxy
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重试${NC}"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
        clear
    done
}

# 安装佰阅部落工具箱
install_baiyue_tools() {
    echo -e "${BLUE}开始安装佰阅部落一键脚本工具箱...${NC}"
    echo -e "${GREEN}该工具箱包含多种常用工具和服务的一键安装脚本${NC}"
    
    # 提供两种安装方式的选择
    echo -e "${BLUE}请选择安装源：${NC}"
    echo "1. GitHub源 (推荐)"
    echo "2. 短链接源"
    read -p "请选择 (1-2): " source_choice
    
    case $source_choice in
        1)
            bash <(curl -L -s https://raw.githubusercontent.com/Baiyuetribe/baiyue_onekey/master/go.sh)
            ;;
        2)
            bash <(curl -L -s git.io/baiyue_onekey)
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
    esac
}

# 其他工具箱菜单
other_tools_menu() {
    while true; do
        echo -e "${BLUE}=== 其他工具箱 ===${NC}"
        echo "1. 佰阅部落一键脚本工具箱"
        echo "0. 返回主菜单"
        echo -e "${BLUE}===================${NC}"
        
        read -p "请选择功能 (0-1): " choice
        
        case $choice in
            1)
                install_baiyue_tools
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重试${NC}"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
        clear
    done
}

# 修改root密码功能
change_root_password() {
    echo -e "${BLUE}开始修改root密码...${NC}"
    echo -e "${GREEN}使用一键脚本修改root密码${NC}"
    
    # 执行一键修改root密码脚本
    bash <(curl -sSL https://raw.githubusercontent.com/elesssss/vpsroot/main/root.sh)
}

# 修改主菜单，添加新选项
show_menu() {
    echo -e "${BLUE}=== 系统工具集合 ===${NC}"
    echo "1. 设置系统时区和时间同步"
    echo "2. Python版本检测和升级"
    echo "3. Docker和Docker Compose安装"
    echo "4. 前端开发工具安装"
    echo "5. 科学上网工具安装"
    echo "6. 其他工具箱"
    echo "7. 修改root密码"
    echo "0. 退出"
    echo -e "${BLUE}===================${NC}"
}

# 修改主程序循环，添加新选项处理
while true; do
    show_menu
    read -p "请选择功能 (0-7): " choice
    
    case $choice in
        1)
            setup_timezone
            ;;
        2)
            upgrade_python
            ;;
        3)
            install_docker
            ;;
        4)
            install_frontend_tools
            ;;
        5)
            proxy_menu
            ;;
        6)
            other_tools_menu
            ;;
        7)
            change_root_password
            ;;
        0)
            echo -e "${GREEN}感谢使用，再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重试${NC}"
            ;;
    esac
    
    echo
    read -p "按回车键继续..."
    clear
done 