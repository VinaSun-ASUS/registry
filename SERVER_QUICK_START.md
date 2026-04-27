# 快速启动指南 - 在服务器上运行 MCP Registry

本指南帮助你在服务器上快速 clone、启动并测试 MCP Registry。

## 📋 前置要求

确保服务器上已安装：
- **Docker** 和 **Docker Compose**
- **Git**
- **curl** (用于测试 API)
- **jq** (可选，用于美化 JSON 输出)

## 🚀 步骤 1: Clone 项目

```bash
# Clone 项目
git clone https://github.com/modelcontextprotocol/registry.git
cd registry
```

## 🔧 步骤 2: 配置环境变量（可选）

### 选项 A: 使用默认配置（推荐新手）

不需要任何配置，直接使用默认设置即可。

### 选项 B: 配置 Figma 专用白名单

如果要限制只允许访问 Figma MCP Server：

```bash
# 复制配置模板
cp .env.private-figma-only .env

# 编辑配置（可选）
nano .env

# 设置白名单
export MCP_REGISTRY_ALLOWED_SERVERS="io.figma/mcp-server"
```

### 选项 C: 自定义配置

```bash
# 创建自定义配置
cat > .env.local << 'EOF'
MCP_REGISTRY_DATABASE_URL=postgres://mcpregistry:mcpregistry@postgres:5432/mcp-registry
MCP_REGISTRY_SEED_FROM=https://registry.modelcontextprotocol.io/v0/servers
MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server
EOF

# 使用自定义配置
export $(cat .env.local | xargs)
```

## 🏃 步骤 3: 启动服务

```bash
# 使用 make 命令启动（推荐）
make dev-compose

# 或者直接使用 docker-compose
docker-compose up -d

# 查看日志
docker-compose logs -f registry
```

启动过程会：
1. 构建 registry Docker 镜像
2. 启动 PostgreSQL 数据库
3. 运行数据库迁移
4. 从生产环境导入种子数据
5. 启动 API 服务器在 http://localhost:8080

**等待时间**: 首次启动约 30-60 秒（需要下载镜像和构建）

## ✅ 步骤 4: 验证服务已启动

```bash
# 检查服务状态
docker-compose ps

# 测试 ping 端点
curl http://localhost:8080/v0.1/ping

# 应该返回: {"message":"pong"}
```

## 🧪 步骤 5: 测试 API 并查看 JSON

### 测试 1: 列出所有 servers

```bash
# 基本请求
curl http://localhost:8080/v0.1/servers

# 美化输出（需要安装 jq）
curl -s http://localhost:8080/v0.1/servers | jq .

# 保存到文件
curl -s http://localhost:8080/v0.1/servers > servers.json
```

**返回格式示例**:
```json
{
  "servers": [
    {
      "name": "io.github.domdomegg/airtable-mcp-server",
      "version": "1.7.3",
      "description": "Read and write access to Airtable database schemas, tables, and records.",
      "packages": [...],
      "repository": {...},
      "meta": {
        "official": {
          "publishedAt": "2025-08-07T13:15:04.280Z",
          "isLatest": true
        }
      }
    }
  ],
  "metadata": {
    "nextCursor": "...",
    "count": 30
  }
}
```

### 测试 2: 搜索特定 server（如 Figma）

```bash
# 搜索 Figma
curl -s "http://localhost:8080/v0.1/servers?search=figma" | jq .

# 只返回最新版本
curl -s "http://localhost:8080/v0.1/servers?version=latest&search=figma" | jq .
```

### 测试 3: 获取特定 server 的最新版本

```bash
# 需要 URL 编码 server name (斜杠 / 变成 %2F)
curl -s "http://localhost:8080/v0.1/servers/io.figma%2Fmcp-server/versions/latest" | jq .

# 或使用 --url-encode (需要较新版本的 curl)
curl -s --get \
  --data-urlencode "serverName=io.figma/mcp-server" \
  "http://localhost:8080/v0.1/servers/io.figma%2Fmcp-server/versions/latest" | jq .
```

**返回格式示例**:
```json
{
  "name": "io.figma/mcp-server",
  "version": "1.0.0",
  "description": "Figma MCP Server",
  "packages": [
    {
      "registryType": "npm",
      "identifier": "figma-mcp-server",
      "version": "1.0.0",
      "runtimeHint": "npx",
      "transport": {
        "type": "stdio"
      }
    }
  ],
  "repository": {
    "url": "https://github.com/figma/mcp-server",
    "source": "github"
  }
}
```

### 测试 4: 获取 server 的所有版本

```bash
curl -s "http://localhost:8080/v0.1/servers/io.figma%2Fmcp-server/versions" | jq .
```

### 测试 5: 使用提供的测试脚本

```bash
# 运行完整的端点测试
bash scripts/test_endpoints.sh
```

## 🔍 常用测试命令

### 查看 CORS Headers

```bash
curl -v -X OPTIONS \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type" \
  http://localhost:8080/v0.1/servers
```

应该看到响应头包含：
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: *
```

### 测试分页

```bash
# 第一页（限制 5 条）
curl -s "http://localhost:8080/v0.1/servers?limit=5" | jq .

# 使用 cursor 获取下一页
CURSOR=$(curl -s "http://localhost:8080/v0.1/servers?limit=5" | jq -r '.metadata.nextCursor')
curl -s "http://localhost:8080/v0.1/servers?limit=5&cursor=$CURSOR" | jq .
```

### 测试白名单过滤

如果配置了 `ALLOWED_SERVERS`：

```bash
# 应该只返回白名单中的 servers
curl -s "http://localhost:8080/v0.1/servers" | jq '.servers[].name'

