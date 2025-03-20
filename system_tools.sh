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
    
    # 使用京东服务器进行时间同步
    echo -e "${BLUE}使用京东服务器同步时间...${NC}"
    bash -c "$(curl -fsSL git.io/JDIXU)"
    
    # 显示当前时间信息
    echo -e "${GREEN}当前系统时间信息：${NC}"
    timedatectl
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

    # 选择要安装的Python版本
    echo -e "${BLUE}请选择要安装的Python版本:${NC}"
    echo "1. Python 3.11"
    echo "2. Python 3.12"
    read -p "请选择 (1-2): " python_version_choice

    case $python_version_choice in
        1)
            python_version="3.11"
            ;;
        2)
            python_version="3.12"
            ;;
        *)
            echo -e "${RED}无效的选择，默认安装Python 3.12${NC}"
            python_version="3.12"
            ;;
    esac

    # 检查是否已安装选择的Python版本
    if command -v python$python_version &> /dev/null; then
        echo -e "${GREEN}Python $python_version 已经安装${NC}"
    else
        echo -e "${GREEN}开始安装Python $python_version...${NC}"
        
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt update
        
        # 安装Python和venv
        sudo apt install -y python$python_version python${python_version}-venv python${python_version}-dev
        
        # 安装pip
        curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python$python_version
        
        # 安装setuptools
        sudo python$python_version -m pip install --upgrade setuptools
    fi

    # 检查venv是否安装
    if ! dpkg -l | grep -q "python${python_version}-venv"; then
        echo -e "${BLUE}安装 Python venv 模块...${NC}"
        sudo apt install -y python${python_version}-venv
    fi

    # 设置选择的Python版本为默认版本
    echo -e "${GREEN}设置Python $python_version为默认版本...${NC}"
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python$python_version 100
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python$python_version 100

    # 重新安装 apt_pkg（如果需要）
    if ! python3 -c "import apt_pkg" 2>/dev/null; then
        echo -e "${BLUE}重新配置 python3-apt...${NC}"
        sudo apt-get install --reinstall python3-apt
    fi

    # 验证安装
    new_version=$(python3 --version 2>&1)
    echo -e "${GREEN}Python版本已更新为: $new_version${NC}"
    
    # 验证pip和venv
    pip_version=$(python3 -m pip --version 2>&1)
    echo -e "${GREEN}Pip版本: $pip_version${NC}"
    
    if python3 -m venv --help &>/dev/null; then
        echo -e "${GREEN}Python venv 已正确安装${NC}"
    else
        echo -e "${RED}警告: Python venv 可能未正确安装${NC}"
    fi
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

    # 安装pnpm
    if command -v pnpm &> /dev/null; then
        echo -e "${GREEN}pnpm已安装，版本信息：${NC}"
        pnpm --version
    else
        echo -e "${GREEN}开始安装pnpm...${NC}"
        sudo npm install -g pnpm
    fi

    # 安装bun
    if command -v bun &> /dev/null; then
        echo -e "${GREEN}bun已安装，版本信息：${NC}"
        bun --version
    else
        echo -e "${GREEN}开始安装bun...${NC}"
        sudo npm install -g bun
    fi

    # 安装pm2
    if command -v pm2 &> /dev/null; then
        echo -e "${GREEN}pm2已安装，版本信息：${NC}"
        pm2 --version
    else
        echo -e "${GREEN}开始安装pm2...${NC}"
        sudo npm install -g pm2
    fi

    # 显示版本信息
    echo -e "${GREEN}安装完成，版本信息：${NC}"
    echo "Node.js: $(node --version)"
    echo "NPM: $(npm --version)"
    echo "Yarn: $(yarn --version)"
    echo "pnpm: $(pnpm --version)"
    echo "bun: $(bun --version)"
    echo "pm2: $(pm2 --version)"

    echo -e "${GREEN}前端开发工具安装完成！${NC}"
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
                bash <(curl -Ls https://hub.gitmirror.com/raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
                ;;
            2)
                echo -e "${GREEN}开始安装Serv00三协议共存版本...${NC}"
                echo -e "${BLUE}支持：vless-reality、vmess-ws(argo)、hysteria2${NC}"
                bash <(curl -Ls https://hub.gitmirror.com/raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)
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
            bash <(curl -L -s https://hub.gitmirror.com/raw.githubusercontent.com/Baiyuetribe/baiyue_onekey/master/go.sh)
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
    bash <(curl -sSL https://hub.gitmirror.com/raw.githubusercontent.com/elesssss/vpsroot/main/root.sh)
}

# Linux综合工具箱安装
install_linux_scripts() {
    echo -e "${BLUE}开始安装Linux综合工具箱...${NC}"
    echo -e "${GREEN}该工具箱包含IP修改、主机名修改、MosDNS安装、UI面板安装和Singbox安装等功能${NC}"
    
    # 下载并执行安装脚本
    wget --quiet --show-progress -O /mnt/main_install.sh https://hub.gitmirror.com/raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
}

# 影视工具菜单
show_media_menu() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│            影视娱乐工具              │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}1.${NC} 小雅Alist"
    echo -e "${BLUE}│${NC} ${GREEN}2.${NC} Emby服务器"
    echo -e "${BLUE}│${NC} ${GREEN}3.${NC} Jellyfin服务器"
    echo -e "${BLUE}│${NC} ${GREEN}4.${NC} TVBox配置"
    echo -e "${BLUE}│${NC} ${GREEN}0.${NC} 返回主菜单"
    echo -e "${BLUE}└──────────────────────────────────────┘${NC}"
}

