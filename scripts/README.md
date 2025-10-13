# n8n Deployment Scripts

Scripts for managing the n8n Docker container on Linux/Unix/macOS and Windows.

## Production Scripts

| Linux/Unix | Windows | Description |
|------------|---------|-------------|
| `start.sh` | `start.ps1` | Start n8n (detached) |
| `stop.sh` | `stop.ps1` | Stop n8n |
| `restart.sh` | `restart.ps1` | Restart n8n |

## Development Scripts

| Linux/Unix | Windows | Description |
|------------|---------|-------------|
| `build.sh` | `build.ps1` | Build Docker image |
| `dev.sh` | `dev.ps1` | Start n8n (interactive) |

## Backup & Restore Scripts

| Linux/Unix | Windows | Description |
|------------|---------|-------------|
| `backup.sh` | `backup.ps1` | Create backup (workflows + credentials) |
| `restore.sh` | `restore.ps1` | Restore from backup |
| `sync-from-prod.sh` | `sync-from-prod.ps1` | Sync production data to local dev |

## Usage

### Linux/Unix/macOS
```bash
# Build
./scripts/build.sh

# Development
./scripts/dev.sh

# Production
./scripts/start.sh
./scripts/stop.sh
./scripts/restart.sh

# Backup & Restore
./scripts/backup.sh           # Create backup
./scripts/restore.sh          # Restore backup
./scripts/sync-from-prod.sh   # Sync from production
```

### Windows
```powershell
# Build
.\scripts\build.ps1

# Development
.\scripts\dev.ps1

# Production
.\scripts\start.ps1
.\scripts\stop.ps1
.\scripts\restart.ps1

# Backup & Restore
.\scripts\backup.ps1           # Create backup
.\scripts\restore.ps1          # Restore backup
.\scripts\sync-from-prod.ps1   # Sync from production
```

## Configuration

Environment variables (optional):

| Variable | Default | Description |
|----------|---------|-------------|
| `WEBHOOK_URL` | `https://n8n.meimberg.io` | n8n webhook base URL |
| `N8N_PORT` | `5678` | Port to expose |

**Example:**
```bash
export WEBHOOK_URL="https://n8n.example.com"
export N8N_PORT="8080"
./scripts/start.sh
```

## Notes

**Production scripts** (`start`, `stop`, `restart`):
- Run detached (background)
- Container name: `n8n`
- Restart policy: `always`

**Development scripts** (`dev`):
- Run foreground (see logs)
- Container name: `n8n-dev`
- Auto-remove on stop
- Loads `.env` file if present

**Backup scripts**:
- Creates `backup.tar.gz` with workflows and credentials
- Also creates timestamped copy: `backup_YYYY-MM-DD_HH-MM-SS.tar.gz`
- Workflows saved to: `backup/workflows/`
- Credentials saved to: `backup/credentials/` (encrypted)

**Sync script**:
- Requires production SSH config in `.env` (copy from `env.example`)
- Triggers backup on production, downloads it, and restores locally
- Useful for testing with real production data

## See Also

- [Local Development Guide](../doc/local-development.md)
- [Production Setup](../doc/production-setup.md)
- [Operations Guide](../doc/operations.md) - Backup strategies
