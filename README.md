# PostgreSQL Docker Compose + MCP Server Setup

This project provides a local PostgreSQL database with a Model Context Protocol (MCP) server for AI integration.

## 🚀 Quick Start (3 Easy Steps!)

### 1. Start the Services
```bash
# Clone the repository
git clone https://github.com/vlameiras/mcp-postgres-example.git
cd mcp-postgres-example

# Copy environment configuration
cp .env.example .env

# Start PostgreSQL + MCP Server
docker-compose up -d
```

### 2. Test Everything Works
```bash
# Run comprehensive tests
./test.sh
```
You should see: `🎉 All tests passed! (5/5)`

### 3. Try the MCP API Examples
```bash
# Run interactive examples
./examples/mcp-examples.sh
```

**That's it! 🎉 Your setup is ready for AI integration.**

### Quick Access
- **PostgreSQL Database**: `localhost:5432` (user: `myuser`, password: `mypassword`, database: `mydatabase`)
- **MCP Server API**: `http://localhost:8080/mcp`
- **Health Check**: `http://localhost:8080/health`

## 📦 What You Get

✅ **PostgreSQL Database** - Containerized PostgreSQL 16 with sample data  
✅ **MCP Server** - Model Context Protocol server for AI integration  
✅ **Sample Data** - Users, posts, and relationships ready for testing  
✅ **Health Checks** - Automatic monitoring and restart capabilities  
✅ **Test Suite** - Comprehensive validation of all functionality  
✅ **API Examples** - Interactive demonstrations of MCP capabilities  
✅ **Backup Tools** - Database backup and restore utilities  

## ⚡ Common Issues & Solutions

**Services won't start?**
```bash
# Check if ports 5432 or 8080 are in use
lsof -i :5432
lsof -i :8080

# Or use different ports by editing .env file
```

**Tests failing?**
```bash
# Wait for services to fully start (takes ~60 seconds)
docker-compose ps

# Check service logs
docker-compose logs postgres
docker-compose logs mcp-server
```

**Need to reset everything?**
```bash
# Stop and remove everything (including data)
docker-compose down -v

# Start fresh
docker-compose up -d
```

## Services

### PostgreSQL Database
- **Port:** 5432
- **Database:** mydatabase
- **User:** myuser
- **Password:** mypassword (change in .env file)

### MCP Server
- **Port:** 8080
- **Protocol:** HTTP/JSON
- **Features:** Read-only PostgreSQL access via Model Context Protocol

## Configuration

Edit the `.env` file to customize:
- Database credentials
- Port mappings
- Server configurations

## 💡 Usage Examples

### 🔄 Easy Way: Run the Examples Script
```bash
# See all MCP server capabilities in action
./examples/mcp-examples.sh
```

### 🔧 Manual API Testing

#### 1. Check Server Health
```bash
curl http://localhost:8080/health
```

#### 2. List Database Resources
```bash
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "resources"
  }'
```

#### 3. Execute SQL Query
```bash
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function", 
    "name": "query",
    "arguments": {
      "query": "SELECT username, email FROM sample.users LIMIT 5;"
    }
  }'
```

### 🗄️ Direct Database Access (Optional)
```bash
# Connect using psql
psql -h localhost -p 5432 -U myuser -d mydatabase

# Or using Docker
docker-compose exec postgres psql -U myuser -d mydatabase
```

## 📊 Sample Data

The setup includes sample data in the `sample` schema:
- `sample.users` - User accounts
- `sample.posts` - Blog posts linked to users
- `sample.user_posts` - View combining users and posts

## Health Checks

Both services include health checks:
- **PostgreSQL:** `pg_isready` command
- **MCP Server:** HTTP health endpoint

Check service health:
```bash
docker-compose ps
```

## Data Persistence

PostgreSQL data persists in a Docker volume (`postgres_data`) and survives container restarts.

## Logs

View service logs:
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs postgres
docker-compose logs mcp-server
```

## Stopping Services

```bash
# Stop services
docker-compose stop

# Stop and remove containers (data persists)
docker-compose down

# Stop, remove containers, and remove volumes (data will be lost)
docker-compose down -v
```

## Troubleshooting

### Services Won't Start
1. Check if ports are already in use
2. Verify Docker and Docker Compose are installed
3. Check `.env` file configuration

### Connection Issues
1. Wait for health checks to pass (up to 60 seconds)
2. Check service logs for errors
3. Verify network connectivity between services

### MCP Server Errors
1. Ensure PostgreSQL is running and healthy
2. Verify DATABASE_URL format in environment
3. Check MCP server logs for specific errors

## Security Notes

- Change default passwords in production
- Use strong, unique passwords
- Consider network security for production deployments
- The MCP server provides read-only access by default

## Development

### Adding Custom Initialization Scripts
Place SQL files in `init-db/` directory. They run automatically when PostgreSQL starts for the first time.

### Modifying Configuration
- Edit `docker-compose.yml` for service configuration
- Edit `.env` file for environment variables
- Restart services after configuration changes

## AI Integration

The MCP server enables AI models to:
- Query database schema and structure
- Execute read-only SQL queries
- Retrieve real-time data without embeddings
- Analyze data patterns and relationships

Connect your AI client to `http://localhost:8080/mcp` to start using the database with natural language queries.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   AI Client │────▶│ MCP Server  │────▶│ PostgreSQL  │
│             │     │ (Port 8080) │     │ (Port 5432) │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Docker    │
                    │   Network   │
                    └─────────────┘
```
# mcp-postgres-example
