# Start n8n service
# PowerShell script for Windows

# Default values
$WEBHOOK_URL = if ($env:WEBHOOK_URL) { $env:WEBHOOK_URL } else { "https://n8n.meimberg.io" }
$N8N_PORT = if ($env:N8N_PORT) { $env:N8N_PORT } else { "5678" }

# Get the backup directory relative to the script location
$BackupDir = Join-Path $PSScriptRoot "..\backup"
$BackupDir = (Resolve-Path $BackupDir -ErrorAction SilentlyContinue).Path
if (-not $BackupDir) {
    # If backup dir doesn't exist, create it
    $BackupDir = Join-Path (Split-Path $PSScriptRoot -Parent) "backup"
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
}

Write-Host "Starting n8n service..." -ForegroundColor Cyan
Write-Host "WEBHOOK_URL: $WEBHOOK_URL"
Write-Host "N8N_PORT: $N8N_PORT"
Write-Host "BACKUP_DIR: $BackupDir"

# Remove any existing container
Write-Host "Removing existing container (if any)..."
docker rm -f n8n 2>$null

# Start the container
Write-Host "Starting new container..."
docker run -d --name n8n `
  -e WEBHOOK_URL="$WEBHOOK_URL" `
  -p "${N8N_PORT}:5678" `
  -v n8n_data:/home/node/.n8n `
  -v "${BackupDir}:/home/node/backup" `
  --user 1000:1000 `
  --restart always `
  n8n-custom

if ($LASTEXITCODE -eq 0) {
  Write-Host "[SUCCESS] n8n service started successfully" -ForegroundColor Green
  docker ps | Select-String "n8n"
} else {
  Write-Host "[ERROR] Failed to start n8n service" -ForegroundColor Red
  exit 1
}

