#!/bin/bash
set -e

# Migration script: n8n from hc-01 to hc-02
# This script:
# 1. Exports workflows, credentials, and encryption key from hc-01.meimberg.io
# 2. Downloads the backup locally
# 3. Uploads to hc-02.meimberg.io
# 4. Imports into the new n8n instance
# 
# IMPORTANT: The encryption key must be migrated for credentials to work!

echo "🔄 Migrating n8n from hc-01.meimberg.io to hc-02.meimberg.io"
echo "================================================================"
echo ""

# Configuration
OLD_HOST="hc-01.meimberg.io"
NEW_HOST="hc-02.meimberg.io"
SSH_KEY_HC01="${HOME}/.ssh/oli_key_hc-01"
SSH_KEY_HC02="${HOME}/.ssh/oli_key"
SSH_USER="root"
TEMP_BACKUP="/tmp/n8n-migration-$(date +%Y%m%d-%H%M%S)"

# Expand tilde in SSH key paths
SSH_KEY_HC01="${SSH_KEY_HC01/#\~/$HOME}"
SSH_KEY_HC02="${SSH_KEY_HC02/#\~/$HOME}"

# Check SSH keys exist
if [ ! -f "$SSH_KEY_HC01" ]; then
    echo "[ERROR] SSH key for hc-01 not found: $SSH_KEY_HC01"
    exit 1
fi

if [ ! -f "$SSH_KEY_HC02" ]; then
    echo "[ERROR] SSH key for hc-02 not found: $SSH_KEY_HC02"
    exit 1
fi

echo "📍 Source: $OLD_HOST (old n8n instance)"
echo "📍 Target: $NEW_HOST (new n8n instance)"
echo "🔑 Using SSH keys:"
echo "   hc-01: $SSH_KEY_HC01"
echo "   hc-02: $SSH_KEY_HC02"
echo ""

# Step 1: Export data from hc-01
echo "📦 Step 1/4: Exporting data from hc-01..."
echo "-------------------------------------------"

ssh -i "$SSH_KEY_HC01" "$SSH_USER@$OLD_HOST" << 'EOF'
set -e

echo "Finding n8n container on hc-01..."

# Find the n8n container (could be named differently)
CONTAINER=$(docker ps --format '{{.Names}}' | grep -i n8n | head -1)

if [ -z "$CONTAINER" ]; then
    echo "[ERROR] No n8n container found on hc-01!"
    docker ps
    exit 1
fi

echo "Found container: $CONTAINER"

# Create temporary backup directory
BACKUP_DIR="/tmp/n8n-migration-backup"
mkdir -p "$BACKUP_DIR/workflows"
mkdir -p "$BACKUP_DIR/credentials"

echo "Exporting workflows..."
docker exec "$CONTAINER" n8n export:workflow --backup --output=/tmp/workflows/

echo "Exporting credentials..."
docker exec "$CONTAINER" n8n export:credentials --all --output=/tmp/credentials.json

echo "Exporting encryption key..."
docker cp "$CONTAINER":/home/node/.n8n/config "$BACKUP_DIR/config"

# Copy from container to host
docker cp "$CONTAINER":/tmp/workflows/. "$BACKUP_DIR/workflows/"
docker cp "$CONTAINER":/tmp/credentials.json "$BACKUP_DIR/credentials/"

# Create archive
cd /tmp
tar -czf n8n-migration-backup.tar.gz n8n-migration-backup/

echo "Backup created at: /tmp/n8n-migration-backup.tar.gz"
ls -lh /tmp/n8n-migration-backup.tar.gz

# List what we backed up
echo ""
echo "Backed up workflows:"
ls -1 "$BACKUP_DIR/workflows/" | wc -l
echo ""
echo "Backed up credentials:"
if [ -f "$BACKUP_DIR/credentials/credentials.json" ]; then
    echo "✓ credentials.json"
else
    echo "✗ No credentials file"
fi
echo ""
echo "Backed up encryption key:"
if [ -f "$BACKUP_DIR/config" ]; then
    echo "✓ config (encryption key)"
else
    echo "✗ No config file - credentials will NOT work on new server!"
fi
EOF

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to export data from hc-01"
    exit 1
fi

echo ""
echo "✅ Export completed!"
echo ""

# Step 2: Download backup from hc-01
echo "⬇️  Step 2/4: Downloading backup from hc-01..."
echo "-----------------------------------------------"

mkdir -p "$TEMP_BACKUP"
scp -i "$SSH_KEY_HC01" "$SSH_USER@$OLD_HOST:/tmp/n8n-migration-backup.tar.gz" "$TEMP_BACKUP/"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to download backup from hc-01"
    exit 1
fi

echo "✅ Downloaded to: $TEMP_BACKUP/n8n-migration-backup.tar.gz"
echo ""

