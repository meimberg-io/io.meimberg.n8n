#!/bin/bash
# Build the n8n custom Docker image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Building n8n custom Docker image..."
cd "$PROJECT_ROOT"

docker build -t n8n-custom .

if [ $? -eq 0 ]; then
  echo "[SUCCESS] Docker image built successfully"
  docker images | grep n8n-custom
else
  echo "[ERROR] Failed to build Docker image"
  exit 1
fi

