#!/bin/bash
# Stop n8n service

echo "Stopping n8n service..."

docker stop n8n

if [ $? -eq 0 ]; then
  echo "[SUCCESS] n8n service stopped successfully"
  docker rm n8n
else
  echo "[ERROR] Failed to stop n8n service (may not be running)"
  exit 1
fi

