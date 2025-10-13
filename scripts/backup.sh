#!/bin/bash
set -e

# n8n Backup Script
# Creates a complete backup of workflows and credentials

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_ROOT="$PROJECT_ROOT/backup"

# Create backup directories
WORKFLOWS_DIR="$BACKUP_ROOT/workflows"
CREDENTIALS_DIR="$BACKUP_ROOT/credentials"
mkdir -p "$WORKFLOWS_DIR"
mkdir -p "$CREDENTIALS_DIR"

echo "Starting n8n backup..."

# Check if container is running
if ! docker ps | grep -q n8n; then
    echo "[ERROR] n8n container is not running!"
    exit 1
fi

# Export workflows
echo "Exporting workflows..."
docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows

# Export credentials (encrypted)
echo "Exporting credentials..."
docker exec n8n n8n export:credentials --backup --output=/home/node/backup/credentials

# Create timestamp
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Create tar.gz archive
echo "Creating backup archive..."
cd "$BACKUP_ROOT"
tar -czf backup.tar.gz workflows/ credentials/

# Create timestamped copy for history
cp backup.tar.gz "backup_${TIMESTAMP}.tar.gz"

echo "[SUCCESS] Backup completed!"
echo "📦 Current backup: $BACKUP_ROOT/backup.tar.gz"
echo "📦 Historic backup: $BACKUP_ROOT/backup_${TIMESTAMP}.tar.gz"
echo ""
echo "Backup contents:"
ls -lh backup*.tar.gz 2>/dev/null || echo "No backups found"

