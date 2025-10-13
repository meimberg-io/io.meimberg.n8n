#!/usr/bin/env pwsh
# Sync n8n data from Production to Local Development
# This script:
# 1. Triggers backup on production server via SSH
# 2. Downloads the backup via SCP
# 3. Restores it to local dev instance

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $ProjectRoot ".env"

# Load environment variables from .env
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
} else {
    Write-Host "[ERROR] .env file not found!" -ForegroundColor Red
    Write-Host "Copy env.example to .env and configure production SSH settings"
    exit 1
}

# Check required variables
if (-not $env:PROD_SSH_HOST -or -not $env:PROD_SSH_USER -or -not $env:PROD_SSH_KEY) {
    Write-Host "[ERROR] Missing production SSH configuration in .env" -ForegroundColor Red
    Write-Host "Required variables: PROD_SSH_HOST, PROD_SSH_USER, PROD_SSH_KEY"
    exit 1
}

# Expand paths
$SshKey = $env:PROD_SSH_KEY -replace '^~', $env:USERPROFILE

# Check if SSH key exists
if (-not (Test-Path $SshKey)) {
    Write-Host "[ERROR] SSH key not found: $SshKey" -ForegroundColor Red
    exit 1
}

# Set defaults
$SshPort = if ($env:PROD_SSH_PORT) { $env:PROD_SSH_PORT } else { "22" }
$AppDir = if ($env:PROD_APP_DIR) { $env:PROD_APP_DIR } else { "/opt/n8n" }

Write-Host "Syncing n8n data from production..."
Write-Host "   Host: $env:PROD_SSH_USER@$env:PROD_SSH_HOST:$SshPort"
Write-Host "   Directory: $AppDir"
Write-Host ""

# Step 1: Trigger backup on production
Write-Host "Step 1/3: Creating backup on production..."

& ssh -i $SshKey -p $SshPort "$($env:PROD_SSH_USER)@$($env:PROD_SSH_HOST)" "cd /opt/n8n/deploy && ./scripts/backup.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create backup on production" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Download backup
Write-Host "Step 2/3: Downloading backup from production..."
$BackupRoot = Join-Path $ProjectRoot "backup"
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null

& scp -i $SshKey -P $SshPort "$($env:PROD_SSH_USER)@$($env:PROD_SSH_HOST):$AppDir/deploy/backup/backup.tar.gz" "$BackupRoot\backup.tar.gz"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to download backup from production" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Restore to local
Write-Host "Step 3/3: Restoring backup to local dev instance..."
& "$ScriptDir\restore.ps1"

Write-Host ""
Write-Host "[SUCCESS] Production data synced to local development!" -ForegroundColor Green
Write-Host ""
Write-Host "WARNING: Remember to restart your local n8n:"
Write-Host "   .\scripts\restart.ps1 (if running in background)"
Write-Host "   Or restart your dev.ps1 session"

