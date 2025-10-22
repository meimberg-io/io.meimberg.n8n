#!/bin/bash
# n8n Backup Export Script
# Exports workflows and credentials to mounted backup directory
# Designed to run inside the n8n container via cron

set -e

BACKUP_ROOT="/home/node/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# Ensure backup directories exist
mkdir -p "${BACKUP_ROOT}/workflows"
mkdir -p "${BACKUP_ROOT}/credentials"

echo "[$(date)] Starting n8n backup export..."

# Clean old exports (keep current only)
rm -rf "${BACKUP_ROOT}/workflows"/* 2>/dev/null || true
rm -rf "${BACKUP_ROOT}/credentials"/* 2>/dev/null || true

# Export workflows (as individual JSON files)
echo "[$(date)] Exporting workflows..."
n8n export:workflow --backup --output="${BACKUP_ROOT}/workflows/" 2>&1 | grep -v "Workflows exported" || true

# Export credentials (as single file with all credentials)
echo "[$(date)] Exporting credentials..."
n8n export:credentials --all --output="${BACKUP_ROOT}/credentials/credentials.json" 2>&1 | grep -v "Credentials exported" || true

# Verify exports
WORKFLOW_COUNT=$(find "${BACKUP_ROOT}/workflows" -name "*.json" 2>/dev/null | wc -l)
CRED_EXISTS=$([ -f "${BACKUP_ROOT}/credentials/credentials.json" ] && echo "yes" || echo "no")

echo "[$(date)] Export completed:"
echo "  - Workflows: ${WORKFLOW_COUNT} files"
echo "  - Credentials: ${CRED_EXISTS}"

# Create metadata file
cat > "${BACKUP_ROOT}/last_export.txt" <<EOF
Last Export: $(date)
Workflows: ${WORKFLOW_COUNT}
Credentials: ${CRED_EXISTS}
EOF

echo "[$(date)] Backup export successful"

