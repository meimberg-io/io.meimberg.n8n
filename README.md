# n8n Workflow Automation

Custom n8n deployment with OCR, PDF processing, image manipulation. Automated deployment via GitHub Actions.

## Quick Start

```bash
# Clone and setup
git clone git@github.com:meimberg-io/io.meimberg.n8n.git
cd io.meimberg.n8n
cp env.example .env

# Start local
docker compose --profile dev up

# Access: http://localhost:5678
```

## Production

Auto-deploys on push to `main`. See [doc/SETUP.md](doc/SETUP.md) for GitHub/DNS configuration.

## Custom Dependencies

- **Tesseract OCR** - Text extraction from images
- **Poppler** - PDF rendering/manipulation
- **ImageMagick, Ghostscript, GraphicsMagick** - Image processing

## Documentation

- [doc/SETUP.md](doc/SETUP.md) - GitHub Actions, DNS configuration
- [doc/OPERATIONS.md](doc/OPERATIONS.md) - Backup, monitoring, troubleshooting

## Architecture

**Local:** Docker container, port 5678, volume `n8n_data`  
**Production:** Traefik → n8n container, auto SSL, https://n8n.meimberg.io

**Data:**
- Workflows/credentials: `/home/node/.n8n` (volume `n8n_data`)
- Backups: `./backupdata` (local) or `/srv/projects/n8n/backup` (prod)

## Common Tasks

```bash
# Development
docker compose --profile dev up
docker compose --profile dev logs -f
docker exec -it n8n-dev sh

# Backup (local or prod)
docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/
docker exec n8n n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json

# Restore
docker exec n8n n8n import:workflow --separate --input=/home/node/backup/workflows/
docker exec n8n n8n import:credentials --input=/home/node/backup/credentials/credentials.json

# Update n8n version
# Edit Dockerfile, change FROM line, commit & push
```

## Environment

Key variables (`.env` local, GitHub secrets prod):

- `WEBHOOK_URL` - Webhook base URL
- `N8N_PORT` - Port (default 5678)
- `N8N_ENCRYPTION_KEY` - Credentials encryption (`openssl rand -hex 32`)
- `APP_DOMAIN`, `SERVER_HOST`, `SERVER_USER` - Production deployment

## Project Structure

```
.github/workflows/deploy.yml    # CI/CD pipeline
doc/                            # Documentation
scripts/                        # Backup/restore utilities
Dockerfile                      # Custom n8n image with dependencies
docker-compose.yml              # Dev/prod configurations
env.example                     # Environment template
```
