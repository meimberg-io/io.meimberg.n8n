#!/bin/bash
set -e

# n8n Restore Script
# Restores workflows and credentials from backup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_ROOT="$PROJECT_ROOT/backup"

# Check if backup exists
if [ ! -f "$BACKUP_ROOT/backup.tar.gz" ]; then
    echo "[ERROR] No backup found at $BACKUP_ROOT/backup.tar.gz"
    echo "Available backups:"
    ls -lh "$BACKUP_ROOT"/backup_*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

echo "Starting n8n restore..."

# Check if container is running
if ! docker ps | grep -q n8n; then
    echo "[ERROR] n8n container is not running!"
    echo "Start n8n first with: ./scripts/start.sh or ./scripts/dev.sh"
    exit 1
fi

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
            docker exec n8n n8n import:workflow --input="/home/node/backup/workflows/$(basename "$workflow")"
        fi
    done
else
    echo "[WARNING] No workflows directory found in backup"
fi

# Import credentials
echo "Importing credentials..."
if [ -d "$BACKUP_ROOT/credentials" ]; then
    for credential in "$BACKUP_ROOT/credentials"/*.json; do
        if [ -f "$credential" ]; then
            echo "Importing $(basename "$credential")..."
            docker exec n8n n8n import:credentials --input="/home/node/backup/credentials/$(basename "$credential")"
        fi
    done
else
    echo "[WARNING] No credentials directory found in backup"
fi

echo "[SUCCESS] Restore completed!"
echo ""
echo "⚠️  You may need to restart n8n for all changes to take effect:"
echo "   ./scripts/restart.sh"

