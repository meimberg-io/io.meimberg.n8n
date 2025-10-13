#!/bin/bash
set -e

# n8n Backup Script
# Creates a complete backup of workflows and credentials

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# On production, backup is at /opt/n8n/backup (mounted to container)
# On local dev, backup is at project_root/backup
if [ -d "/opt/n8n/backup" ]; then
    BACKUP_ROOT="/opt/n8n/backup"
else
    BACKUP_ROOT="$PROJECT_ROOT/backup"
fi

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

# Clean old backup data
echo "Cleaning backup directories..."
echo "  Workflows: $WORKFLOWS_DIR"
echo "  Credentials: $CREDENTIALS_DIR"
rm -rf "$WORKFLOWS_DIR"/* "$CREDENTIALS_DIR"/* 2>/dev/null || true

# Export workflows (as individual files)
echo "Exporting workflows..."
docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/

echo "Checking workflows export..."
ls -la "$WORKFLOWS_DIR" || echo "Cannot list $WORKFLOWS_DIR"

# Export credentials (as single file with all credentials)
echo "Exporting credentials..."
docker exec n8n n8n export:credentials --output=/home/node/backup/credentials/credentials.json

echo "Checking credentials export..."
ls -la "$CREDENTIALS_DIR" || echo "Cannot list $CREDENTIALS_DIR"

# Verify files were created
if [ ! "$(ls -A $WORKFLOWS_DIR 2>/dev/null)" ]; then
    echo "[ERROR] No workflows exported! Check if /opt/n8n/backup is mounted correctly."
    exit 1
fi

if [ ! -f "$CREDENTIALS_DIR/credentials.json" ]; then
    echo "[ERROR] No credentials exported!"
    exit 1
fi

# Create timestamp
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Create tar.gz archive
echo "Creating backup archive..."
echo "  From: $BACKUP_ROOT (workflows/ and credentials/)"

# List what we're backing up
echo "Files to backup:"
find "$BACKUP_ROOT/workflows" "$BACKUP_ROOT/credentials" -type f 2>/dev/null | head -5
echo "  ... (showing first 5 files)"

# Archive location (in deploy folder for easy scp download)
ARCHIVE_DIR="$PROJECT_ROOT/backup"
mkdir -p "$ARCHIVE_DIR"
echo "  To: $ARCHIVE_DIR/backup.tar.gz"

# Create tar from the actual backup location
cd "$BACKUP_ROOT"
echo "Creating tar from: $(pwd)"
tar -czf "$ARCHIVE_DIR/backup.tar.gz" workflows/ credentials/

echo "Tar created. Checking contents..."
tar -tzf "$ARCHIVE_DIR/backup.tar.gz" | head -10

# Create timestamped copy for history
cp "$ARCHIVE_DIR/backup.tar.gz" "$ARCHIVE_DIR/backup_${TIMESTAMP}.tar.gz"

echo "[SUCCESS] Backup completed!"
echo "Current backup: $ARCHIVE_DIR/backup.tar.gz"
echo "Historic backup: $ARCHIVE_DIR/backup_${TIMESTAMP}.tar.gz"
echo ""
echo "Backup archive size:"
ls -lh "$ARCHIVE_DIR/backup.tar.gz"

