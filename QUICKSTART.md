# 🚀 Quick Start - Lightweight MCP Registry

## 📋 Completed Refactoring

✅ **Fully rewrote `cmd/registry/main.go`**
✅ **Removed all database dependencies**
✅ **Uses only the Go standard library**
✅ **Reads data from `data/seed.json`**
✅ **Supports all required API endpoints**

---

## 🎯 Get Started (Three Steps)

### Step 1: Start the Server

Using the existing startup method (**recommended**):
```bash
make dev-compose
```

Or run directly:
```bash
go run cmd/registry/main.go
```

### Step 2: Verify the Server

```bash
curl http://localhost:8081/v0.1/ping
```

Expected response:
```json
{
  "status": "ok",
  "message": "pong"
}
```

### Step 3: Test All Endpoints

```bash
# Linux/Mac
chmod +x test-lightweight.sh
./test-lightweight.sh

```

---

## 📡 API Endpoints Overview

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/healthz` | GET | Azure/K8s health check |
| `/v0.1/ping` | GET | API connectivity test |
| `/v0.1/servers` | GET | List all servers |
| `/v0.1/servers` | POST | Create a server (non-persistent) |
| `/v0.1/servers/{name}/versions/latest` | GET | Get latest version |
| `/v0.1/servers/{name}/versions/{version}` | GET | Get specific version |

---

## 🧪 Quick Tests

### Test 1: Ping
```bash
curl http://localhost:8081/v0.1/ping
```

### Test 2: List Servers
```bash
curl http://localhost:8081/v0.1/servers | jq '.metadata'
```

### Test 3: Get Figma MCP Server
```bash
curl "http://localhost:8081/v0.1/servers/io.figma%2Fmcp-server/versions/latest" | jq '{name, version}'
```

### Test 4: POST Create Server
```bash
curl -X POST http://localhost:8081/v0.1/servers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "com.example/my-server",
    "version": "1.0.0",
    "description": "My awesome server"
  }' | jq '.'
```

---

## 🎯 Key Improvements

### Before (requires database)
```go
// Requires connecting to PostgreSQL
db, err = database.NewPostgreSQL(ctx, cfg.DatabaseURL)

// Requires many internal packages
"github.com/modelcontextprotocol/registry/internal/api"
"github.com/modelcontextprotocol/registry/internal/database"
"github.com/modelcontextprotocol/registry/internal/service"
...
```

### Now (fully standalone)
```go
// Directly reads JSON file
registry, err = loadSeedData("/data/seed.json")

// Uses only the Go standard library
"context"
"encoding/json"
"net/http"
...
```

---

## 🔧 Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT` | `8080` | HTTP port |
| `MCP_REGISTRY_SEED_FROM` | `/data/seed.json` | Seed file path |

---

## 📁 File Structure

```
registry/
├── cmd/
│   └── registry/
│       └── main.go              ✨ Refactored - lightweight version
├── data/
│   └── seed.json                📊 Data source
├── test-lightweight.sh          🧪 Test script (Linux/Mac)
└── QUICKSTART.md                📚 This file
```

---

## 🎉 It's that simple!

1. **Start**: `make dev-compose`
2. **Test**: `./test-lightweight.sh`
3. **Done**: ✅

---

## 💡 FAQ

### Q: How do I change the port?
```bash
PORT=9090 go run cmd/registry/main.go
```

### Q: How do I use a different data file?
```bash
MCP_REGISTRY_SEED_FROM=my-data.json go run cmd/registry/main.go
```

### Q: Will POST data be persisted?
No. This is the lightweight version — all POST requests only return a success message and are not persisted.

### Q: Can it be used in production?
Yes, but only for static configuration scenarios. If you need to dynamically add/modify servers, use the full version (with database).

---

## 🚀 Deployment Recommendations

### Docker
```bash
docker build -t mcp-registry-light .
docker run -d -p 8080:8080 -v ./data:/data:ro mcp-registry-light
```

### Kubernetes
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mcp-seed-data
data:
  seed.json: |
    [...]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-registry
spec:
  template:
    spec:
      containers:
      - name: registry
        image: mcp-registry-light
        volumeMounts:
        - name: seed-data
          mountPath: /data
      volumes:
      - name: seed-data
        configMap:
          name: mcp-seed-data
```

---

**Created**: 2026-06-01
**Version**: Lightweight v1.0
**Suitable for**: Static configuration, lightweight deployment, development and testing
