#!/bin/bash
set -e

# n8n Restore Script
# Restores workflows and credentials from backup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_ROOT="$PROJECT_ROOT/backupdata"

# Check if backup exists
if [ ! -f "$BACKUP_ROOT/backup.tar.gz" ]; then
    echo "[ERROR] No backup found at $BACKUP_ROOT/backup.tar.gz"
    echo "Available backups:"
    ls -lh "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

echo "Starting n8n restore..."

# Check if container is running
# Check for n8n-dev (local) or n8n (production style) or n8n-prod (testing)
CONTAINER_NAME=""
if docker ps | grep -q "n8n-dev"; then
    CONTAINER_NAME="n8n-dev"
elif docker ps | grep -q " n8n$"; then
    CONTAINER_NAME="n8n"
elif docker ps | grep -q "n8n-prod"; then
    CONTAINER_NAME="n8n-prod"
fi

if [ -z "$CONTAINER_NAME" ]; then
    echo "[ERROR] n8n container is not running!"
    echo "Start n8n first with: docker compose --profile dev up"
    exit 1
fi

echo "Using container: $CONTAINER_NAME"

# Clean old backup data
echo "Cleaning old backup data..."
rm -rf "$BACKUP_ROOT/workflows" "$BACKUP_ROOT/credentials" 2>/dev/null || true

# Extract backup
echo "Extracting backup..."
cd "$BACKUP_ROOT"
tar -xzf backup.tar.gz

# Import workflows
echo "Importing workflows..."
if [ -d "$BACKUP_ROOT/workflows" ]; then
    for workflow in "$BACKUP_ROOT/workflows"/*.json; do
        if [ -f "$workflow" ]; then
            echo "Importing $(basename "$workflow")..."
            docker exec "$CONTAINER_NAME" n8n import:workflow --input="/home/node/backup/workflows/$(basename "$workflow")"
        fi
    done
else
    echo "[WARNING] No workflows directory found in backup"
fi

# Import credentials
echo "Importing credentials..."
if [ -f "$BACKUP_ROOT/credentials/credentials.json" ]; then
    echo "Importing credentials..."
    docker exec "$CONTAINER_NAME" n8n import:credentials --input="/home/node/backup/credentials/credentials.json"
else
    echo "[WARNING] No credentials file found in backup"
fi

echo "[SUCCESS] Restore completed!"
echo ""
echo "⚠️  You may need to restart n8n for all changes to take effect:"
echo "   docker compose --profile dev restart"