# 尝试访问不在白名单中的 server（应返回 404）
curl -s "http://localhost:8080/v0.1/servers/io.github.example%2Fother-server/versions/latest"
```

## 📊 查看完整的 JSON Schema

### 获取 API 文档

```bash
# 查看 OpenAPI 文档（交互式）
open http://localhost:8080/docs

# 或在服务器上使用 curl
curl -s http://localhost:8080/openapi.json | jq . > openapi.json
```

### 查看 server.json schema

```bash
# 查看项目中的 schema 文件
cat internal/validators/schemas/2025-12-11.json | jq .

# 或下载最新的 schema
curl -s https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json | jq .
```

## 🐛 故障排除

### 检查容器状态

```bash
# 查看所有容器
docker-compose ps

# 查看 registry 日志
docker-compose logs registry

# 查看 postgres 日志
docker-compose logs postgres

# 实时跟踪日志
docker-compose logs -f
```

### 常见问题

#### 1. 端口已被占用

```bash
# 修改端口
export MCP_REGISTRY_SERVER_ADDRESS=:8081
docker-compose down
docker-compose up -d

# 或修改 docker-compose.yml 中的 ports 配置
```

#### 2. 数据库连接失败

```bash
# 重启数据库
docker-compose restart postgres

# 等待数据库就绪
docker-compose exec postgres pg_isready -U mcpregistry
```

#### 3. 数据未加载

```bash
# 手动重新启动以重新加载种子数据
docker-compose down
docker-compose up -d
```

#### 4. 构建失败

```bash
# 清理并重新构建
make clean
docker-compose down -v
make dev-compose
```

## 🛑 停止服务

```bash
# 停止服务（保留数据）
docker-compose down

# 停止并删除所有数据
docker-compose down -v

# 使用 make 命令
make dev-down
```

## 🔄 更新代码

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose down
make dev-compose
```

## 📝 高级配置示例

### 完整的 .env 配置示例

```bash
cat > .env << 'EOF'
# 数据库配置
MCP_REGISTRY_DATABASE_URL=postgres://mcpregistry:mcpregistry@postgres:5432/mcp-registry

# 服务器地址
MCP_REGISTRY_SERVER_ADDRESS=:8080

# 种子数据来源（生产环境或本地文件）
MCP_REGISTRY_SEED_FROM=https://registry.modelcontextprotocol.io/v0/servers

# 服务器白名单（逗号分隔）
MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server,io.github.domdomegg/airtable-mcp-server

# 禁用注册表验证（仅用于开发）
MCP_REGISTRY_ENABLE_REGISTRY_VALIDATION=true

# 匿名认证（仅用于测试）
MCP_REGISTRY_ENABLE_ANONYMOUS_AUTH=true
EOF
```

### 生产环境配置

```bash
cat > .env.production << 'EOF'
MCP_REGISTRY_DATABASE_URL=postgres://user:password@production-db:5432/mcp-registry
MCP_REGISTRY_SERVER_ADDRESS=:8080
MCP_REGISTRY_SEED_FROM=https://registry.modelcontextprotocol.io/v0/servers
MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server
MCP_REGISTRY_ENABLE_ANONYMOUS_AUTH=false
MCP_REGISTRY_ENABLE_REGISTRY_VALIDATION=true

# 生产环境的 JWT 密钥（请生成自己的）
MCP_REGISTRY_JWT_PRIVATE_KEY=$(openssl rand -hex 32)

# GitHub OAuth 配置
MCP_REGISTRY_GITHUB_CLIENT_ID=your_client_id
MCP_REGISTRY_GITHUB_CLIENT_SECRET=your_client_secret
EOF
```

## 📚 相关文档

- [完整 README](README.md)
- [服务器白名单配置](docs/administration/server-allowlist.md)
- [私有注册表设置](PRIVATE_REGISTRY_SETUP.md)
- [API 规范合规性](REGISTRY_COMPLIANCE.md)
- [API 文档](docs/reference/api/generic-registry-api.md)

## 🎯 快速测试清单

复制此命令快速测试所有功能：

```bash
#!/bin/bash
# 快速测试脚本

echo "=== 测试 1: Ping ==="
curl -s http://localhost:8080/v0.1/ping | jq .

echo -e "\n=== 测试 2: 列出 servers ==="
curl -s "http://localhost:8080/v0.1/servers?limit=3" | jq '.servers[] | {name, version}'

echo -e "\n=== 测试 3: 搜索 Figma ==="
curl -s "http://localhost:8080/v0.1/servers?search=figma" | jq '.servers[] | .name'

echo -e "\n=== 测试 4: CORS Headers ==="
curl -I -X OPTIONS \
  -H "Origin: https://example.com" \
  http://localhost:8080/v0.1/servers 2>&1 | grep -i "access-control"

echo -e "\n=== 测试 5: API 文档 ==="
echo "访问: http://localhost:8080/docs"

echo -e "\n✅ 测试完成！"
```

保存为 `quick-test.sh`，运行：
```bash
chmod +x quick-test.sh
./quick-test.sh
```

---

**需要帮助？** 查看 [GitHub Issues](https://github.com/modelcontextprotocol/registry/issues) 或加入 [Discord](https://modelcontextprotocol.io/community/communication)
