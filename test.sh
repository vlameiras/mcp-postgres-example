#!/bin/bash

# Test script for PostgreSQL + MCP Server setup
# This script performs basic health checks and API tests

set -e

echo "🧪 Starting PostgreSQL + MCP Server Tests"
echo "=========================================="

# Configuration
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432" 
POSTGRES_USER="myuser"
POSTGRES_DB="mydatabase"
MCP_SERVER_URL="http://localhost:8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_postgres_connection() {
    echo -n "🔍 Testing PostgreSQL connection... "
    if docker-compose exec -T postgres pg_isready -h localhost -p 5432 -U $POSTGRES_USER >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

test_mcp_server_health() {
    echo -n "🔍 Testing MCP Server health... "
    if curl -f -s "${MCP_SERVER_URL}/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

test_mcp_resources() {
    echo -n "🔍 Testing MCP resources endpoint... "
    local response=$(curl -s -X POST "${MCP_SERVER_URL}/mcp" \
        -H "Content-Type: application/json" \
        -d '{
            "type": "function",
            "name": "resources"
        }' 2>/dev/null)
    
    if echo "$response" | grep -q "resources" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "Response: $response"
        return 1
    fi
}

test_mcp_query() {
    echo -n "🔍 Testing MCP query execution... "
    local response=$(curl -s -X POST "${MCP_SERVER_URL}/mcp" \
        -H "Content-Type: application/json" \
        -d '{
            "type": "function",
            "name": "query",
            "arguments": {
                "query": "SELECT COUNT(*) as user_count FROM sample.users;"
            }
        }' 2>/dev/null)
    
    if echo "$response" | grep -q "user_count" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "Response: $response"
        return 1
    fi
}

test_data_persistence() {
    echo -n "🔍 Testing data persistence... "
    local user_count=$(docker-compose exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT COUNT(*) FROM sample.users;" 2>/dev/null | xargs)
    
    if [[ "$user_count" =~ ^[0-9]+$ ]] && [ "$user_count" -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} (Found $user_count users)"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

# Check if services are running
echo "🚀 Checking if services are running..."
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${YELLOW}⚠️  Services not running. Starting them...${NC}"
    docker-compose up -d
    echo "⏳ Waiting 30 seconds for services to start..."
    sleep 30
fi

# Run tests
echo ""
echo "🧪 Running Tests"
echo "=================="

failed_tests=0

test_postgres_connection || ((failed_tests++))
test_mcp_server_health || ((failed_tests++))
test_mcp_resources || ((failed_tests++))
test_mcp_query || ((failed_tests++))
test_data_persistence || ((failed_tests++))

echo ""
echo "📊 Test Results"
echo "==============="

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! (5/5)${NC}"
    echo ""
    echo "🔗 Services are ready:"
    echo "   PostgreSQL: $POSTGRES_HOST:$POSTGRES_PORT"
    echo "   MCP Server: $MCP_SERVER_URL"
    exit 0
else
    echo -e "${RED}❌ $failed_tests test(s) failed${NC}"
    echo ""
    echo "🔧 Troubleshooting tips:"
    echo "   - Check service logs: docker-compose logs"
    echo "   - Verify services are running: docker-compose ps"
    echo "   - Check network connectivity between services"
    exit 1
fi
