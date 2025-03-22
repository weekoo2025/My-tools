#!/bin/bash
# 升级python版本

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 错误处理函数
handle_error() {
    echo -e "${RED}错误: $1${NC}"
    exit 1
}

# 安装指定版本的Python
install_python() {
    local version=$1
    echo -e "${BLUE}开始安装Python $version...${NC}"
    
    # 更新包列表
    echo -e "${BLUE}更新软件包列表...${NC}"
    sudo apt update || handle_error "更新软件包列表失败"
    
    # 安装依赖
    echo -e "${BLUE}安装必要依赖...${NC}"
    sudo apt install -y software-properties-common || handle_error "安装依赖失败"
    
    # 添加deadsnakes PPA
    echo -e "${BLUE}添加Python PPA源...${NC}"
    sudo add-apt-repository -y ppa:deadsnakes/ppa || handle_error "添加PPA源失败"
    
    # 更新包列表
    sudo apt update || handle_error "更新软件包列表失败"
    
    # 安装Python及相关包
    echo -e "${BLUE}安装Python ${version}及相关包...${NC}"
    sudo apt install -y python${version} python${version}-venv python${version}-dev || handle_error "安装Python失败"
    
    # 安装pip
    echo -e "${BLUE}安装pip...${NC}"
    curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py || handle_error "下载pip安装脚本失败"
    sudo python${version} get-pip.py || handle_error "安装pip失败"
    rm get-pip.py
    
    # 安装setuptools
    echo -e "${BLUE}安装setuptools...${NC}"
    sudo python${version} -m pip install --upgrade setuptools || handle_error "安装setuptools失败"
}

echo -e "${BLUE}开始检测当前Python版本...${NC}"

# 检查当前Python版本
current_version=$(python3 --version 2>&1) || handle_error "无法获取Python版本"
echo -e "${GREEN}当前Python版本: $current_version${NC}"

# 处理命令行参数
if [ $# -eq 1 ]; then
    choice=$1
else
    # 显示选项菜单
    echo -e "\n${BLUE}请选择要安装的Python版本：${NC}"
    echo "1) Python 3.11"
    echo "2) Python 3.12"
    echo "3) 两个版本都安装"
    read -p "请输入选项 (1-3): " choice
fi

case $choice in
    1)
        if command -v python3.11 &> /dev/null; then
            echo -e "${GREEN}Python 3.11 已经安装${NC}"
        else
            install_python "3.11"
        fi
        selected_version="3.11"
        ;;
    2)
        if command -v python3.12 &> /dev/null; then
            echo -e "${GREEN}Python 3.12 已经安装${NC}"
        else
            install_python "3.12"
        fi
        selected_version="3.12"
        ;;
    3)
        if ! command -v python3.11 &> /dev/null; then
            install_python "3.11"
        else
            echo -e "${GREEN}Python 3.11 已经安装${NC}"
        fi
        if ! command -v python3.12 &> /dev/null; then
            install_python "3.12"
        else
            echo -e "${GREEN}Python 3.12 已经安装${NC}"
        fi
        
        # 如果是通过命令行参数调用，默认使用3.12作为默认版本
        if [ $# -eq 1 ]; then
            selected_version="3.12"
        else
            echo -e "\n${BLUE}请选择要设置为默认的Python版本：${NC}"
            echo "1) Python 3.11"
            echo "2) Python 3.12"
            read -p "请输入选项 (1-2): " default_choice
            case $default_choice in
                1) selected_version="3.11" ;;
                2) selected_version="3.12" ;;
                *) handle_error "无效的选项" ;;
            esac
        fi
        ;;
    *)
        handle_error "无效的选项"
        ;;
esac

# 配置Python环境
echo -e "${BLUE}配置Python环境...${NC}"

# 安装python-is-python3包
echo -e "${BLUE}安装python-is-python3包...${NC}"
sudo apt install -y python-is-python3 || handle_error "安装python-is-python3失败"

# 设置选定的Python版本为默认版本
echo -e "${BLUE}设置Python ${selected_version}为默认版本...${NC}"

# 更新alternatives，设置更高的优先级（100）以确保它是默认选项
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${selected_version} 100 || handle_error "设置python3默认版本失败"

# 如果python-is-python3安装失败，手动创建软链接
if [ ! -e /usr/bin/python ]; then
    echo -e "${BLUE}创建python软链接...${NC}"
    sudo ln -sf /usr/bin/python3 /usr/bin/python || handle_error "创建python软链接失败"
fi

# 验证安装
echo -e "${BLUE}验证Python安装...${NC}"
new_version=$(python3 --version 2>&1) || handle_error "无法获取Python版本"
echo -e "${GREEN}Python版本已更新为: $new_version${NC}"

python_version=$(python --version 2>&1) || handle_error "无法获取Python版本"
echo -e "${GREEN}Python命令版本: $python_version${NC}"

# 验证pip安装
pip_version=$(python3 -m pip --version 2>&1) || handle_error "无法获取pip版本"
echo -e "${GREEN}Pip版本: $pip_version${NC}"

# 验证venv
echo -e "${BLUE}验证venv模块...${NC}"
if python3 -m venv --help &>/dev/null; then
    echo -e "${GREEN}venv模块已正确安装${NC}"
else
    echo -e "${RED}警告: venv模块未正确安装，请检查安装${NC}"
fi

echo -e "${GREEN}Python升级和配置完成！${NC}"

# 显示虚拟环境使用说明
echo -e "\n${BLUE}虚拟环境使用说明：${NC}"
echo -e "${GREEN}1. 创建虚拟环境:${NC}"
echo -e "   python -m venv myenv"
echo -e "${GREEN}2. 激活虚拟环境:${NC}"
echo -e "   source myenv/bin/activate"
echo -e "${GREEN}3. 退出虚拟环境:${NC}"
echo -e "   deactivate"

# 显示最终配置信息
echo -e "\n${BLUE}系统Python配置信息：${NC}"
echo -e "${GREEN}Python3 路径: $(which python3)${NC}"
echo -e "${GREEN}Python 路径: $(which python)${NC}"
echo -e "${GREEN}Pip3 路径: $(which pip3)${NC}"
echo -e "${GREEN}Pip 路径: $(which pip)${NC}"

# 如果安装了两个版本，显示所有版本的路径
if [ "$choice" == "3" ]; then
    echo -e "\n${BLUE}已安装的Python版本：${NC}"
    echo -e "${GREEN}Python 3.11 路径: $(which python3.11)${NC}"
    echo -e "${GREEN}Python 3.12 路径: $(which python3.12)${NC}"
fi 