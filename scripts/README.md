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

## See Also

- [Local Development Guide](../doc/local-development.md)
- [Production Setup](../doc/production-setup.md)
