#!/bin/bash
# 快速测试 MCP Registry 的所有核心功能
# 使用方法: ./quick-test.sh

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 配置
HOST="${MCP_REGISTRY_HOST:-http://localhost:8080}"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}MCP Registry 快速测试${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "测试地址: ${HOST}\n"

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}警告: jq 未安装，JSON 输出将不会格式化${NC}"
    echo -e "安装方法: brew install jq (macOS) 或 apt install jq (Ubuntu)\n"
    JQ_CMD="cat"
else
    JQ_CMD="jq ."
fi

# 测试函数
run_test() {
    local test_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -e "${BLUE}=== 测试: ${test_name} ===${NC}"
    echo -e "URL: ${url}"
    
    # 获取响应和状态码
    response=$(curl -s -w "\n%{http_code}" "$url")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    # 检查状态码
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ 状态码: ${http_code}${NC}"
    else
        echo -e "${RED}✗ 状态码: ${http_code} (期望: ${expected_status})${NC}"
    fi
    
    # 显示响应体（美化）
    echo -e "\n${YELLOW}响应:${NC}"
    echo "$body" | $JQ_CMD | head -30
    
    # 如果输出太长，显示提示
    line_count=$(echo "$body" | wc -l)
    if [ $line_count -gt 30 ]; then
        echo -e "${YELLOW}... (输出已截断，共 $line_count 行)${NC}"
    fi
    
    echo ""
}

# 测试 CORS
test_cors() {
    echo -e "${BLUE}=== 测试: CORS Headers ===${NC}"
    echo -e "URL: ${HOST}/v0.1/servers"
    
    headers=$(curl -s -I -X OPTIONS \
        -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: GET" \
        "${HOST}/v0.1/servers")
    
    if echo "$headers" | grep -iq "access-control-allow-origin"; then
        echo -e "${GREEN}✓ Access-Control-Allow-Origin 存在${NC}"
        echo "$headers" | grep -i "access-control"
    else
        echo -e "${RED}✗ CORS headers 缺失${NC}"
    fi
    echo ""
}

# 执行测试
echo -e "${GREEN}开始测试...${NC}\n"

# 1. Ping 测试
run_test "Ping 端点" "${HOST}/v0.1/ping" 200

# 2. 健康检查
run_test "健康检查" "${HOST}/v0/health" 200

# 3. 列出 servers（限制 3 条）
run_test "列出 Servers (limit=3)" "${HOST}/v0.1/servers?limit=3" 200

# 4. 搜索测试
run_test "搜索 'airtable'" "${HOST}/v0.1/servers?search=airtable&limit=2" 200

# 5. 获取特定 server（使用 latest）
# 注意: 这里使用一个常见的 server 作为示例
run_test "获取 Server Latest 版本" \
    "${HOST}/v0.1/servers/io.github.domdomegg%2Fairtable-mcp-server/versions/latest" 200

# 6. 列出 server 的所有版本
run_test "列出 Server 所有版本" \
    "${HOST}/v0.1/servers/io.github.domdomegg%2Fairtable-mcp-server/versions" 200

# 7. CORS 测试
test_cors

# 8. API 文档测试
run_test "OpenAPI 文档" "${HOST}/openapi.json" 200

# 总结
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}测试完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "查看更多信息:"
echo -e "  • API 文档: ${HOST}/docs"
echo -e "  • OpenAPI JSON: ${HOST}/openapi.json"
echo -e "  • 健康检查: ${HOST}/v0/health"
echo ""

# 如果配置了白名单，显示提示
if [ ! -z "$MCP_REGISTRY_ALLOWED_SERVERS" ]; then
    echo -e "${YELLOW}注意: 服务器白名单已启用${NC}"
    echo -e "允许的 servers: $MCP_REGISTRY_ALLOWED_SERVERS"
    echo ""
fi

# 显示一些有用的命令
echo -e "${BLUE}常用测试命令:${NC}"
echo -e "  # 查看所有 servers"
echo -e "  curl -s '${HOST}/v0.1/servers' | jq ."
echo ""
echo -e "  # 搜索特定 server"
echo -e "  curl -s '${HOST}/v0.1/servers?search=figma' | jq ."
echo ""
echo -e "  # 获取 server 详情"
echo -e "  curl -s '${HOST}/v0.1/servers/SERVER_NAME/versions/latest' | jq ."
echo ""
echo -e "  # 查看 CORS headers"
echo -e "  curl -I -X OPTIONS -H 'Origin: https://example.com' '${HOST}/v0.1/servers'"
echo ""
