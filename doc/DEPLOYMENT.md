# Deployment and Operations Guide

Complete guide for deploying, operating, monitoring, and maintaining n8n in production.

## Table of Contents

- [Deployment Process](#deployment-process)
- [Container Management](#container-management)
- [Monitoring](#monitoring)
- [Backups and Restore](#backups-and-restore)
- [Updating n8n](#updating-n8n)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## Deployment Process

### Automatic Deployment (Recommended)

Every push to `main` branch triggers automatic deployment via GitHub Actions.

**Process:**
1. Developer pushes code to `main`
2. GitHub Actions builds Docker image
3. Image pushed to GitHub Container Registry
4. SSH to server and copy `docker-compose.prod.yml` template
5. Use `envsubst` to substitute environment variables (image, domain, webhook URL)
6. Pull image and start/restart container
7. Verify container is running

**Monitor deployment:**
```bash
# Watch GitHub Actions
# https://github.com/meimberg-io/io.meimberg.n8n/actions

# View container logs during deployment
ssh deploy@hc-02.meimberg.io "docker logs n8n -f"
```

### Manual Deployment

If needed, deploy manually:

```bash
# SSH to server
ssh deploy@hc-02.meimberg.io

# Navigate to project
cd /srv/projects/n8n

# Pull latest image
docker compose pull

# Restart container
docker compose up -d

# Verify
docker ps | grep n8n
docker logs n8n -f
```

### Rollback Deployment

To rollback to a previous version:

```bash
# SSH to server
ssh deploy@hc-02.meimberg.io
cd /srv/projects/n8n

# Stop current container
docker compose down

# Use specific image tag (find in GitHub Container Registry)
# Edit docker-compose.yml and change:
# image: ghcr.io/meimberg-io/io.meimberg.n8n:main-abc1234

# Start with previous version
docker compose up -d
```

---

## Container Management

### Check Status

```bash
# Container running
ssh deploy@hc-02.meimberg.io "docker ps | grep n8n"

# Container details
ssh deploy@hc-02.meimberg.io "docker inspect n8n"

# Container stats
ssh deploy@hc-02.meimberg.io "docker stats n8n --no-stream"
```

### View Logs

```bash
# View recent logs
ssh deploy@hc-02.meimberg.io "docker logs n8n --tail 100"

# Follow logs in real-time
ssh deploy@hc-02.meimberg.io "docker logs n8n -f"

# Logs with timestamps
ssh deploy@hc-02.meimberg.io "docker logs n8n -f --timestamps"
```

### Restart Container

```bash
# Graceful restart
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose restart"

# Stop and start
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose down && docker compose up -d"

# Force recreate
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose up -d --force-recreate"
```

### Access Container Shell

```bash
# Enter container
ssh deploy@hc-02.meimberg.io "docker exec -it n8n sh"

# Run command in container
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n --version"
```

---

## Monitoring

### Health Checks

```bash
# Test HTTP endpoint
curl https://n8n.meimberg.io/healthz

# Check from server
ssh deploy@hc-02.meimberg.io "curl http://localhost:5678/healthz"
```

### Resource Usage

```bash
# CPU and memory
ssh deploy@hc-02.meimberg.io "docker stats n8n --no-stream"

# Disk usage
ssh deploy@hc-02.meimberg.io "docker system df"

# Volume size
ssh deploy@hc-02.meimberg.io "docker volume inspect n8n_data"
ssh deploy@hc-02.meimberg.io "du -sh /var/lib/docker/volumes/n8n_data"

# Backup directory size
ssh deploy@hc-02.meimberg.io "du -sh /srv/projects/n8n/backup"
```

### Check SSL Certificate

```bash
# Certificate details
echo | openssl s_client -servername n8n.meimberg.io -connect n8n.meimberg.io:443 2>/dev/null | openssl x509 -noout -dates

# Certificate expiry
curl -vI https://n8n.meimberg.io 2>&1 | grep "expire"
```

### Traefik Integration

```bash
# Check if n8n is registered with Traefik
ssh deploy@hc-02.meimberg.io "docker logs traefik | grep n8n"

# Verify container is on traefik network
ssh deploy@hc-02.meimberg.io "docker inspect n8n | grep traefik"
```

---

## Backups and Restore

### Quick Backup

**Option 1: Using backup script (local or prod):**

```bash
# On production server
ssh deploy@hc-02.meimberg.io
cd /srv/projects/n8n
git clone https://github.com/meimberg-io/io.meimberg.n8n.git scripts-temp
./scripts-temp/scripts/backup.sh
rm -rf scripts-temp
```

**Option 2: Manual export:**

```bash
# Export workflows
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/"

# Export credentials (encrypted)
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json"

# Download backup
scp -r deploy@hc-02.meimberg.io:/srv/projects/n8n/backup ./backup-$(date +%Y%m%d)
```

### Backup Contains

- **Workflows**: All workflow definitions (JSON files)
- **Credentials**: Encrypted credentials (single JSON file)
- **Not included**: Execution history, logs, binary data

### Restore Backup

```bash
# Copy backup to server
scp -r ./backup deploy@hc-02.meimberg.io:/srv/projects/n8n/

# Import workflows
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n import:workflow --separate --input=/home/node/backup/workflows"

# Import credentials
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n import:credentials --input=/home/node/backup/credentials/credentials.json"

# Restart n8n
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose restart"
```

### Automated Backups

Set up automated backups with cron:

```bash
# SSH to server
ssh deploy@hc-02.meimberg.io

# Create backup script
cat > /home/deploy/backup-n8n.sh << 'EOF'
#!/bin/bash
set -e
docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/
docker exec n8n n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json
cd /srv/projects/n8n
tar -czf /home/deploy/backups/n8n-backup-$(date +%Y%m%d-%H%M%S).tar.gz backup/
find /home/deploy/backups -name "n8n-backup-*.tar.gz" -mtime +30 -delete
EOF

chmod +x /home/deploy/backup-n8n.sh

# Create backups directory
mkdir -p /home/deploy/backups

# Add to crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /home/deploy/backup-n8n.sh >> /home/deploy/backups/backup.log 2>&1
```

### Sync from Production to Local

Use the sync script to download production data for local testing:

```bash
# On local machine
cd /path/to/io.meimberg.n8n

# Configure .env (if not done)
echo "PROD_SSH_HOST=hc-02.meimberg.io" >> .env
echo "PROD_SSH_USER=deploy" >> .env
echo "PROD_APP_DIR=/srv/projects/n8n" >> .env

# Run sync script
./scripts/sync-from-prod.sh  # Linux/macOS
# or
.\scripts\sync-from-prod.ps1  # Windows
```

---

## Updating n8n

### Update n8n Version

```bash
# 1. Edit Dockerfile locally
vim Dockerfile

# Change version line
FROM docker.n8n.io/n8nio/n8n:1.120.0  # Update to desired version

# 2. Commit and push
git add Dockerfile
git commit -m "chore: update n8n to v1.120.0"
git push origin main

# 3. GitHub Actions automatically builds and deploys
# Monitor: https://github.com/meimberg-io/io.meimberg.n8n/actions

# 4. Verify new version
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n --version"
```

### Add System Dependencies

To add Alpine packages (e.g., for custom nodes):

```bash
# Edit Dockerfile
vim Dockerfile

# Update RUN command
RUN apk update && apk add --no-cache \
    perl \
    poppler-utils \
    imagemagick \
    ghostscript \
    graphicsmagick \
    your-new-package

# Commit and push
git add Dockerfile
git commit -m "feat: add your-new-package dependency"
git push origin main
```

### Install Community Nodes

```bash
# Edit Dockerfile
vim Dockerfile

# Add after the RUN apk... command
USER node
WORKDIR /home/node/.n8n/nodes
RUN npm install n8n-nodes-package-name

# Commit and push
git add Dockerfile
git commit -m "feat: add n8n-nodes-package-name"
git push origin main
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check container status
ssh deploy@hc-02.meimberg.io "docker ps -a | grep n8n"

# View error logs
ssh deploy@hc-02.meimberg.io "docker logs n8n"

# Check volume exists
ssh deploy@hc-02.meimberg.io "docker volume ls | grep n8n_data"

# Check docker-compose.yml
ssh deploy@hc-02.meimberg.io "cat /srv/projects/n8n/docker-compose.yml"
```

### Container Keeps Restarting

```bash
# Check restart count
ssh deploy@hc-02.meimberg.io "docker inspect n8n | grep RestartCount"

# View recent logs
ssh deploy@hc-02.meimberg.io "docker logs n8n --tail 100"

# Common causes:
# - Missing environment variables
# - Volume permission issues
# - Port already in use
# - Database corruption (rare)
```

### Cannot Access n8n (HTTPS Issues)

```bash
# Test DNS
dig n8n.meimberg.io +short

# Test from server
ssh deploy@hc-02.meimberg.io "curl http://localhost:5678"

# Check Traefik routing
ssh deploy@hc-02.meimberg.io "docker logs traefik | grep n8n"

# Verify Traefik labels
ssh deploy@hc-02.meimberg.io "docker inspect n8n | grep traefik"

# Check if on traefik network
ssh deploy@hc-02.meimberg.io "docker network inspect traefik"
```

### Webhooks Not Working

```bash
# Check WEBHOOK_URL
ssh deploy@hc-02.meimberg.io "docker exec n8n env | grep WEBHOOK_URL"
# Should show: WEBHOOK_URL=https://n8n.meimberg.io

# Test webhook from outside
curl -X POST https://n8n.meimberg.io/webhook-test/your-webhook-id

# Check n8n logs for webhook calls
ssh deploy@hc-02.meimberg.io "docker logs n8n | grep webhook"
```

### Backup/Restore Issues

```bash
# Check backup directory permissions
ssh deploy@hc-02.meimberg.io "ls -la /srv/projects/n8n/backup"
# Should be owned by UID 1000

# Fix permissions if needed
ssh deploy@hc-02.meimberg.io "sudo chown -R 1000:1000 /srv/projects/n8n/backup"

# Test export manually
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n export:workflow --backup --output=/home/node/backup/test/"
```

### High Memory Usage

```bash
# Check memory
ssh deploy@hc-02.meimberg.io "docker stats n8n --no-stream"

# Check number of active workflows
# (Login to n8n UI and check)

# Restart to clear memory
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose restart"

# Set memory limits in docker-compose.yml (if needed)
```

### Data Lost After Restart

```bash
# Verify volume is persistent
ssh deploy@hc-02.meimberg.io "docker volume inspect n8n_data"

# Check if volume is mounted
ssh deploy@hc-02.meimberg.io "docker inspect n8n | grep -A 10 Mounts"

# Volume should be at: /var/lib/docker/volumes/n8n_data/_data
```

---

## Maintenance

### Clean Up Old Images

```bash
# List images
ssh deploy@hc-02.meimberg.io "docker images | grep n8n"

# Remove unused images
ssh deploy@hc-02.meimberg.io "docker image prune -f"

# Remove specific old image
ssh deploy@hc-02.meimberg.io "docker rmi <image-id>"
```

### Clean Up Logs

```bash
# Check log size
ssh deploy@hc-02.meimberg.io "docker inspect n8n | grep LogPath"
ssh deploy@hc-02.meimberg.io "du -h /var/lib/docker/containers/*/...json.log"

# Rotate logs (stop container first)
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose down"
ssh deploy@hc-02.meimberg.io "truncate -s 0 /var/lib/docker/containers/*/...json.log"
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose up -d"
```

### Update Server Infrastructure

```bash
# Update system packages
ssh deploy@hc-02.meimberg.io "sudo apt update && sudo apt upgrade -y"

# Update Docker
ssh deploy@hc-02.meimberg.io "sudo apt install docker-ce docker-ce-cli containerd.io"

# Reboot if kernel updated
ssh deploy@hc-02.meimberg.io "sudo reboot"
```

### Database Maintenance (SQLite)

n8n uses SQLite by default. For maintenance:

```bash
# Access database
ssh deploy@hc-02.meimberg.io "docker exec -it n8n sh"
cd /home/node/.n8n
sqlite3 database.sqlite

# Optimize database
VACUUM;
PRAGMA optimize;
.exit
```

---

## Performance Optimization

### Increase Container Resources

Edit docker-compose.yml on server:

```bash
ssh deploy@hc-02.meimberg.io
cd /srv/projects/n8n
nano docker-compose.yml

# Add under n8n service:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          memory: 1G

# Restart
docker compose up -d --force-recreate
```

### Enable Execution Data Pruning

```bash
# Add to docker-compose.yml environment:
- EXECUTIONS_DATA_PRUNE=true
- EXECUTIONS_DATA_MAX_AGE=168  # Keep 7 days

# Restart
cd /srv/projects/n8n
docker compose up -d
```

---

## Security Best Practices

1. **Keep n8n Updated** - Regularly update to latest version
2. **Secure Credentials** - n8n encrypts credentials at rest
3. **Use HTTPS** - Traefik provides automatic SSL
4. **Backup Regularly** - Automate daily backups
5. **Monitor Logs** - Watch for suspicious activity
6. **Restrict Access** - Consider IP whitelisting in Traefik
7. **Update System** - Keep server and Docker updated

---

## Related Documentation

- [README.md](../README.md) - Project overview
- [SETUP-CHECKLIST.md](SETUP-CHECKLIST.md) - Quick setup guide
- [GITHUB-SETUP.md](GITHUB-SETUP.md) - GitHub configuration
- [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) - Docker Compose usage
- [n8n Documentation](https://docs.n8n.io/) - Official n8n docs
- [Ansible Structure](../../io.meimberg.meta/doc/ANSIBLE-STRUCTURE.md) - Infrastructure overview

---

**Last Updated:** October 2025

