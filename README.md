# n8n Workflow Automation Platform

Custom n8n deployment for meimberg.io infrastructure with enhanced dependencies and automated CI/CD.

## What is n8n?

n8n is a powerful workflow automation tool that connects various services and APIs. This deployment includes custom dependencies for document processing (OCR, PDF manipulation, image processing).

## Quick Start

### Local Development

**Prerequisites:**
- Docker and Docker Compose
- Git

**Setup:**
```bash
# Clone repository
git clone git@github.com:meimberg-io/io.meimberg.n8n.git
cd io.meimberg.n8n

# Copy environment file
cp env.example .env

# Edit .env (optional - defaults work for local dev)
# Set WEBHOOK_URL, N8N_PORT, etc.

# Start n8n
docker compose --profile dev up

# Access at http://localhost:5678
```

**First login:**
1. Open http://localhost:5678
2. Create your admin account
3. Start building workflows!

### Production Deployment

Automated deployment via GitHub Actions on push to `main` branch.

**See:** [GITHUB-SETUP.md](doc/GITHUB-SETUP.md) for initial setup.

---

## Custom Features

This n8n deployment includes additional system dependencies for enhanced functionality:

| Package | Purpose |
|---------|---------|
| **Tesseract OCR** | Optical character recognition |
| **Poppler** | PDF rendering and manipulation |
| **ImageMagick** | Image processing and conversion |
| **Ghostscript** | PostScript/PDF interpreter |
| **GraphicsMagick** | Image processing toolkit |

These enable workflows that process documents, extract text from images, convert PDFs, and manipulate images.

---

## Documentation

### 📋 Quick Reference
- **[SETUP-CHECKLIST.md](doc/SETUP-CHECKLIST.md)** - Step-by-step setup guide
- **[README.md](README.md)** - This file (overview)

### 🚀 Deployment
- **[GITHUB-SETUP.md](doc/GITHUB-SETUP.md)** - GitHub configuration and first deployment
- **[DEPLOYMENT.md](doc/DEPLOYMENT.md)** - Operations, monitoring, and troubleshooting
- **[DOCKER-COMPOSE.md](doc/DOCKER-COMPOSE.md)** - Local development with Docker Compose

