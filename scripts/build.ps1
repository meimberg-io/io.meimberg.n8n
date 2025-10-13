# Build the n8n custom Docker image (Windows)

$ProjectRoot = Split-Path $PSScriptRoot -Parent

Write-Host "Building n8n custom Docker image..." -ForegroundColor Cyan
Set-Location $ProjectRoot

docker build -t n8n-custom .

if ($LASTEXITCODE -eq 0) {
  Write-Host "[SUCCESS] Docker image built successfully" -ForegroundColor Green
  docker images | Select-String "n8n-custom"
} else {
  Write-Host "[ERROR] Failed to build Docker image" -ForegroundColor Red
  exit 1
}

