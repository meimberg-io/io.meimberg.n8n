# Start n8n for local development (Windows)
# This script loads environment variables from .env file if it exists

$ProjectRoot = Split-Path $PSScriptRoot -Parent

# Load .env file if it exists
$EnvFile = Join-Path $ProjectRoot ".env"
if (Test-Path $EnvFile) {
    Write-Host "Loading environment from .env file..." -ForegroundColor Cyan
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^([^#].+?)=(.+)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

# Default values for local development
$WEBHOOK_URL = if ($env:WEBHOOK_URL) { $env:WEBHOOK_URL } else { "http://localhost:5678" }
$N8N_PORT = if ($env:N8N_PORT) { $env:N8N_PORT } else { "5678" }

# Get backup directory
$BackupDir = Join-Path $ProjectRoot "backup"
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
}

Write-Host "Starting n8n for local development..." -ForegroundColor Cyan
Write-Host "WEBHOOK_URL: $WEBHOOK_URL"
Write-Host "N8N_PORT: $N8N_PORT"
Write-Host "BACKUP_DIR: $BackupDir"
Write-Host ""
Write-Host "Access n8n at: $WEBHOOK_URL" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

# Remove any existing container
docker rm -f n8n-dev 2>$null

# Start the container (not in detached mode for development)
docker run --rm --name n8n-dev `
  -e WEBHOOK_URL="$WEBHOOK_URL" `
  -p "${N8N_PORT}:5678" `
  -v n8n_data:/home/node/.n8n `
  -v "${BackupDir}:/home/node/backup" `
  --user 1000:1000 `
  n8n-custom

