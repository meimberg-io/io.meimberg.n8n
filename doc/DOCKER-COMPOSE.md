# Docker Compose Usage

Guide for using Docker Compose in local development and testing.

## Available Files

### 1. `docker-compose.yml` (Unified with Profiles)

Single file with both dev and prod configurations using profiles.

**Usage:**
```bash
# Development mode (with volumes)
docker compose --profile dev up

# Production mode (test production build)
docker compose --profile prod up

# Rebuild and start
docker compose --profile dev up --build

# In background
docker compose --profile dev up -d

# View logs
docker compose --profile dev logs -f

# Stop
docker compose --profile dev down
```

### 2. `docker-compose.prod.yml` (Production Template)

This file is a template that GitHub Actions copies to the server and processes with `envsubst` to substitute environment variables. It includes Traefik labels for automatic SSL and routing.

**What it contains:**
- Pre-built image from GitHub Container Registry (variable: `${DOCKER_IMAGE}`)
- Traefik labels for routing and SSL (variable: `${APP_DOMAIN}`)
- External traefik network
- Production environment variables (variable: `${WEBHOOK_URL}`)

**How it's used:**
1. GitHub Actions copies this file to `/srv/projects/n8n/docker-compose.prod.yml`
2. Server uses `envsubst` to replace `${VARIABLE}` placeholders
3. Output becomes the actual `docker-compose.yml` used in production

---

## Quick Commands

### Development Workflow

```bash
# 1. Copy environment file
cp env.example .env

# 2. Edit .env with your values
# Set WEBHOOK_URL, N8N_PORT, etc.

# 3. Start development container
docker compose --profile dev up

# 4. Access n8n at http://localhost:5678

# 5. Stop
docker compose --profile dev down
```

### Production Testing

```bash
# Test production build locally
docker compose --profile prod up --build

# Access at http://localhost:5678
```

### Rebuild

```bash
# Force rebuild
docker compose --profile dev build --no-cache

# Rebuild and start
docker compose --profile dev up --build
```

---

## Features

### Development Mode (`--profile dev`)

✅ **Persistent data** - Uses Docker volume `n8n_data`  
✅ **Backup directory** - Mounts `./backupdata` for exports  
✅ **Isolated environment** - Consistent across machines  
✅ **Health checks** - Monitor container health  
✅ **Custom dependencies** - Includes Tesseract, Poppler, ImageMagick

**Mounted directories:**
- `n8n_data` volume → `/home/node/.n8n` (workflows, credentials, database)
- `./backupdata` → `/home/node/backup` (backup exports)

### Production Mode (`--profile prod`)

✅ **Production build** - Tests the exact production configuration  
✅ **Separate volume** - Uses `n8n_data_prod` to avoid conflicts  
✅ **Same image** - Built from same Dockerfile as production  
✅ **Environment variables** - Can test with production-like settings

---

## Environment Variables

Configure in `.env` file:

| Variable | Default | Description |
|----------|---------|-------------|
| `WEBHOOK_URL` | `http://localhost:5678` | Webhook base URL |
| `N8N_PORT` | `5678` | Port to expose n8n |
| `GENERIC_TIMEZONE` | `Europe/Berlin` | n8n timezone |
| `TZ` | `Europe/Berlin` | Container timezone |
| `N8N_LOG_LEVEL` | `info` | Log verbosity (error, warn, info, debug) |
| `N8N_BASIC_AUTH_ACTIVE` | `false` | Enable basic auth |
| `N8N_BASIC_AUTH_USER` | - | Basic auth username |
| `N8N_BASIC_AUTH_PASSWORD` | - | Basic auth password |
| `N8N_ENCRYPTION_KEY` | - | Credentials encryption key |

**Example `.env`:**
```env
WEBHOOK_URL=http://localhost:5678
N8N_PORT=5678
GENERIC_TIMEZONE=Europe/Berlin
TZ=Europe/Berlin
N8N_LOG_LEVEL=info

# Optional: Basic auth
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password

# Optional: Encryption key (generate with: openssl rand -hex 32)
N8N_ENCRYPTION_KEY=your_encryption_key_here
```

---

## Common Tasks

### View Logs

```bash
# Real-time logs
docker compose --profile dev logs -f

# Last 100 lines
docker compose --profile dev logs --tail 100

# Logs for specific service
docker logs n8n-dev -f
```

### Access Container Shell

```bash
# Enter container
docker compose --profile dev exec n8n-dev sh

# Or directly
docker exec -it n8n-dev sh

# Once inside:
n8n --version
ls -la /home/node/.n8n
```

### Restart Container

```bash
# Graceful restart
docker compose --profile dev restart

# Stop and start
docker compose --profile dev down
docker compose --profile dev up -d
```

### Clean Up

```bash
# Stop and remove containers
docker compose --profile dev down

# Stop and remove with volumes (⚠️ deletes data)
docker compose --profile dev down -v

# Remove old images
docker image prune -f
```

### Run Commands in Container

```bash
# Check n8n version
docker compose --profile dev exec n8n-dev n8n --version

# Export workflows
docker compose --profile dev exec n8n-dev n8n export:workflow --backup --output=/home/node/backup/workflows/

# Import workflows
docker compose --profile dev exec n8n-dev n8n import:workflow --separate --input=/home/node/backup/workflows/
```

---

## Volumes

### Data Volume (`n8n_data`)

Stores all n8n data:
- Workflows
- Credentials (encrypted)
- Execution history
- SQLite database
- Settings

**Location:** `/var/lib/docker/volumes/n8n_data/_data`

