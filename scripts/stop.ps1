# Stop n8n service
# PowerShell script for Windows

Write-Host "Stopping n8n service..." -ForegroundColor Cyan

docker stop n8n

if ($LASTEXITCODE -eq 0) {
  Write-Host "[SUCCESS] n8n service stopped successfully" -ForegroundColor Green
  docker rm n8n
} else {
  Write-Host "[ERROR] Failed to stop n8n service (may not be running)" -ForegroundColor Red
  exit 1
}

