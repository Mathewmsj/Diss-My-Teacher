#!/bin/bash

# 修复所有问题的脚本

echo "=========================================="
echo "修复部署问题"
echo "=========================================="

# 获取项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "项目根目录: $SCRIPT_DIR"

# 1. 停止现有服务
echo ""
echo "1. 停止现有服务..."
./stop.sh 2>/dev/null || true
kill $(cat backend.pid frontend.pid 2>/dev/null) 2>/dev/null || true

# 2. 检查并使用 Python 3.9 重新创建虚拟环境
echo ""
echo "2. 检查虚拟环境..."

cd backend

# 检查当前虚拟环境的 Python 版本
if [ -d "backend-env" ]; then
    CURRENT_PYTHON_VERSION=$("$(pwd)/backend-env/bin/python" --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    echo "当前虚拟环境 Python 版本: $CURRENT_PYTHON_VERSION"
    
    if [ "$CURRENT_PYTHON_VERSION" != "3.9" ]; then
        echo "⚠️  虚拟环境使用的是 Python $CURRENT_PYTHON_VERSION，需要 Python 3.9"
        echo "删除旧虚拟环境..."
        rm -rf backend-env
    fi
fi

# 如果虚拟环境不存在或已删除，重新创建
if [ ! -d "backend-env" ]; then
    echo ""
    echo "使用 Python 3.9 创建新虚拟环境..."
    
    if ! command -v python3.9 > /dev/null 2>&1; then
        echo "❌ 未找到 python3.9"
        echo "请确保已安装 Python 3.9"
        exit 1
    fi
    
    python3.9 -m venv backend-env
    
    if [ $? -ne 0 ]; then
        echo "❌ 创建虚拟环境失败"
        exit 1
    fi
    
    echo "✅ 虚拟环境创建成功"
fi

# 3. 激活虚拟环境并安装依赖
echo ""
echo "3. 安装依赖..."

source backend-env/bin/activate

# 验证 Python 版本
PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "虚拟环境 Python 版本: $PYTHON_VERSION"

if [ "$PYTHON_VERSION" != "3.9" ]; then
    echo "⚠️  警告: 虚拟环境不是 Python 3.9，可能存在问题"
fi

# 升级 pip
echo "升级 pip..."
python -m pip install --upgrade pip setuptools wheel

# 安装依赖
if [ -f "requirements.txt" ]; then
    echo "安装依赖..."
    pip install -r requirements.txt
else
    echo "❌ 未找到 requirements.txt"
    exit 1
fi

# 验证 Django 安装
echo ""
echo "验证 Django 安装..."
python -c "import django; print('Django 版本:', django.get_version())" 2>/dev/null || {
    echo "❌ Django 未正确安装"
    exit 1
}

cd ..

# 4. 修复前端 ENOSPC 问题（文件监控限制）
echo ""
echo "4. 修复前端文件监控限制..."

# 增加 inotify 限制（临时，重启后失效）
if command -v sysctl > /dev/null 2>&1; then
    echo "增加文件监控限制..."
    sudo sysctl -w fs.inotify.max_user_watches=524288 2>/dev/null || echo "需要 root 权限来修改系统限制"
fi

# 5. 提示启动服务
echo ""
echo "=========================================="
echo "✅ 修复完成！"
echo "=========================================="
echo ""
echo "现在可以启动服务:"
echo "  ./start.sh           # 使用默认端口 5000/5010"
echo "  ./start.sh 8806 8807 # 使用域名端口"
echo ""

