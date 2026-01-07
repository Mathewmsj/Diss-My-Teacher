#!/bin/bash

# 依赖安装脚本
# 用于在服务器上安装 Python 依赖

echo "=========================================="
echo "安装 Python 依赖"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查虚拟环境
if [ -d "backend-env" ]; then
    VENV_PATH="$(pwd)/backend-env"
elif [ -d "../backend-env" ]; then
    VENV_PATH="$(cd .. && pwd)/backend-env"
else
    echo "错误: 未找到虚拟环境"
    exit 1
fi

echo "虚拟环境路径: $VENV_PATH"

# 激活虚拟环境
source "$VENV_PATH/bin/activate"

# 检查 Python 版本
echo ""
echo "Python 版本:"
python --version

# 检查 pip 版本
echo ""
echo "当前 pip 版本:"
pip --version

# 升级 pip
echo ""
echo "升级 pip..."
python -m pip install --upgrade pip

# 安装依赖
echo ""
echo "安装依赖..."
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 依赖安装成功！"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "❌ 依赖安装失败！"
    echo "=========================================="
    echo ""
    echo "如果 Django 4.2.7 安装失败，可以尝试使用兼容版本:"
    echo "  pip install -r requirements-compat.txt"
    exit 1
fi

