#!/usr/bin/env pwsh
# n8n Restore Script
# Restores workflows and credentials from backup

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BackupRoot = Join-Path $ProjectRoot "backup"
$BackupFile = Join-Path $BackupRoot "backup.tar.gz"

# Check if backup exists
if (-not (Test-Path $BackupFile)) {
    Write-Host "[ERROR] No backup found at $BackupFile" -ForegroundColor Red
    Write-Host "Available backups:"
    Get-ChildItem -Path $BackupRoot -Filter "backup_*.tar.gz" -ErrorAction SilentlyContinue | Format-Table Name, Length, LastWriteTime
    exit 1
}

Write-Host "Starting n8n restore..."

# Check if container is running
$containerRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "^n8n"
if (-not $containerRunning) {
    Write-Host "[ERROR] n8n container is not running!" -ForegroundColor Red
    Write-Host "Start n8n first with: .\scripts\start.ps1 or .\scripts\dev.ps1"
    exit 1
}

# Extract backup
Write-Host "Extracting backup..."
$CurrentLocation = Get-Location
Set-Location $BackupRoot
tar -xzf backup.tar.gz
Set-Location $CurrentLocation

# Import workflows
Write-Host "Importing workflows..."
$WorkflowsDir = Join-Path $BackupRoot "workflows"
if (Test-Path $WorkflowsDir) {
    $workflows = Get-ChildItem -Path $WorkflowsDir -Filter "*.json"
    foreach ($workflow in $workflows) {
        Write-Host "Importing $($workflow.Name)..."
        docker exec n8n n8n import:workflow --input="/home/node/backup/workflows/$($workflow.Name)"
    }
} else {
    Write-Host "[WARNING] No workflows directory found in backup" -ForegroundColor Yellow
}

# Import credentials
Write-Host "Importing credentials..."
$CredentialsDir = Join-Path $BackupRoot "credentials"
if (Test-Path $CredentialsDir) {
    $credentials = Get-ChildItem -Path $CredentialsDir -Filter "*.json"
    foreach ($credential in $credentials) {
        Write-Host "Importing $($credential.Name)..."
        docker exec n8n n8n import:credentials --input="/home/node/backup/credentials/$($credential.Name)"
    }
} else {
    Write-Host "[WARNING] No credentials directory found in backup" -ForegroundColor Yellow
}

Write-Host "[SUCCESS] Restore completed!" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  You may need to restart n8n for all changes to take effect:"
Write-Host "   .\scripts\restart.ps1"

