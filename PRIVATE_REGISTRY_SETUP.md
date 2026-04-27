# Quick Start: Private Registry with Server Allowlist

## 快速配置步骤

### 1. 复制配置文件模板

```bash
cp .env.private-figma-only .env
```

### 2. 修改配置文件

编辑 `.env` 文件，设置以下关键配置：

```bash
# 数据库连接
MCP_REGISTRY_DATABASE_URL=postgres://username:password@localhost:5432/mcp-registry

# 服务器白名单 - 只允许 Figma MCP Server
MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server
```

### 3. 启动注册表

使用 Docker Compose 启动：

```bash
make dev-compose
```

或者手动启动：

```bash
docker-compose up
```

### 4. 验证配置

测试只有 Figma server 可访问：

```bash
# 列出所有服务器 - 应该只返回 Figma server
curl http://localhost:8080/v0/servers

# 尝试访问 Figma server - 应该成功
curl http://localhost:8080/v0/servers/io.figma%2Fmcp-server

# 尝试访问其他 server - 应该返回 404
curl http://localhost:8080/v0/servers/io.github.example%2Fother-server
```

## 配置说明

### 查找服务器名称

如果不确定 Figma MCP Server 的确切名称，可以先查询公共注册表：

```bash
# 搜索 Figma 相关的服务器
curl "https://registry.modelcontextprotocol.io/v0/servers?search=figma"
```

在返回的 JSON 中查找 `name` 字段，例如：
```json
{
  "servers": [
    {
      "name": "io.figma/mcp-server",
      "description": "Figma MCP Server",
      ...
    }
  ]
}
```

### 允许多个服务器

如果需要允许多个服务器，使用逗号分隔：

```bash
MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server,io.github.example/another-server
```

### 关闭白名单功能

如果要允许访问所有服务器，清空或注释掉该配置：

```bash
# MCP_REGISTRY_ALLOWED_SERVERS=
```

或：

```bash
MCP_REGISTRY_ALLOWED_SERVERS=
```

## Docker Compose 示例

修改 `docker-compose.yml` 添加白名单配置：

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: mcp-registry
      POSTGRES_USER: registry
      POSTGRES_PASSWORD: registry_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  registry:
    build: .
    environment:
      - MCP_REGISTRY_DATABASE_URL=postgres://registry:registry_password@postgres:5432/mcp-registry
      - MCP_REGISTRY_SERVER_ADDRESS=:8080
      - MCP_REGISTRY_SEED_FROM=https://registry.modelcontextprotocol.io/v0/servers
      # 关键配置：只允许 Figma MCP Server
      - MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server
    ports:
      - "8080:8080"
    depends_on:
      - postgres

volumes:
  postgres_data:
```

## 故障排除

### 问题：所有服务器仍然可见

**解决方案：**
1. 检查环境变量是否正确设置：`echo $MCP_REGISTRY_ALLOWED_SERVERS`
2. 确认服务已重启
3. 查看日志确认配置已加载

### 问题：Figma server 返回 404

**解决方案：**
1. 检查数据库中是否有该服务器数据
2. 验证服务器名称是否完全匹配（区分大小写）
3. 确认服务器名称中没有多余的空格

### 问题：无法连接数据库

**解决方案：**
1. 确认 PostgreSQL 服务正在运行
2. 检查数据库连接字符串格式
3. 验证数据库用户权限

## 生产环境注意事项

1. **安全性**：使用强密码和安全的 JWT 密钥
2. **SSL/TLS**：配置 HTTPS 以保护传输数据
3. **备份**：定期备份数据库
4. **监控**：设置监控和告警
5. **更新**：定期更新服务器名称列表

## 更多信息

详细文档请参阅：[docs/administration/server-allowlist.md](docs/administration/server-allowlist.md)
