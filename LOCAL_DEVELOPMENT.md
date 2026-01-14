# 本地开发部署指南

## 快速开始

### 1. 启动服务

```bash
# 使用默认端口（后端8000，前端5173）
./start-local.sh

# 或自定义端口
./start-local.sh 8000 5173
```

### 2. 访问应用

- **前端**: http://localhost:5173
- **后端API**: http://localhost:8000/api
- **后端管理**: http://localhost:8000/admin

### 3. 停止服务

```bash
./stop-local.sh
```

## 前提条件

### 已安装的依赖

✅ Python 3.9+
✅ Node.js 和 npm
✅ 后端虚拟环境 (backend-env)
✅ 前端依赖 (node_modules)

### 如果缺少依赖

**创建后端虚拟环境：**
```bash
cd backend
python3 -m venv backend-env
source backend-env/bin/activate  # macOS/Linux
pip install -r requirements.txt
```

**安装前端依赖：**
```bash
npm install
```

## 配置说明

### 后端端口
- 默认: `8000` (Django 开发服务器标准端口)
- 可自定义: `./start-local.sh 3000 5173`

### 前端端口
- 默认: `5173` (Vite 开发服务器标准端口)
- 可自定义: `./start-local.sh 8000 3000`

### API 配置

前端会自动检测本地开发环境，使用 `http://localhost:8000/api` 作为 API 地址。

如果后端使用不同端口，需要：
1. 设置环境变量: `export VITE_API_BASE=http://localhost:YOUR_PORT/api`
2. 或修改 `src/api.js` 中的 `getApiBase()` 函数

## 查看日志

```bash
# 后端日志
tail -f backend.log

# 前端日志
tail -f frontend.log

# 实时查看两个日志
tail -f backend.log frontend.log
```

## 数据库

本地使用 SQLite 数据库：
- 位置: `backend/db.sqlite3`
- 迁移: 脚本会自动运行 `migrate`
- 重置数据库: 删除 `backend/db.sqlite3` 并重新运行迁移

## 常见问题

### 端口被占用

```bash
# 查看端口占用
lsof -i :8000
lsof -i :5173

# 手动停止
kill -9 <PID>
```

### 后端启动失败

1. 检查虚拟环境: `source backend/backend-env/bin/activate`
2. 检查依赖: `pip list`
3. 查看日志: `tail -20 backend.log`
4. 运行迁移: `cd backend && python manage.py migrate`

### 前端启动失败

1. 检查 Node 版本: `node --version` (需要 v14+)
2. 检查依赖: `npm list`
3. 查看日志: `tail -20 frontend.log`
4. 重新安装: `rm -rf node_modules package-lock.json && npm install`

### API 请求失败

1. 确认后端正在运行: `curl http://localhost:8000/healthz`
2. 检查 API 地址配置: 查看 `src/api.js`
3. 检查浏览器控制台的错误信息

## 开发提示

### 热重载

- **前端**: Vite 支持热模块替换 (HMR)，修改代码后自动刷新
- **后端**: Django 开发服务器支持自动重载，修改 Python 代码后自动重启

### 调试

- **前端**: 使用浏览器开发者工具 (F12)
- **后端**: 查看 `backend.log` 文件

### 数据库管理

```bash
cd backend
source backend-env/bin/activate
python manage.py shell  # Django shell
python manage.py dbshell  # SQLite shell
python manage.py createsuperuser  # 创建管理员
```

## 与服务器部署的区别

| 项目 | 本地开发 | 服务器部署 |
|------|---------|-----------|
| 后端地址 | 127.0.0.1:8000 | 0.0.0.0:5009 |
| 前端地址 | localhost:5173 | 0.0.0.0:8806 |
| 监听接口 | 127.0.0.1 | 0.0.0.0 (所有接口) |
| 启动脚本 | start-local.sh | start.sh |
| 停止脚本 | stop-local.sh | stop.sh |