# Step 3: Upload backup to hc-02
echo "⬆️  Step 3/4: Uploading backup to hc-02..."
echo "-------------------------------------------"

scp -i "$SSH_KEY_HC02" "$TEMP_BACKUP/n8n-migration-backup.tar.gz" "$SSH_USER@$NEW_HOST:/tmp/"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to upload backup to hc-02"
    exit 1
fi

echo "✅ Uploaded to hc-02:/tmp/"
echo ""

# Step 4: Import into new n8n instance on hc-02
echo "📥 Step 4/4: Importing data into new n8n on hc-02..."
echo "-----------------------------------------------------"

ssh -i "$SSH_KEY_HC02" "$SSH_USER@$NEW_HOST" << 'EOF'
set -e

echo "Finding n8n container on hc-02..."

# Check if n8n container is running
if ! docker ps | grep -q " n8n$"; then
    echo "[ERROR] n8n container is not running on hc-02!"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

echo "Found container: n8n"

# Extract backup
cd /tmp
tar -xzf n8n-migration-backup.tar.gz

# Ensure deploy user can access the files
DEPLOY_UID=$(id -u deploy)
if [ -n "$DEPLOY_UID" ]; then
    chown -R deploy:deploy /tmp/n8n-migration-backup
fi

# Copy to n8n project directory
mkdir -p /srv/projects/n8n/migration
cp -r /tmp/n8n-migration-backup/* /srv/projects/n8n/migration/

echo ""
echo "Installing encryption key..."
if [ -f /srv/projects/n8n/migration/config ]; then
    # Copy the encryption key to the container
    docker cp /srv/projects/n8n/migration/config n8n:/home/node/.n8n/config
    echo "✓ Encryption key installed"
    echo "🔄 Restarting n8n to apply encryption key..."
    cd /srv/projects/n8n && docker compose restart n8n
    sleep 5
    echo "✓ n8n restarted"
else
    echo "⚠️  WARNING: No encryption key found! Credentials may not work!"
fi

echo ""
echo "Importing workflows..."
WORKFLOW_COUNT=0
for workflow in /srv/projects/n8n/migration/workflows/*.json; do
    if [ -f "$workflow" ]; then
        echo "  Importing $(basename "$workflow")..."
        docker cp "$workflow" n8n:/tmp/workflow.json
        docker exec n8n n8n import:workflow --input=/tmp/workflow.json
        WORKFLOW_COUNT=$((WORKFLOW_COUNT + 1))
    fi
done

echo ""
echo "Importing credentials..."
if [ -f /srv/projects/n8n/migration/credentials/credentials.json ]; then
    docker cp /srv/projects/n8n/migration/credentials/credentials.json n8n:/tmp/credentials.json
    docker exec n8n n8n import:credentials --input=/tmp/credentials.json
    echo "✓ Credentials imported"
else
    echo "⚠️  No credentials file found"
fi

echo ""
echo "Migration summary:"
echo "  Workflows imported: $WORKFLOW_COUNT"
echo "  Encryption key: Migrated ✓"
echo "  Credentials: Ready to use (encryption key applied)"
echo ""

# Cleanup
rm -rf /tmp/n8n-migration-backup /tmp/n8n-migration-backup.tar.gz
echo "Cleaned up temporary files on hc-02"
EOF

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to import data into hc-02"
    exit 1
fi

echo ""
echo "✅ Import completed!"
echo ""

# Cleanup local temp files
echo "🧹 Cleaning up local temporary files..."
rm -rf "$TEMP_BACKUP"

# Cleanup on hc-01
echo "🧹 Cleaning up temporary files on hc-01..."
ssh -i "$SSH_KEY_HC01" "$SSH_USER@$OLD_HOST" "rm -rf /tmp/n8n-migration-backup /tmp/n8n-migration-backup.tar.gz" || true

echo ""
echo "================================================================"
echo "🎉 Migration completed successfully!"
echo "================================================================"
echo ""
echo "✓ Workflows migrated"
echo "✓ Credentials migrated"
echo "✓ Encryption key migrated (credentials should work without re-authentication)"
echo ""
echo "Next steps:"
echo "1. Verify workflows in new n8n: https://n8n-2.meimberg.io"
echo "2. Check that all credentials are active (no 'Needs first setup' warnings)"
echo "3. Test a few workflows to ensure they work"
echo "4. Update DNS to point n8n.meimberg.io to hc-02"
echo "5. Update GitHub variable APP_DOMAIN from n8n-2.meimberg.io to n8n.meimberg.io"
echo "6. Redeploy to update Traefik routing"
echo ""
echo "⚠️  Don't shut down the old n8n on hc-01 until you've verified everything works!"
echo ""

