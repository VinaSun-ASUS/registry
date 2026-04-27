# 服务器快速启动 - 一页纸命令参考

## 🚀 三步启动

```bash
# 1. Clone 项目
git clone https://github.com/modelcontextprotocol/registry.git && cd registry

# 2. 启动服务（包含数据库）
make dev-compose

# 3. 测试（等待 30 秒后运行）
curl http://localhost:8080/v0.1/ping
```

## 🎯 一键测试所有功能

```bash
# 赋予执行权限并运行
chmod +x quick-test.sh && ./quick-test.sh
```

## 📝 常用 API 测试命令

### 基础测试

```bash
# Ping
curl http://localhost:8080/v0.1/ping

# 健康检查
curl http://localhost:8080/v0/health

# 列出所有 servers（美化输出）
curl -s http://localhost:8080/v0.1/servers | jq .

# 只显示 server 名称
curl -s http://localhost:8080/v0.1/servers | jq '.servers[].name'
```

### 搜索和过滤

```bash
# 搜索 Figma
curl -s "http://localhost:8080/v0.1/servers?search=figma" | jq .

# 限制返回数量
curl -s "http://localhost:8080/v0.1/servers?limit=5" | jq .

# 只返回最新版本
curl -s "http://localhost:8080/v0.1/servers?version=latest&limit=5" | jq .

# 组合条件：搜索 + 最新版本
curl -s "http://localhost:8080/v0.1/servers?search=airtable&version=latest" | jq .
```

### 获取特定 Server

```bash
# 获取 Airtable server 的最新版本
curl -s "http://localhost:8080/v0.1/servers/io.github.domdomegg%2Fairtable-mcp-server/versions/latest" | jq .

# 获取所有版本
curl -s "http://localhost:8080/v0.1/servers/io.github.domdomegg%2Fairtable-mcp-server/versions" | jq .

# 获取特定版本
curl -s "http://localhost:8080/v0.1/servers/io.github.domdomegg%2Fairtable-mcp-server/versions/1.7.3" | jq .
```

**注意**: Server 名称中的 `/` 需要编码为 `%2F`

### 测试 CORS

```bash
# 查看 CORS headers
curl -I -X OPTIONS \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: GET" \
  http://localhost:8080/v0.1/servers
```

## 🎨 查看 JSON 格式

### 完整 Server 对象示例

```bash
# 获取一个完整的 server JSON
curl -s "http://localhost:8080/v0.1/servers?limit=1" | jq '.servers[0]' > example-server.json

# 查看文件
cat example-server.json
```

**典型 JSON 结构**:
```json
{
  "name": "io.github.domdomegg/airtable-mcp-server",
  "version": "1.7.3",
  "description": "Read and write access to Airtable...",
  "packages": [
    {
      "registryType": "npm",
      "identifier": "airtable-mcp-server",
      "version": "1.7.3",
      "runtimeHint": "npx",
      "transport": { "type": "stdio" },
      "environmentVariables": [...]
    }
  ],
  "repository": {
    "url": "https://github.com/domdomegg/airtable-mcp-server.git",
    "source": "github"
  },
  "meta": {
    "official": {
      "publishedAt": "2025-08-07T13:15:04.280Z",
      "isLatest": true
    }
  }
}
```

### 提取特定字段

```bash
# 只显示 name 和 version
curl -s http://localhost:8080/v0.1/servers | jq '.servers[] | {name, version}'

# 显示所有 package types
curl -s http://localhost:8080/v0.1/servers | jq '.servers[].packages[].registryType' | sort -u

# 显示有多少个 servers
curl -s http://localhost:8080/v0.1/servers | jq '.metadata.count'
```

## 🔧 配置白名单（只允许 Figma）

```bash
# 方法 1: 环境变量（临时）
export MCP_REGISTRY_ALLOWED_SERVERS="io.figma/mcp-server"
docker-compose down && docker-compose up -d

# 方法 2: 使用配置文件
cp .env.private-figma-only .env
make dev-compose

# 方法 3: 直接修改 docker-compose.yml
# 在 registry 服务的 environment 中添加:
# - MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server
```

## 📊 服务管理

```bash
# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f registry

# 重启服务
docker-compose restart registry

# 停止服务
docker-compose down

# 停止并删除数据
docker-compose down -v
```

## 🐛 快速诊断

```bash
# 检查服务是否运行
curl -f http://localhost:8080/v0.1/ping && echo "✓ 服务正常" || echo "✗ 服务异常"

# 检查数据库连接
docker-compose exec postgres pg_isready -U mcpregistry

# 查看最近的错误日志
docker-compose logs --tail=50 registry | grep -i error

# 测试 v0.1 端点是否可访问
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/v0.1/servers
```

## 📱 浏览器访问

```bash
# 在浏览器中打开（macOS）
open http://localhost:8080/docs

# Linux
xdg-open http://localhost:8080/docs

# Windows (WSL)
explorer.exe http://localhost:8080/docs
```

或直接访问:
- **API 文档**: http://localhost:8080/docs
- **OpenAPI JSON**: http://localhost:8080/openapi.json
- **健康检查**: http://localhost:8080/v0/health

## 💾 保存测试结果

```bash
# 保存所有 servers 到文件
curl -s http://localhost:8080/v0.1/servers > all-servers.json

# 保存特定搜索结果
curl -s "http://localhost:8080/v0.1/servers?search=figma" > figma-servers.json

# 生成可读的文本报告
curl -s http://localhost:8080/v0.1/servers | jq -r '.servers[] | "\(.name) - v\(.version)"' > servers-list.txt
```

## 🔍 URL 编码工具

如果需要测试包含特殊字符的 server name:

```bash
# 使用 Python
python3 -c "import urllib.parse; print(urllib.parse.quote('io.figma/mcp-server'))"

# 使用 Node.js
node -e "console.log(encodeURIComponent('io.figma/mcp-server'))"

# 或在线工具
# https://www.urlencoder.org/
```

常见字符编码:
- `/` → `%2F`
- `@` → `%40`
- `#` → `%23`
- `?` → `%3F`

## 📚 更多信息

- 详细指南: [SERVER_QUICK_START.md](SERVER_QUICK_START.md)
- 白名单配置: [PRIVATE_REGISTRY_SETUP.md](PRIVATE_REGISTRY_SETUP.md)
- API 规范: [REGISTRY_COMPLIANCE.md](REGISTRY_COMPLIANCE.md)
- 完整文档: [README.md](README.md)
