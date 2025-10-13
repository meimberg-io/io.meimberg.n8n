#!/bin/bash
# Start n8n service

# Default values
WEBHOOK_URL="${WEBHOOK_URL:-https://n8n.meimberg.io}"
N8N_PORT="${N8N_PORT:-5678}"

echo "Starting n8n service..."
echo "WEBHOOK_URL: $WEBHOOK_URL"
echo "N8N_PORT: $N8N_PORT"

# Remove any existing container
docker rm -f n8n 2>/dev/null || true

# Determine user:group to run container as
# On production (/opt/n8n exists), use current user
# On local dev, use 1000:1000 (default node user)
if [ -d "/opt/n8n" ]; then
  DOCKER_USER="$(id -u):$(id -g)"
else
  DOCKER_USER="1000:1000"
fi

echo "Starting container as user: $DOCKER_USER"

# Start the container
docker run -d --name n8n \
  -e WEBHOOK_URL="$WEBHOOK_URL" \
  -p ${N8N_PORT}:5678 \
  -v n8n_data:/home/node/.n8n \
  -v /opt/n8n/backup:/home/node/backup \
  --user $DOCKER_USER \
  --restart always \
  n8n-custom

if [ $? -eq 0 ]; then
  echo "[SUCCESS] n8n service started successfully"
  docker ps | grep n8n
else
  echo "[ERROR] Failed to start n8n service"
  exit 1
fi

