#!/bin/bash

# 从 Render 数据库迁移到服务器本地数据库的脚本

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

echo ""
echo "步骤1: 检查数据库配置"
echo "=========================================="

# 检查是否有 DATABASE_URL 环境变量
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  未设置 DATABASE_URL 环境变量"
    echo ""
    echo "请设置 Render 数据库连接字符串："
    echo "export DATABASE_URL='postgresql://user:password@host:port/dbname'"
    echo ""
    read -p "是否现在输入 DATABASE_URL? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入 DATABASE_URL: " DATABASE_URL
        export DATABASE_URL
    else
        echo "❌ 需要 DATABASE_URL 才能继续"
        exit 1
    fi
fi

echo "✅ DATABASE_URL 已设置"

echo ""
echo "步骤2: 导出 Render 数据库数据"
echo "=========================================="

# 检查是否安装了 pg_dump
if ! command -v pg_dump > /dev/null 2>&1; then
    echo "⚠️  未找到 pg_dump，尝试安装..."
    if command -v yum > /dev/null 2>&1; then
        sudo yum install -y postgresql 2>/dev/null || echo "需要手动安装 postgresql 客户端"
    elif command -v apt-get > /dev/null 2>&1; then
        sudo apt-get install -y postgresql-client 2>/dev/null || echo "需要手动安装 postgresql-client"
    fi
fi

# 导出数据
EXPORT_FILE="render_export_$(date +%Y%m%d_%H%M%S).sql"
echo "正在导出数据到: $EXPORT_FILE"

# 使用 Django 的数据库连接信息
python << EOF
import os
import dj_database_url
import subprocess

db_url = os.getenv('DATABASE_URL')
if not db_url:
    print("❌ DATABASE_URL 未设置")
    exit(1)

db_config = dj_database_url.parse(db_url)

# 构建 pg_dump 命令
pg_dump_cmd = [
    'pg_dump',
    '-h', db_config['HOST'],
    '-p', str(db_config['PORT']),
    '-U', db_config['USER'],
    '-d', db_config['NAME'],
    '-F', 'c',  # 自定义格式
    '-f', '$EXPORT_FILE'
]

# 设置密码环境变量
env = os.environ.copy()
env['PGPASSWORD'] = db_config['PASSWORD']

print(f"正在连接: {db_config['HOST']}:{db_config['PORT']}/{db_config['NAME']}")
result = subprocess.run(pg_dump_cmd, env=env, capture_output=True, text=True)

if result.returncode == 0:
    print(f"✅ 数据导出成功: $EXPORT_FILE")
else:
    print(f"❌ 导出失败: {result.stderr}")
    exit(1)
EOF

if [ $? -ne 0 ]; then
    echo "❌ 数据导出失败"
    exit 1
fi

echo ""
echo "步骤3: 备份本地数据库（如果存在）"
echo "=========================================="

if [ -f "db.sqlite3" ]; then
    BACKUP_FILE="db.sqlite3.backup_$(date +%Y%m%d_%H%M%S)"
    cp db.sqlite3 "$BACKUP_FILE"
    echo "✅ 本地数据库已备份到: $BACKUP_FILE"
else
    echo "ℹ️  本地数据库不存在，无需备份"
fi

echo ""
echo "步骤4: 导入数据到本地 SQLite 数据库"
echo "=========================================="

echo "⚠️  注意: 从 PostgreSQL 迁移到 SQLite 需要数据转换"
echo ""
read -p "是否继续? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 使用 Django 的 dumpdata 和 loaddata（更可靠的方法）
echo ""
echo "方法1: 使用 Django dumpdata/loaddata（推荐）"
echo "----------------------------------------"

# 临时设置使用 Render 数据库
export DATABASE_URL
python manage.py dumpdata --exclude auth.permission --exclude contenttypes > render_data.json

if [ $? -eq 0 ]; then
    echo "✅ 数据导出成功: render_data.json"
    
    # 切换到本地数据库
    unset DATABASE_URL
    
    # 运行迁移
    echo ""
    echo "运行数据库迁移..."
    python manage.py migrate
    
    # 导入数据
    echo ""
    echo "导入数据到本地数据库..."
    python manage.py loaddata render_data.json
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "✅ 迁移完成！"
        echo "=========================================="
        echo ""
        echo "数据文件:"
        echo "  - render_data.json (Django 格式)"
        echo "  - $EXPORT_FILE (PostgreSQL 格式)"
        if [ -f "$BACKUP_FILE" ]; then
            echo "  - $BACKUP_FILE (本地数据库备份)"
        fi
        echo ""
        echo "现在可以使用本地 SQLite 数据库了"
    else
        echo "❌ 数据导入失败"
        exit 1
    fi
else
    echo "❌ 数据导出失败"
    exit 1
fi

