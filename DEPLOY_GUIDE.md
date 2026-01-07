# 🚀 部署指南

根据 [部署教程](https://static.yunguhs.com/tutorials/deploy/) 的完整部署步骤

## 快速部署（推荐）

在服务器上执行一条命令即可完成所有部署：

```bash
cd Diss-My-Teacher
git pull
chmod +x auto-deploy.sh
./auto-deploy.sh 5007 5008
```

## 详细部署步骤

### 1. SSH 登录服务器

```bash
ssh mathew@110.40.153.38
```

**密码格式**：`Mathew@学号`（注意首字母大写）

### 2. 从 GitHub 下载代码

如果还没有下载代码：

```bash
git clone https://ghfast.top/https://github.com/Mathewmsj/Diss-My-Teacher.git
cd Diss-My-Teacher
```

如果已经下载，更新代码：

```bash
cd Diss-My-Teacher
git pull
```

### 3. 运行自动化部署脚本

```bash
chmod +x auto-deploy.sh
./auto-deploy.sh 5007 5008
```

这个脚本会自动完成：
- ✅ 拉取最新代码
- ✅ 停止旧服务
- ✅ 清理端口占用
- ✅ 安装前端依赖（npm install）
- ✅ 创建 Python 虚拟环境
- ✅ 安装后端依赖（Django 4.2.7）
- ✅ 执行数据库迁移
- ✅ 启动服务

### 4. 通过浏览器访问

部署完成后，可以通过以下方式访问：

#### 方式 A：IP 直接访问（端口 5000-5010）

- **前端**：`http://110.40.153.38:5008`
- **后端 API**：`http://110.40.153.38:5007/api`

#### 方式 B：域名访问（推荐）

- **前端**：`http://mathew.yunguhs.com` 或 `https://mathew.yunguhs.com`
- **后端 API**：`http://mathew.yunguhs.com/api`

**注意**：使用域名访问时，需要将应用运行在端口 **8806**（后端）和 **8807**（前端）：

```bash
./auto-deploy.sh 8806 8807
```

## 端口说明

### IP 直接访问
- 端口范围：**5000-5010**（防火墙允许的范围）
- 当前配置：后端 5007，前端 5008

### 域名访问（mathew）
- 后端端口：**8806**
- 前端端口：**8807**
- 域名：`mathew.yunguhs.com`

## 常用命令

### 查看服务状态
```bash
./check.sh
```

### 查看日志
```bash
# 后端日志
tail -f backend.log

# 前端日志
tail -f frontend.log
```

### 停止服务
```bash
./stop.sh
```

### 重启服务
```bash
./stop.sh
./start.sh 5007 5008
# 或使用域名端口
./start.sh 8806 8807
```

## 故障排除

### 问题 1：端口被占用

```bash
# 检查端口占用
lsof -i :5007
lsof -i :5008

# 停止占用端口的进程
kill -9 <进程ID>
```

### 问题 2：服务无法访问

1. **检查服务是否运行**：
   ```bash
   ps aux | grep -E "python.*manage.py|node.*vite"
   ```

2. **检查端口是否监听**：
   ```bash
   lsof -i :5007
   lsof -i :5008
   ```

3. **检查日志**：
   ```bash
   tail -50 backend.log
   tail -50 frontend.log
   ```

### 问题 3：依赖安装失败

```bash
# 删除虚拟环境重新创建
cd backend
rm -rf backend-env
python3 -m venv backend-env
source backend-env/bin/activate
pip install -r requirements.txt
cd ..
```

### 问题 4：前端无法访问后端

确保前端 API 地址配置正确。启动脚本会自动设置：
```
VITE_API_BASE="http://110.40.153.38:后端端口/api"
```

## 验证部署

部署成功后，应该能够：

1. ✅ 在浏览器中打开前端页面
2. ✅ 看到登录/注册界面
3. ✅ 前端能正常调用后端 API
4. ✅ 所有功能正常工作

## 注意事项

1. **监听地址**：应用已配置为监听 `0.0.0.0`，可以从外部访问
2. **端口范围**：IP 访问必须在 5000-5010 之间
3. **域名访问**：mathew 的域名端口是 8806（后端）和 8807（前端）
4. **后台运行**：使用 `nohup` 和 `&` 让服务在后台运行，即使退出 SSH 也不会停止

## 完成！

恭喜你完成了部署！如果遇到任何问题，请查看日志文件或运行 `./check.sh` 进行诊断。

