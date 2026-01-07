#!/bin/bash

# 简化的迁移脚本 - 使用 Django dumpdata/loaddata

echo "=========================================="
echo "从 Render 数据库迁移到本地数据库"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 激活虚拟环境
if [ -d "backend-env" ]; then
    source backend-env/bin/activate
elif [ -d "../backend-env" ]; then
    source ../backend-env/bin/activate
else
    echo "❌ 未找到虚拟环境"
    exit 1
fi

# 检查 DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
    echo ""
    echo "请设置 Render 数据库连接字符串："
    echo "export DATABASE_URL='postgresql://user:password@host:port/dbname'"
    echo ""
    read -p "请输入 DATABASE_URL: " DATABASE_URL
    export DATABASE_URL
fi

echo ""
echo "步骤1: 从 Render 导出数据"
echo "=========================================="
python manage.py dumpdata --exclude auth.permission --exclude contenttypes --indent 2 > render_data.json

if [ $? -ne 0 ]; then
    echo "❌ 导出失败，请检查 DATABASE_URL 是否正确"
    exit 1
fi

echo "✅ 数据已导出到: render_data.json"

echo ""
echo "步骤2: 备份本地数据库"
echo "=========================================="
if [ -f "db.sqlite3" ]; then
    BACKUP_FILE="db.sqlite3.backup_$(date +%Y%m%d_%H%M%S)"
    cp db.sqlite3 "$BACKUP_FILE"
    echo "✅ 已备份到: $BACKUP_FILE"
fi

echo ""
echo "步骤3: 切换到本地数据库并导入数据"
echo "=========================================="

# 切换到本地数据库
unset DATABASE_URL

# 运行迁移
echo "运行数据库迁移..."
python manage.py migrate

# 清空现有数据（可选）
read -p "是否清空现有数据? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python manage.py flush --noinput
fi

# 导入数据
echo ""
echo "导入数据..."
python manage.py loaddata render_data.json

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 迁移完成！"
    echo "=========================================="
    echo ""
    echo "数据文件: render_data.json"
    if [ -f "$BACKUP_FILE" ]; then
        echo "备份文件: $BACKUP_FILE"
    fi
else
    echo ""
    echo "❌ 导入失败，请检查错误信息"
    exit 1
fi

