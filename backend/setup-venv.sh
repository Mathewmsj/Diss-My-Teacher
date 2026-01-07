#!/bin/bash

# 使用 Python 3.9 重新创建虚拟环境
# 用于在服务器上设置正确的虚拟环境

echo "=========================================="
echo "使用 Python 3.9 创建虚拟环境"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "当前工作目录: $(pwd)"

# 检查 requirements.txt 是否存在
if [ ! -f "requirements.txt" ]; then
    echo "❌ 错误: 在 $(pwd) 目录下找不到 requirements.txt"
    echo "请确保在 backend 目录下运行此脚本"
    exit 1
fi

echo "找到 requirements.txt: $(pwd)/requirements.txt"

# 检查 python3.9 是否存在
if ! command -v python3.9 > /dev/null 2>&1; then
    echo "❌ 未找到 python3.9"
    echo "请确保已安装 Python 3.9"
    exit 1
fi

echo "找到 Python 3.9:"
python3.9 --version

# 检查是否有旧的虚拟环境
if [ -d "backend-env" ]; then
    echo ""
    echo "发现已存在的虚拟环境 backend-env"
    read -p "是否删除并重新创建? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "删除旧的虚拟环境..."
        rm -rf backend-env
    else
        echo "保留旧虚拟环境，直接退出"
        exit 0
    fi
fi

# 创建新的虚拟环境
echo ""
echo "创建新的虚拟环境（使用 Python 3.9）..."
python3.9 -m venv backend-env

if [ $? -ne 0 ]; then
    echo "❌ 创建虚拟环境失败"
    exit 1
fi

# 激活虚拟环境
echo ""
echo "激活虚拟环境..."
source backend-env/bin/activate

# 升级 pip
echo ""
echo "升级 pip..."
python -m pip install --upgrade pip setuptools wheel

# 安装依赖
echo ""
echo "安装依赖..."
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 虚拟环境设置成功！"
    echo "=========================================="
    echo ""
    echo "Python 版本:"
    python --version
    echo ""
    echo "Django 版本:"
    python -c "import django; print(django.get_version())" 2>/dev/null || echo "Django 未安装"
else
    echo ""
    echo "=========================================="
    echo "❌ 依赖安装失败"
    echo "=========================================="
    exit 1
fi