**Inspect volume:**
```bash
docker volume inspect n8n_data
```

**Backup volume:**
```bash
# Create backup
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n_data_backup.tar.gz -C /data .

# Restore backup
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/n8n_data_backup.tar.gz"
```

### Backup Directory (`./backupdata`)

Mounted directory for workflow/credential exports:
- `backupdata/workflows/` - Workflow JSON files
- `backupdata/credentials/` - Encrypted credentials JSON

**Note:** This directory is git-ignored (only `.gitkeep` is tracked).

---

## Networking

### Local Network

Development and prod containers use `n8n-network` bridge network.

**Inspect network:**
```bash
docker network inspect n8n-network
```

### Port Mapping

Default: `5678:5678` (host:container)

**Change host port:**
```env
# In .env
N8N_PORT=8080
```

Then access at `http://localhost:8080`

### Access from Other Containers

If you have other containers that need to call n8n:

```yaml
# In another docker-compose.yml
services:
  other-app:
    # ...
    networks:
      - n8n-network
    environment:
      - N8N_URL=http://n8n-dev:5678

networks:
  n8n-network:
    external: true
```

---

## Health Checks

The container includes health checks:

```yaml
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5678/healthz"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Check health status:**
```bash
docker inspect n8n-dev | grep -A 10 Health
```

---

## Troubleshooting

### Port Already in Use

```bash
# Find what's using port 5678
sudo lsof -i :5678
# or
sudo netstat -tlnp | grep 5678

# Change port in .env
echo "N8N_PORT=8080" >> .env
```

### Container Won't Start

```bash
# Check logs
docker compose --profile dev logs

# Check if image built successfully
docker images | grep n8n

# Rebuild without cache
docker compose --profile dev build --no-cache
```

### Volume Permission Issues

```bash
# Check volume ownership
docker volume inspect n8n_data

# Fix permissions (if needed)
docker run --rm -v n8n_data:/data alpine chown -R 1000:1000 /data
```

### Cannot Access n8n UI

```bash
# Check container is running
docker ps | grep n8n

# Check port mapping
docker port n8n-dev

# Test connection
curl http://localhost:5678

# Check logs for errors
docker logs n8n-dev
```

### Data Not Persisting

```bash
# Verify volume exists
docker volume ls | grep n8n_data

# Check volume is mounted
docker inspect n8n-dev | grep -A 10 Mounts

# Volume should be mounted at /home/node/.n8n
```

### Backup Directory Empty

```bash
# Check directory exists
ls -la ./backupdata

# Check mount in container
docker compose --profile dev exec n8n-dev ls -la /home/node/backup

# Export workflows manually
docker compose --profile dev exec n8n-dev n8n export:workflow --backup --output=/home/node/backup/workflows/
```

---

## Advanced Configuration

### Using PostgreSQL Instead of SQLite

Create a `docker-compose.override.yml`:

```yaml
services:
  n8n-dev:
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=n8n_password
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=n8n
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=n8n_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - n8n-network

volumes:
  postgres_data:
```

Then run:
```bash
docker compose --profile dev -f docker-compose.yml -f docker-compose.override.yml up
```

### Resource Limits

Create `docker-compose.override.yml`:

```yaml
services:
  n8n-dev:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          memory: 512M
```

### Custom n8n Configuration

Add to `.env`:

```env
# Execution settings
N8N_PAYLOAD_SIZE_MAX=16
EXECUTIONS_PROCESS=main
EXECUTIONS_TIMEOUT=300
EXECUTIONS_TIMEOUT_MAX=3600

# Workflow settings
WORKFLOWS_DEFAULT_NAME=My Workflow

# Security
N8N_SECURE_COOKIE=true
N8N_BLOCK_ENV_ACCESS_IN_NODE=true
```

---

## Production Deployment

**Don't use docker-compose.yml directly in production!**

Production deployment is handled by:
1. GitHub Actions builds image
2. Pushes to GitHub Container Registry
3. SSH to server and copies `docker-compose.prod.yml` template
4. Uses `envsubst` to substitute variables (creates `docker-compose.yml`)
5. Pulls and starts container

**Template variables:**
- `${DOCKER_IMAGE}` - Full image path from GHCR
- `${APP_DOMAIN}` - Domain name for Traefik routing
- `${WEBHOOK_URL}` - n8n webhook base URL

See:
- [GITHUB-SETUP.md](GITHUB-SETUP.md) - GitHub configuration
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production operations

---

## Comparison: Dev vs Prod

| Aspect | Development (`--profile dev`) | Production (Server) |
|--------|------------------------------|---------------------|
| **Image source** | Built locally | GitHub Container Registry |
| **Data volume** | `n8n_data` | `n8n_data` |
| **Backup mount** | `./backupdata` | `/srv/projects/n8n/backup` |
| **Network** | `n8n-network` | `traefik` (external) |
| **Port** | `5678:5678` | Internal only |
| **SSL/HTTPS** | No | Yes (via Traefik) |
| **Domain** | `localhost:5678` | `n8n.meimberg.io` |
| **Restart policy** | `unless-stopped` | `unless-stopped` |
| **Traefik labels** | No | Yes |

---

## Related Documentation

- [README.md](../README.md) - Project overview
- [SETUP-CHECKLIST.md](SETUP-CHECKLIST.md) - Quick setup guide
- [GITHUB-SETUP.md](GITHUB-SETUP.md) - GitHub configuration
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production operations
- [n8n Environment Variables](https://docs.n8n.io/hosting/configuration/environment-variables/) - Complete list

---

**Last Updated:** October 2025

