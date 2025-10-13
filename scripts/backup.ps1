#!/usr/bin/env pwsh
# n8n Backup Script
# Creates a complete backup of workflows and credentials

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BackupRoot = Join-Path $ProjectRoot "backup"

# Create backup directories
$WorkflowsDir = Join-Path $BackupRoot "workflows"
$CredentialsDir = Join-Path $BackupRoot "credentials"
New-Item -ItemType Directory -Force -Path $WorkflowsDir | Out-Null
New-Item -ItemType Directory -Force -Path $CredentialsDir | Out-Null

Write-Host "Starting n8n backup..."

# Check if container is running
$containerRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "^n8n$"
if (-not $containerRunning) {
    Write-Host "[ERROR] n8n container is not running!" -ForegroundColor Red
    exit 1
}

# Export workflows
Write-Host "Exporting workflows..."
docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows

# Export credentials (encrypted)
Write-Host "Exporting credentials..."
docker exec n8n n8n export:credentials --backup --output=/home/node/backup/credentials

# Create timestamp
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Create tar.gz archive
Write-Host "Creating backup archive..."
$CurrentLocation = Get-Location
Set-Location $BackupRoot

# Use tar (available in Windows 10 1803+)
tar -czf backup.tar.gz workflows/ credentials/

# Create timestamped copy for history
Copy-Item "backup.tar.gz" "backup_${Timestamp}.tar.gz"

Set-Location $CurrentLocation

Write-Host "[SUCCESS] Backup completed!" -ForegroundColor Green
Write-Host "📦 Current backup: $BackupRoot\backup.tar.gz"
Write-Host "📦 Historic backup: $BackupRoot\backup_${Timestamp}.tar.gz"
Write-Host ""
Write-Host "Backup contents:"
Get-ChildItem -Path $BackupRoot -Filter "backup*.tar.gz" | Format-Table Name, Length, LastWriteTime -AutoSize

