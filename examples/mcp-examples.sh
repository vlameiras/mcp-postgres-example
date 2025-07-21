#!/bin/bash

# MCP Server API Examples
# Demonstrates various ways to interact with the MCP server

MCP_SERVER_URL="http://localhost:8080"

echo "🚀 MCP Server API Examples"
echo "=========================="
echo "Server URL: $MCP_SERVER_URL"
echo ""

# Example 1: List all database resources
echo "📋 Example 1: List Database Resources"
echo "--------------------------------------"
curl -X POST "$MCP_SERVER_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "resources"
  }' | jq '.' 2>/dev/null || echo "Response received (install jq for pretty formatting)"

echo -e "\n"

# Example 2: Basic SELECT query
echo "📊 Example 2: Basic User Query"
echo "-------------------------------"
curl -X POST "$MCP_SERVER_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "query",
    "arguments": {
      "query": "SELECT id, username, email, created_at FROM sample.users ORDER BY created_at DESC;"
    }
  }' | jq '.' 2>/dev/null || echo "Response received"

echo -e "\n"

# Example 3: JOIN query
echo "🔗 Example 3: Users with Posts (JOIN)"
echo "-------------------------------------"
curl -X POST "$MCP_SERVER_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "query",
    "arguments": {
      "query": "SELECT u.username, p.title, p.created_at FROM sample.users u JOIN sample.posts p ON u.id = p.user_id ORDER BY p.created_at DESC LIMIT 5;"
    }
  }' | jq '.' 2>/dev/null || echo "Response received"

echo -e "\n"

# Example 4: Aggregation query
echo "📈 Example 4: Post Count by User"
echo "--------------------------------"
curl -X POST "$MCP_SERVER_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "query",
    "arguments": {
      "query": "SELECT u.username, COUNT(p.id) as post_count FROM sample.users u LEFT JOIN sample.posts p ON u.id = p.user_id GROUP BY u.username ORDER BY post_count DESC;"
    }
  }' | jq '.' 2>/dev/null || echo "Response received"

echo -e "\n"

# Example 5: Schema information
echo "🏗️  Example 5: Schema Information"
echo "----------------------------------"
curl -X POST "$MCP_SERVER_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "query",
    "arguments": {
      "query": "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = '\''sample'\'' ORDER BY table_name, ordinal_position;"
    }
  }' | jq '.' 2>/dev/null || echo "Response received"

echo -e "\n"

# Example 6: Using the view
echo "👁️  Example 6: Using User Posts View"
echo "------------------------------------"
curl -X POST "$MCP_SERVER_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "query",
    "arguments": {
      "query": "SELECT * FROM sample.user_posts WHERE title IS NOT NULL LIMIT 3;"
    }
  }' | jq '.' 2>/dev/null || echo "Response received"

echo -e "\n"
echo "✨ Examples completed!"
echo ""
echo "💡 Tips:"
echo "   - Install jq for better JSON formatting: brew install jq"
echo "   - All queries are read-only for security"
echo "   - Use these patterns for AI integration"
