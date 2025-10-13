#!/bin/bash
# Start n8n for local development
# This script loads environment variables from .env file if it exists

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load .env file if it exists
if [ -f "$PROJECT_ROOT/.env" ]; then
  echo "Loading environment from .env file..."
  export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
fi

# Default values for local development
WEBHOOK_URL="${WEBHOOK_URL:-http://localhost:5678}"
N8N_PORT="${N8N_PORT:-5678}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/backup}"

echo "Starting n8n for local development..."
echo "WEBHOOK_URL: $WEBHOOK_URL"
echo "N8N_PORT: $N8N_PORT"
echo "BACKUP_DIR: $BACKUP_DIR"
echo ""
echo "Access n8n at: $WEBHOOK_URL"
echo "Press Ctrl+C to stop"
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Remove any existing container
docker rm -f n8n-dev 2>/dev/null || true

# Start the container (not in detached mode for development)
docker run --rm --name n8n-dev \
  -e WEBHOOK_URL="$WEBHOOK_URL" \
  -p ${N8N_PORT}:5678 \
  -v n8n_data:/home/node/.n8n \
  -v "$BACKUP_DIR:/home/node/backup" \
  --user 1000:1000 \
  n8n-custom