### 📚 External Resources
- [n8n Documentation](https://docs.n8n.io/) - Official n8n docs
- [n8n Community](https://community.n8n.io/) - Community forum
- [n8n Workflows](https://n8n.io/workflows/) - Workflow templates
- [Ansible Structure](../io.meimberg.meta/doc/ANSIBLE-STRUCTURE.md) - Infrastructure overview

---

## Architecture

### Local Development
```
┌─────────────────┐
│   Docker Host   │
│                 │
│  ┌───────────┐  │
│  │  n8n-dev  │  │  Port: 5678
│  │           │  │  Volume: n8n_data
│  │  Custom   │  │  Mount: ./backupdata
│  │  Image    │  │
│  └───────────┘  │
│                 │
└─────────────────┘
```

### Production
```
┌──────────────────────────────────────┐
│           Server (hc-02)             │
│                                      │
│  ┌────────────┐      ┌───────────┐  │
│  │  Traefik   │◄────►│    n8n    │  │
│  │   Proxy    │      │ Container │  │
│  │            │      │           │  │
│  │ Auto SSL   │      │  Volume:  │  │
│  │ Let's      │      │ n8n_data  │  │
│  │ Encrypt    │      │           │  │
│  └────────────┘      └───────────┘  │
│        │                    │        │
│        │                    │        │
│   Port 443 (HTTPS)    Port 5678     │
│                         (internal)   │
└──────────────────────────────────────┘
         │
         ▼
   n8n.meimberg.io
```

### Data Storage

- **Workflows & Credentials**: Docker volume `n8n_data` (`/home/node/.n8n`)
- **Exports/Backups**: Host directory `/srv/projects/n8n/backup` (prod) or `./backupdata` (dev)
- **Database**: SQLite (default) at `/home/node/.n8n/database.sqlite`

---

## Common Tasks

### Development

```bash
# Start development environment
docker compose --profile dev up

# View logs
docker compose --profile dev logs -f

# Access container shell
docker exec -it n8n-dev sh

# Stop
docker compose --profile dev down
```

### Backup & Restore

```bash
# Export workflows
docker exec n8n-dev n8n export:workflow --backup --output=/home/node/backup/workflows/

# Export credentials
docker exec n8n-dev n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json

# Import workflows
docker exec n8n-dev n8n import:workflow --separate --input=/home/node/backup/workflows/

# Import credentials
docker exec n8n-dev n8n import:credentials --input=/home/node/backup/credentials/credentials.json
```

For production backups, see [DEPLOYMENT.md](doc/DEPLOYMENT.md#backups-and-restore).

### Sync Production to Local

Test with real production data locally:

```bash
# Configure production SSH in .env
# PROD_SSH_HOST=hc-02.meimberg.io
# PROD_SSH_USER=deploy
# PROD_APP_DIR=/srv/projects/n8n

# Run sync script
./scripts/sync-from-prod.sh  # Linux/macOS
# or
.\scripts\sync-from-prod.ps1  # Windows
```

---

## Environment Variables

Configure in `.env` file (copy from `env.example`):

### Local Development

| Variable | Default | Description |
|----------|---------|-------------|
| `WEBHOOK_URL` | `http://localhost:5678` | Webhook base URL |
| `N8N_PORT` | `5678` | Port to expose |
| `GENERIC_TIMEZONE` | `Europe/Berlin` | Timezone |
| `N8N_BASIC_AUTH_ACTIVE` | `false` | Enable basic auth |
| `N8N_ENCRYPTION_KEY` | - | Credentials encryption |

### Production (via GitHub Variables)

| Variable | Value | Description |
|----------|-------|-------------|
| `WEBHOOK_URL` | `https://n8n.meimberg.io` | Production webhook URL |
| `APP_DOMAIN` | `n8n.meimberg.io` | Domain name |
| `SERVER_HOST` | `hc-02.meimberg.io` | Server hostname |
| `SERVER_USER` | `deploy` | SSH user |

See [GITHUB-SETUP.md](doc/GITHUB-SETUP.md) for configuration.

---

## Deployment Pipeline

Every push to `main` triggers:

1. ✅ **Build** - Custom Docker image with dependencies
2. ✅ **Push** - To GitHub Container Registry
3. ✅ **Deploy** - SSH to server, copy docker-compose.prod.yml template
4. ✅ **Process** - Use envsubst to substitute environment variables
5. ✅ **Start** - Pull image and start container
6. ✅ **Verify** - Check container is running
7. ✅ **SSL** - Traefik automatically provisions Let's Encrypt certificate

**Monitor:** https://github.com/meimberg-io/io.meimberg.n8n/actions

---

## Updating n8n

To update the n8n version:

```bash
# Edit Dockerfile
vim Dockerfile

# Change version
FROM docker.n8n.io/n8nio/n8n:1.120.0  # Update version

# Commit and push
git add Dockerfile
git commit -m "chore: update n8n to v1.120.0"
git push origin main
```

GitHub Actions automatically builds and deploys the new version.

**Check current version:**
```bash
# Local
docker exec n8n-dev n8n --version

# Production
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n --version"
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose --profile dev logs

# Rebuild image
docker compose --profile dev build --no-cache
docker compose --profile dev up
```

### Port Already in Use

```bash
# Find process using port 5678
sudo lsof -i :5678

# Or change port in .env
echo "N8N_PORT=8080" >> .env
```

### Workflows Not Persisting

```bash
# Verify volume exists
docker volume ls | grep n8n_data

# Check volume is mounted
docker inspect n8n-dev | grep -A 10 Mounts
```

### Production Issues

See [DEPLOYMENT.md](doc/DEPLOYMENT.md#troubleshooting) for production troubleshooting.

---

## Scripts

Utility scripts in `scripts/` directory:

| Script | Purpose |
|--------|---------|
| `backup.sh` / `backup.ps1` | Export workflows and credentials |
| `restore.sh` / `restore.ps1` | Import workflows and credentials |
| `sync-from-prod.sh` / `sync-from-prod.ps1` | Download production data |

**Note:** These scripts work with both local dev and production environments.

---

## Security

### Credentials Encryption

n8n encrypts credentials at rest using `N8N_ENCRYPTION_KEY`. Generate a secure key:

```bash
openssl rand -hex 32
```

Add to `.env` (local) or GitHub Secrets (production).

### HTTPS/SSL

Production deployment uses:
- **Traefik** reverse proxy
- **Let's Encrypt** automatic SSL certificates
- **HTTPS** enforcement (HTTP redirects to HTTPS)

### Access Control

Consider enabling basic authentication:

```env
# In .env
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password
```

Or use Traefik middleware for IP whitelisting, OAuth, etc.

---

## Contributing

### Making Changes

```bash
# Create feature branch
git checkout -b feature/my-change

# Make changes
# Test locally with: docker compose --profile dev up

# Commit
git add .
git commit -m "feat: add my feature"

# Push (but don't merge to main yet)
git push origin feature/my-change

# Create PR for review
```

### Adding System Dependencies

To add Alpine packages:

```bash
# Edit Dockerfile
vim Dockerfile

# Add package to RUN command
RUN apk update && apk add --no-cache \
    perl \
    poppler-utils \
    imagemagick \
    ghostscript \
    graphicsmagick \
    your-new-package

# Test locally
docker compose --profile dev build --no-cache
docker compose --profile dev up

# Commit and push
git add Dockerfile
git commit -m "feat: add your-new-package"
git push origin main
```

### Installing Community Nodes

```bash
# Edit Dockerfile
vim Dockerfile

# Add after system packages
USER node
WORKDIR /home/node/.n8n/nodes
RUN npm install n8n-nodes-package-name

# Test, commit, push
```

---

## Tech Stack

| Component | Version/Type | Purpose |
|-----------|-------------|---------|
| **n8n** | 1.115.2 | Workflow automation |
| **Docker** | Latest | Containerization |
| **Alpine Linux** | Latest | Base OS |
| **Tesseract** | Latest | OCR |
| **ImageMagick** | Latest | Image processing |
| **Poppler** | Latest | PDF tools |
| **Traefik** | v2+ | Reverse proxy (prod) |
| **Let's Encrypt** | - | SSL certificates (prod) |
| **GitHub Actions** | - | CI/CD pipeline |

---

## Project Structure

```
io.meimberg.n8n/
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
├── doc/
│   ├── SETUP-CHECKLIST.md      # Quick setup guide
│   ├── GITHUB-SETUP.md         # GitHub configuration
│   ├── DEPLOYMENT.md           # Operations guide
│   └── DOCKER-COMPOSE.md       # Docker usage
├── scripts/
│   ├── backup.sh/.ps1          # Backup utility
│   ├── restore.sh/.ps1         # Restore utility
│   └── sync-from-prod.sh/.ps1  # Sync from production
├── backupdata/                 # Local backup directory
│   ├── workflows/              # Exported workflows
│   └── credentials/            # Exported credentials
├── Dockerfile                  # Custom n8n image
├── docker-compose.yml          # Unified dev/prod compose
├── docker-compose.prod.yml     # Reference: production compose
├── env.example                 # Environment template
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

---

## Support

### Documentation
- Check `doc/` directory for detailed guides
- Review [n8n official documentation](https://docs.n8n.io/)

### Common Issues
- [DEPLOYMENT.md - Troubleshooting](doc/DEPLOYMENT.md#troubleshooting)
- [DOCKER-COMPOSE.md - Troubleshooting](doc/DOCKER-COMPOSE.md#troubleshooting)

### Community
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub Issues](https://github.com/n8n-io/n8n/issues)

---

## License

This deployment configuration is part of the meimberg.io infrastructure. n8n itself is licensed under the [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).

---

**Last Updated:** October 2025  
**n8n Version:** 1.115.2  
**Infrastructure:** meimberg.io / Ansible-managed
