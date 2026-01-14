# 本地性能测试说明

## 概述

这个文档说明如何在本地电脑上测试远程服务器 `http://mathew.yunguhs.com` 的性能。

## 注意事项

- **域名 `mathew.yunguhs.com`** 指向前端（端口 8806）
- **后端API** 地址为：`http://110.40.153.38:5009`
- 性能测试应该直接测试后端API，因为前端只是静态文件服务

## 安装 Apache Benchmark

### macOS
```bash
brew install httpd
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install apache2-utils
```

### Linux (CentOS/RHEL)
```bash
sudo yum install httpd-tools
```

## 使用方法

### 方法1: 使用完整测试脚本（推荐）

```bash
# 使用默认配置（1000请求，10并发）
./performance-test-local.sh

# 自定义配置
./performance-test-local.sh http://110.40.153.38:5009 2000 20
```

### 方法2: 使用简化测试脚本

```bash
# 默认：1000请求，10并发
./test-endpoints-local.sh

# 自定义：2000请求，20并发
./test-endpoints-local.sh 2000 20
```

### 方法3: 直接使用 ab 命令

```bash
# 测试健康检查端点
ab -n 1000 -c 10 http://110.40.153.38:5009/healthz

# 测试教师列表端点
ab -n 1000 -c 10 http://110.40.153.38:5009/api/teachers/

# 测试评分列表端点
ab -n 1000 -c 10 http://110.40.153.38:5009/api/ratings/
```

## 测试结果

测试结果会保存在 `performance-test-results/` 目录中：
- 每个端点的详细结果文件
- 汇总报告文件
- TSV格式的数据文件（可用于绘图）

## 解释测试结果

### 关键指标

1. **Requests per second (请求/秒)**
   - 越高越好
   - 表示服务器每秒能处理的请求数

2. **Time per request (平均响应时间)**
   - 越低越好
   - 单位：毫秒(ms)
   - 表示每个请求的平均处理时间

3. **Failed requests (失败请求数)**
   - 应该是 0
   - 如果有失败请求，需要检查服务器状态

4. **Time taken for tests (总耗时)**
   - 单位：秒
   - 完成所有请求的总时间

### 示例输出

```
Requests per second:    245.67 [#/sec] (mean)
Time per request:       40.704 [ms] (mean)
Failed requests:        0
Time taken for tests:   4.071 seconds
```

## 测试建议

1. **先进行小规模测试**：使用较少的请求数（如100-500）先测试
2. **逐步增加负载**：根据服务器响应情况逐步增加请求数和并发数
3. **多次测试取平均**：性能测试结果可能有波动，建议多次测试取平均值
4. **注意服务器资源**：不要对生产服务器进行过于激进的测试

## 常见问题

### Q: 为什么测试后端而不是域名？
A: 域名指向前端（Vite开发服务器），性能测试应该直接测试后端API的性能瓶颈。

### Q: 测试失败怎么办？
A: 
1. 检查网络连接
2. 确认后端服务正在运行
3. 检查防火墙设置
4. 查看后端日志

### Q: 如何查看详细结果？
A: 查看 `performance-test-results/` 目录中的详细输出文件。

