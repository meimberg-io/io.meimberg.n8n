#!/bin/bash
set -e

# Sync n8n data from Production to Local Development
# This script:
# 1. Triggers backup on production server via SSH
# 2. Downloads the backup via SCP
# 3. Restores it to local dev instance

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables from .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(cat "$PROJECT_ROOT/.env" | grep -v '^#' | grep -v '^[[:space:]]*$' | xargs)
else
    echo "[ERROR] .env file not found!"
    echo "Copy env.example to .env and configure production SSH settings"
    exit 1
fi

# Check required variables
if [ -z "$PROD_SSH_HOST" ] || [ -z "$PROD_SSH_USER" ] || [ -z "$PROD_SSH_KEY" ]; then
    echo "[ERROR] Missing production SSH configuration in .env"
    echo "Required variables: PROD_SSH_HOST, PROD_SSH_USER, PROD_SSH_KEY"
    exit 1
fi

# Expand ~ in SSH key path
PROD_SSH_KEY="${PROD_SSH_KEY/#\~/$HOME}"

# Check if SSH key exists
if [ ! -f "$PROD_SSH_KEY" ]; then
    echo "[ERROR] SSH key not found: $PROD_SSH_KEY"
    exit 1
fi

# Set defaults
PROD_SSH_PORT="${PROD_SSH_PORT:-22}"
PROD_APP_DIR="${PROD_APP_DIR:-/opt/n8n}"

echo "🔄 Syncing n8n data from production..."
echo "   Host: $PROD_SSH_USER@$PROD_SSH_HOST:$PROD_SSH_PORT"
echo "   Directory: $PROD_APP_DIR"
echo ""

# Step 1: Trigger backup on production
echo "📦 Step 1/3: Creating backup on production..."
ssh -i "$PROD_SSH_KEY" -p "$PROD_SSH_PORT" "$PROD_SSH_USER@$PROD_SSH_HOST" << 'EOF'
cd /opt/n8n/deploy
./scripts/backup.sh
EOF

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to create backup on production"
    exit 1
fi

echo ""

# Step 2: Download backup
echo "⬇️  Step 2/3: Downloading backup from production..."
BACKUP_ROOT="$PROJECT_ROOT/backup"
mkdir -p "$BACKUP_ROOT"

scp -i "$PROD_SSH_KEY" -P "$PROD_SSH_PORT" \
    "$PROD_SSH_USER@$PROD_SSH_HOST:$PROD_APP_DIR/deploy/backup/backup.tar.gz" \
    "$BACKUP_ROOT/backup.tar.gz"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to download backup from production"
    exit 1
fi

echo ""

# Step 3: Restore to local
echo "📥 Step 3/3: Restoring backup to local dev instance..."
"$SCRIPT_DIR/restore.sh"

echo ""
echo "[SUCCESS] Production data synced to local development!"
echo ""
echo "⚠️  Remember to restart your local n8n:"
echo "   ./scripts/restart.sh (if running in background)"
echo "   Or restart your dev.sh session"

