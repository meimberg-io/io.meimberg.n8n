# Restart n8n service
# PowerShell script for Windows

Write-Host "Restarting n8n service..." -ForegroundColor Cyan

# Stop the service (if running)
Write-Host "Stopping existing service..."
& "$PSScriptRoot\stop.ps1" 2>$null

# Wait a moment
Start-Sleep -Seconds 2

# Start the service
Write-Host "Starting service..."
& "$PSScriptRoot\start.ps1"

if ($LASTEXITCODE -eq 0) {
  Write-Host "[SUCCESS] n8n service restarted successfully" -ForegroundColor Green
} else {
  Write-Host "[ERROR] Failed to restart n8n service" -ForegroundColor Red
  exit 1
}

