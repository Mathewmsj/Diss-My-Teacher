#!/bin/bash

# 快速修复脚本 - 检查并创建虚拟环境

echo "=========================================="
echo "快速修复虚拟环境"
echo "=========================================="

# 获取项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "项目根目录: $SCRIPT_DIR"

# 检查虚拟环境位置
cd backend

if [ -d "backend-env" ]; then
    echo "✅ 找到虚拟环境: $(pwd)/backend-env"
    VENV_PATH="$(pwd)/backend-env"
elif [ -d "../backend-env" ]; then
    echo "✅ 找到虚拟环境: $(cd .. && pwd)/backend-env"
    VENV_PATH="$(cd .. && pwd)/backend-env"
else
    echo "❌ 未找到虚拟环境"
    echo ""
    echo "正在创建虚拟环境..."
    
    # 检查 python3.9
    if ! command -v python3.9 > /dev/null 2>&1; then
        echo "❌ 未找到 python3.9"
        echo "请确保已安装 Python 3.9"
        exit 1
    fi
    
    # 创建虚拟环境
    python3.9 -m venv backend-env
    
    if [ $? -ne 0 ]; then
        echo "❌ 创建虚拟环境失败"
        exit 1
    fi
    
    echo "✅ 虚拟环境创建成功"
    VENV_PATH="$(pwd)/backend-env"
fi

# 激活虚拟环境
echo ""
echo "激活虚拟环境..."
source "$VENV_PATH/bin/activate"

# 检查 Python 版本
PYTHON_VERSION=$(python --version 2>&1)
echo "Python 版本: $PYTHON_VERSION"

# 检查 Django 是否安装
if ! python -c "import django" 2>/dev/null; then
    echo ""
    echo "Django 未安装，正在安装依赖..."
    
    # 升级 pip
    python -m pip install --upgrade pip setuptools wheel
    
    # 安装依赖
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        echo "❌ 未找到 requirements.txt"
        exit 1
    fi
    
    # 验证安装
    python -c "import django; print('Django 版本:', django.get_version())" 2>/dev/null || {
        echo "❌ Django 安装失败"
        exit 1
    }
else
    echo "✅ Django 已安装"
    python -c "import django; print('Django 版本:', django.get_version())"
fi

cd ..

echo ""
echo "=========================================="
echo "✅ 修复完成！"
echo "=========================================="
echo ""
echo "现在可以启动服务:"
echo "  ./start.sh"
echo ""

