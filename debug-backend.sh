#!/bin/bash

# 后端调试脚本

echo "=========================================="
echo "后端调试信息"
echo "=========================================="

# 获取项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "项目根目录: $SCRIPT_DIR"
echo ""

# 1. 检查端口占用
echo "1. 检查端口5000占用情况:"
if command -v lsof > /dev/null 2>&1; then
    lsof -i:5000 2>/dev/null || echo "端口5000未被占用"
else
    netstat -tulnp 2>/dev/null | grep ":5000 " || echo "端口5000未被占用"
fi
echo ""

# 2. 检查后端日志
echo "2. 后端日志（最后20行）:"
if [ -f "backend.log" ]; then
    tail -n 20 backend.log
else
    echo "❌ 未找到 backend.log 文件"
fi
echo ""

# 3. 检查虚拟环境
echo "3. 检查虚拟环境:"
cd backend
if [ -d "backend-env" ]; then
    VENV_PATH="$(pwd)/backend-env"
    echo "虚拟环境路径: $VENV_PATH"
    source "$VENV_PATH/bin/activate"
    echo "Python 版本: $(python --version)"
    echo "Django 版本: $(python -c 'import django; print(django.get_version())' 2>/dev/null || echo '未安装')"
else
    echo "❌ 未找到虚拟环境"
fi
echo ""

# 4. 尝试手动启动（测试）
echo "4. 测试手动启动后端（5秒后自动停止）:"
echo "运行命令: python manage.py runserver 0.0.0.0:5000"
echo ""
timeout 5 python manage.py runserver 0.0.0.0:5000 2>&1 || echo "启动测试完成"
echo ""

cd ..

echo "=========================================="
echo "调试完成"
echo "=========================================="

