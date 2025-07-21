#!/bin/bash

# Backup script for PostgreSQL database
# Creates timestamped backups of the database

set -e

# Configuration
POSTGRES_USER="myuser"
POSTGRES_DB="mydatabase"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🗄️  PostgreSQL Backup Script${NC}"
echo "================================="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if PostgreSQL is running
if ! docker-compose ps postgres | grep -q "Up"; then
    echo "❌ PostgreSQL container is not running"
    echo "Start it with: docker-compose up -d postgres"
    exit 1
fi

echo "📦 Creating backup..."
echo "Target: $BACKUP_FILE"

# Create backup
docker-compose exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"
COMPRESSED_FILE="${BACKUP_FILE}.gz"

echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo "File: $COMPRESSED_FILE"
echo "Size: $(ls -lh "$COMPRESSED_FILE" | awk '{print $5}')"

# Cleanup old backups (keep last 5)
echo "🧹 Cleaning up old backups..."
ls -t "$BACKUP_DIR"/postgres_backup_*.sql.gz 2>/dev/null | tail -n +6 | xargs -r rm
echo "Kept most recent 5 backups"

echo ""
echo "💡 To restore this backup:"
echo "   1. Stop services: docker-compose down"
echo "   2. Remove volume: docker volume rm postgresql-test_postgres_data"
echo "   3. Start PostgreSQL: docker-compose up -d postgres"
echo "   4. Restore: gunzip -c $COMPRESSED_FILE | docker-compose exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB"
