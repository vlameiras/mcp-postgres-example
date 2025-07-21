# PostgreSQL Docker Compose + MCP Server Setup

This project provides a local PostgreSQL database with a Model Context Protocol (MCP) server for AI integration.

## Quick Start

1. **Clone and navigate to the project:**
   ```bash
   git clone <repository-url>
   cd postgresql-test
   ```

2. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Start the services:**
   ```bash
   docker-compose up -d
   ```

4. **Verify services are running:**
   ```bash
   docker-compose ps
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

## Usage Examples

### Direct Database Access
```bash
# Connect using psql
psql -h localhost -p 5432 -U myuser -d mydatabase

# Or using Docker
docker-compose exec postgres psql -U myuser -d mydatabase
```

### MCP Server API

#### List Database Resources
```bash
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "resources"
  }'
```

#### Execute SQL Query
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

#### Get Database Schema Information
```bash
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "type": "function",
    "name": "query", 
    "arguments": {
      "query": "SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema = '\''sample'\'' ORDER BY table_name, ordinal_position;"
    }
  }'
```

## Sample Data

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
