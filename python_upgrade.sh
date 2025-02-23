#!/bin/bash
# 升级python版本

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}开始检测当前Python版本...${NC}"

# 检查当前Python版本
current_version=$(python3 --version 2>&1)
echo "当前Python版本: $current_version"

# 检查是否已安装Python 3.12
if command -v python3.12 &> /dev/null; then
    echo -e "${GREEN}Python 3.12 已经安装${NC}"
else
    echo -e "${GREEN}开始安装Python 3.12...${NC}"
    
    # 更新包列表
    sudo apt update
    
    # 安装依赖
    sudo apt install -y software-properties-common
    
    # 添加deadsnakes PPA
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    
    # 更新包列表
    sudo apt update
    
    # 安装Python 3.12 及相关包
    sudo apt install -y python3.12 python3.12-venv
    
    # 安装pip
    curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.12
    
    # 安装setuptools
    sudo python3.12 -m pip install --upgrade setuptools
fi

# 设置Python 3.12为默认Python版本
echo -e "${GREEN}设置Python 3.12为默认版本...${NC}"

# 更新alternatives，设置更高的优先级（100）以确保它是默认选项
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 100
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 100

# 验证安装
new_version=$(python3 --version 2>&1)
echo -e "${GREEN}Python版本已更新为: $new_version${NC}"

# 验证pip安装
pip_version=$(python3 -m pip --version 2>&1)
echo -e "${GREEN}Pip版本: $pip_version${NC}"

echo -e "${GREEN}Python升级和配置完成！${NC}" 