# 安装小雅全家桶
install_xiaoya() {
    echo -e "${BLUE}开始安装小雅全家桶...${NC}"
    echo -e "${GREEN}包含：Alist、Emby、Jellyfin、TVBox${NC}"
    
    bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
}

# 主菜单显示
show_main_menu() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│          Linux 系统工具集合          │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}1.${NC} 系统设置与优化"
    echo -e "${BLUE}│${NC} ${GREEN}2.${NC} 开发环境配置"
    echo -e "${BLUE}│${NC} ${GREEN}3.${NC} 网络代理工具"
    echo -e "${BLUE}│${NC} ${GREEN}4.${NC} 系统工具箱"
    echo -e "${BLUE}│${NC} ${GREEN}5.${NC} 影视娱乐工具"
    echo -e "${BLUE}│${NC} ${GREEN}0.${NC} 退出脚本"
    echo -e "${BLUE}└──────────────────────────────────────┘${NC}"
}

# 系统设置菜单
show_system_menu() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│            系统设置与优化            │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}1.${NC} 时区和时间同步 (京东服务器)"
    echo -e "${BLUE}│${NC} ${GREEN}2.${NC} Root密码修改"
    echo -e "${BLUE}│${NC} ${GREEN}3.${NC} BBR加速配置"
    echo -e "${BLUE}│${NC} ${GREEN}0.${NC} 返回主菜单"
    echo -e "${BLUE}└──────────────────────────────────────┘${NC}"
}

# 开发环境菜单
show_dev_menu() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│            开发环境配置              │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}1.${NC} Python环境 (3.12)"
    echo -e "${BLUE}│${NC} ${GREEN}2.${NC} Docker环境"
    echo -e "${BLUE}│${NC} ${GREEN}3.${NC} Node.js环境"
    echo -e "${BLUE}│${NC} ${GREEN}0.${NC} 返回主菜单"
    echo -e "${BLUE}└──────────────────────────────────────┘${NC}"
}

# 网络代理菜单
show_proxy_menu() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│            网络代理工具              │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}1.${NC} Docker版V2rayA"
    echo -e "${BLUE}│${NC} ${GREEN}2.${NC} Sing-box官方版"
    echo -e "${BLUE}│${NC} ${GREEN}3.${NC} Serv00三协议共存版"
    echo -e "${BLUE}│${NC} ${GREEN}0.${NC} 返回主菜单"
    echo -e "${BLUE}└──────────────────────────────────────┘${NC}"
}

# 工具箱菜单
show_tools_menu() {
    clear
    echo -e "${BLUE}┌──────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│            系统工具箱                │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${GREEN}1.${NC} 佰阅部落工具箱"
    echo -e "${BLUE}│${NC} ${GREEN}2.${NC} Linux综合工具箱"
    echo -e "${BLUE}│${NC} ${GREEN}3.${NC} 系统优化工具集"
    echo -e "${BLUE}│${NC} ${GREEN}0.${NC} 返回主菜单"
    echo -e "${BLUE}└──────────────────────────────────────┘${NC}"
}

# 修改主程序循环，添加新选项处理
while true; do
    show_main_menu
    read -p "请选择功能 (0-5): " choice
    
    case $choice in
        1)
            show_system_menu
            read -p "请选择功能 (0-3): " sub_choice
            case $sub_choice in
                1)
                    setup_timezone
                    ;;
                2)
                    change_root_password
                    ;;
                3)
                    # 实现BBR加速配置
                    echo -e "${GREEN}BBR加速配置功能正在开发中...${NC}"
                    ;;
                0)
                    ;;
                *)
                    echo -e "${RED}无效的选择，请重试${NC}"
                    ;;
            esac
            ;;
        2)
            show_dev_menu
            read -p "请选择功能 (0-3): " sub_choice
            case $sub_choice in
                1)
                    upgrade_python
                    ;;
                2)
                    install_docker
                    ;;
                3)
                    install_frontend_tools
                    ;;
                0)
                    ;;
                *)
                    echo -e "${RED}无效的选择，请重试${NC}"
                    ;;
            esac
            ;;
        3)
            show_proxy_menu
            read -p "请选择功能 (0-3): " sub_choice
            case $sub_choice in
                1)
                    install_v2raya
                    ;;
                2)
                    install_vps_proxy
                    ;;
                3)
                    # 实现Serv00三协议共存版
                    echo -e "${GREEN}Serv00三协议共存版功能正在开发中...${NC}"
                    ;;
                0)
                    ;;
                *)
                    echo -e "${RED}无效的选择，请重试${NC}"
                    ;;
            esac
            ;;
        4)
            show_tools_menu
            read -p "请选择功能 (0-3): " sub_choice
            case $sub_choice in
                1)
                    install_baiyue_tools
                    ;;
                2)
                    install_linux_scripts
                    ;;
                3)
                    # 实现系统优化工具集
                    echo -e "${GREEN}系统优化工具集功能正在开发中...${NC}"
                    ;;
                0)
                    ;;
                *)
                    echo -e "${RED}无效的选择，请重试${NC}"
                    ;;
            esac
            ;;
        5)
            show_media_menu
            read -p "请选择功能 (0-4): " sub_choice
            case $sub_choice in
                1)
                    install_xiaoya
                    ;;
                2)
                    echo -e "${GREEN}Emby服务器安装功能正在开发中...${NC}"
                    ;;
                3)
                    echo -e "${GREEN}Jellyfin服务器安装功能正在开发中...${NC}"
                    ;;
                4)
                    echo -e "${GREEN}TVBox配置功能正在开发中...${NC}"
                    ;;
                0)
                    ;;
                *)
                    echo -e "${RED}无效的选择，请重试${NC}"
                    ;;
            esac
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