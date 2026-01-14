#!/bin/bash

# 更新服务器代码脚本

echo "=========================================="
echo "更新服务器代码"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo ""
echo "正在从GitHub拉取最新代码..."
git pull origin main

if [ $? -eq 0 ]; then
    echo "✅ 代码更新成功"
    echo ""
    echo "注意：如果前端正在运行，需要重启前端服务才能使用新代码"
    echo "运行: ./restart.sh"
else
    echo "❌ 代码更新失败"
    exit 1
fi

