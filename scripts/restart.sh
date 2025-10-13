#!/bin/bash
# Restart n8n service

echo "Restarting n8n service..."

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Stop the service (if running)
"$SCRIPT_DIR/stop.sh" 2>/dev/null || true

# Wait a moment
sleep 2

# Start the service
"$SCRIPT_DIR/start.sh"

if [ $? -eq 0 ]; then
  echo "[SUCCESS] n8n service restarted successfully"
else
  echo "[ERROR] Failed to restart n8n service"
  exit 1
fi

