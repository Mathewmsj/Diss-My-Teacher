#!/bin/bash

# 修复安装问题的诊断脚本

echo "=========================================="
echo "诊断和修复依赖安装问题"
echo "=========================================="

# 获取项目根目录
if [ -f "start.sh" ]; then
    PROJECT_ROOT="$(pwd)"
elif [ -f "../start.sh" ]; then
    PROJECT_ROOT="$(cd .. && pwd)"
else
    echo "错误: 请在项目目录下运行此脚本"
    exit 1
fi

echo "项目根目录: $PROJECT_ROOT"

# 检查 requirements.txt 位置
REQUIREMENTS_FILE="$PROJECT_ROOT/backend/requirements.txt"
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo ""
    echo "❌ 未找到 requirements.txt 文件"
    echo "预期位置: $REQUIREMENTS_FILE"
    echo ""
    echo "请执行以下步骤:"
    echo "1. 确保在项目根目录: cd /path/to/Diss-My-Teacher"
    echo "2. 更新代码: git pull"
    echo "3. 检查文件: ls -la backend/requirements.txt"
    exit 1
fi

echo "✅ 找到 requirements.txt: $REQUIREMENTS_FILE"

# 进入 backend 目录
cd "$PROJECT_ROOT/backend"
echo "当前目录: $(pwd)"

# 检查虚拟环境
if [ -d "backend-env" ]; then
    VENV_PATH="$(pwd)/backend-env"
elif [ -d "../backend-env" ]; then
    VENV_PATH="$(cd .. && pwd)/backend-env"
else
    echo ""
    echo "❌ 未找到虚拟环境"
    echo "请运行: cd backend && ./setup-venv.sh"
    exit 1
fi

echo "虚拟环境路径: $VENV_PATH"

# 激活虚拟环境
source "$VENV_PATH/bin/activate"

echo ""
echo "=========================================="
echo "当前环境信息"
echo "=========================================="
echo "Python 版本: $(python --version)"
echo "当前目录: $(pwd)"
echo "requirements.txt: $(pwd)/requirements.txt"
echo "文件是否存在: $([ -f requirements.txt ] && echo '是' || echo '否')"

# 列出当前目录文件
echo ""
echo "当前目录文件列表:"
ls -la | grep -E "(requirements|manage.py)"

# 如果 requirements.txt 存在，尝试安装
if [ -f "requirements.txt" ]; then
    echo ""
    echo "=========================================="
    echo "开始安装依赖"
    echo "=========================================="
    
    # 升级 pip
    echo "升级 pip..."
    python -m pip install --upgrade pip setuptools wheel
    
    # 安装依赖
    echo ""
    echo "安装依赖..."
    pip install -r requirements.txt
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "✅ 依赖安装成功！"
        echo "=========================================="
        echo ""
        echo "验证安装:"
        python -c "import django; print('Django 版本:', django.get_version())" 2>/dev/null || echo "❌ Django 未正确安装"
    else
        echo ""
        echo "=========================================="
        echo "❌ 依赖安装失败"
        echo "=========================================="
        exit 1
    fi
else
    echo ""
    echo "❌ 在当前目录找不到 requirements.txt"
    echo "请确保在 backend 目录下运行，并且已执行 git pull"
fi

