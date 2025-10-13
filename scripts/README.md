# n8n Deployment Scripts

This directory contains scripts for managing the n8n Docker container on both Linux/Unix and Windows systems.

## Available Scripts

### For Linux/Unix/macOS

#### Production Scripts
- `start.sh` - Start the n8n container in production mode (detached)
- `stop.sh` - Stop the n8n container
- `restart.sh` - Restart the n8n container

#### Development Scripts
- `build.sh` - Build the custom n8n Docker image
- `dev.sh` - Start n8n in development mode (interactive, with console output)

**Usage:**
```bash
# Build the image first
./scrips/build.sh

# Development
./scrips/dev.sh

# Production
./scrips/start.sh
./scrips/stop.sh
./scrips/restart.sh
```

### For Windows

#### Production Scripts
- `start.ps1` - Start the n8n container in production mode (detached)
- `stop.ps1` - Stop the n8n container
- `restart.ps1` - Restart the n8n container

#### Development Scripts
- `build.ps1` - Build the custom n8n Docker image
- `dev.ps1` - Start n8n in development mode (interactive, with console output)

**Usage:**
```powershell
# Build the image first
.\scrips\build.ps1

# Development
.\scrips\dev.ps1

# Production
.\scrips\start.ps1
.\scrips\stop.ps1
.\scrips\restart.ps1
```

## Configuration

All scripts support environment variables for configuration:

| Variable | Description | Default |
|----------|-------------|---------|
| `WEBHOOK_URL` | n8n webhook base URL | `https://n8n.meimberg.io` |
| `N8N_PORT` | Port to expose n8n on the host | `5678` |

### Linux/Unix Example
```bash
export WEBHOOK_URL="https://n8n.example.com"
export N8N_PORT="8080"
./scrips/start.sh
```

### Windows Example
```powershell
$env:WEBHOOK_URL = "https://n8n.example.com"
$env:N8N_PORT = "8080"
.\scrips\start.ps1
```

## Prerequisites

- Docker must be installed and running
- Docker volume `n8n_data` must exist
- **Linux/Unix:** Backup directory `/opt/n8n/backup` should exist (production)
- **Windows/Development:** Backup directory will be automatically created at `backup` in the project root

## Troubleshooting

### Linux/Unix
If you get "Permission denied":
```bash
chmod +x scrips/*.sh
```

### Windows
If you get an execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Notes

### Production Scripts (`start`, `stop`, `restart`)
- Automatically remove any existing `n8n` container before starting
- Containers run in detached mode (background)
- Started with `--restart always` policy for automatic restarts
- Container name: `n8n`

### Development Scripts (`dev`)
- Run in foreground with console output for debugging
- Load environment variables from `.env` file if present
- Automatically remove container on stop (Ctrl+C)
- Container name: `n8n-dev` (separate from production)
- Use `--rm` flag (no restart policy)

### Data Storage
- All data is persisted in the `n8n_data` Docker volume
- **Linux/Unix:** Backups are stored in `/opt/n8n/backup` (production) or `./backup` (development)
- **Windows:** Backups are stored in the `backup` folder at the project root (automatically created)

For detailed local development instructions, see [doc/local-development.md](../doc/local-development.md)

