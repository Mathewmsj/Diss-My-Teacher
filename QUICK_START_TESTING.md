# 快速开始 - 本地性能测试

## 快速测试（推荐）

在你的本地电脑上运行：

```bash
# 使用默认配置（1000请求，10并发）
./performance-test-local.sh

# 或者使用简化版本
./test-endpoints-local.sh
```

## 自定义测试

```bash
# 语法：./performance-test-local.sh [后端URL] [请求数] [并发数]
./performance-test-local.sh http://110.40.153.38:5009 2000 20

# 简化版本
./test-endpoints-local.sh 2000 20
```

## 测试结果位置

所有测试结果保存在：`performance-test-results/` 目录

## 说明

- ✅ **可以直接在本地电脑上运行**，不需要上传到服务器
- ✅ **测试远程服务器** `http://110.40.153.38:5009`（后端API地址）
- ✅ **域名 `mathew.yunguhs.com`** 指向前端，但性能测试应该直接测试后端API
- ✅ **需要安装 Apache Benchmark (ab)**：
  - macOS: `brew install httpd`
  - Ubuntu: `sudo apt-get install apache2-utils`
  - CentOS: `sudo yum install httpd-tools`

## 示例输出

```
==========================================
Performance Bottleneck Analysis
Testing Remote Server: http://mathew.yunguhs.com
==========================================

Test Configuration:
  Backend URL: http://110.40.153.38:5009
  Total Requests: 1000
  Concurrency Level: 10

Testing: http://110.40.153.38:5009/healthz
  ✅ Requests per second: 107.89
  ✅ Time per request (ms): 46.344
  ✅ Failed requests: 0

==========================================
Test Summary
==========================================
Endpoint                       |      Req/sec |   Time/req (ms)
/api/ratings/                  |        83.87 |          59.619
/healthz                       |       107.89 |          46.344
/api/teachers/                 |       141.53 |          35.328

Worst Performing Endpoint: /api/ratings/
Average Response Time: 59.619ms
```

## 更多信息

查看 `LOCAL_TESTING.md` 了解详细信息。

