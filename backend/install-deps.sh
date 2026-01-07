#!/bin/bash

# 依赖安装脚本
# 用于在服务器上安装 Python 依赖

echo "=========================================="
echo "安装 Python 依赖"
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

# 检查 Python 版本（尝试多种方式）
echo ""
echo "检查 Python 版本:"
if command -v python3.9 > /dev/null 2>&1; then
    PYTHON_CMD="python3.9"
    echo "找到 python3.9:"
    $PYTHON_CMD --version
elif command -v python3 > /dev/null 2>&1; then
    PYTHON_CMD="python3"
    echo "找到 python3:"
    $PYTHON_CMD --version
else
    PYTHON_CMD="python"
    echo "使用 python:"
    $PYTHON_CMD --version
fi

# 检查 pip 版本
echo ""
echo "当前 pip 版本:"
pip --version

# 升级 pip（使用找到的 Python 命令）
echo ""
echo "升级 pip..."
$PYTHON_CMD -m pip install --upgrade pip setuptools wheel

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

