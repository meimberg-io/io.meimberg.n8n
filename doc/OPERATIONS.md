# Operations

## Container Management

```bash
# Status
ssh deploy@hc-02.meimberg.io "docker ps | grep n8n"
ssh deploy@hc-02.meimberg.io "docker stats n8n --no-stream"

# Logs
ssh deploy@hc-02.meimberg.io "docker logs n8n --tail 100"
ssh deploy@hc-02.meimberg.io "docker logs n8n -f"

# Restart
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose restart"

# Shell access
ssh deploy@hc-02.meimberg.io "docker exec -it n8n sh"
```

## Backup & Restore

### Manual Backup

```bash
# Export workflows
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/"

# Export credentials (encrypted)
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json"

# Download
scp -r deploy@hc-02.meimberg.io:/srv/projects/n8n/backup ./backup-$(date +%Y%m%d)
```

### Restore

```bash
# Upload backup
scp -r ./backup deploy@hc-02.meimberg.io:/srv/projects/n8n/

# Import workflows
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n import:workflow --separate --input=/home/node/backup/workflows"

# Import credentials
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n import:credentials --input=/home/node/backup/credentials/credentials.json"

# Restart
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose restart"
```

## Monitoring

```bash
# Health check
curl https://n8n.meimberg.io/healthz

# Resource usage
ssh deploy@hc-02.meimberg.io "docker stats n8n --no-stream"

# Disk usage
ssh deploy@hc-02.meimberg.io "du -sh /var/lib/docker/volumes/n8n_data"
ssh deploy@hc-02.meimberg.io "du -sh /srv/projects/n8n/backup"

# SSL cert expiry
echo | openssl s_client -servername n8n.meimberg.io -connect n8n.meimberg.io:443 2>/dev/null | openssl x8 -noout -dates
```

## Updating

### Update n8n Version

```bash
# Edit Dockerfile - change FROM version line
vim Dockerfile
# FROM docker.n8n.io/n8nio/n8n:1.120.0

# Commit and push
git add Dockerfile
git commit -m "chore: update n8n to v1.120.0"
git push origin main

# Verify after deployment
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n --version"
```

### Add System Dependencies

```bash
# Edit Dockerfile
RUN apk update && apk add --no-cache \
    existing-packages \
    your-new-package

# Commit and push
```

## Troubleshooting

### Container Won't Start

```bash
# Check status and logs
ssh deploy@hc-02.meimberg.io "docker ps -a | grep n8n"
ssh deploy@hc-02.meimberg.io "docker logs n8n"

# Verify volume
ssh deploy@hc-02.meimberg.io "docker volume ls | grep n8n_data"
```

### Container Keeps Restarting

```bash
# Check restart count and logs
ssh deploy@hc-02.meimberg.io "docker inspect n8n | grep RestartCount"
ssh deploy@hc-02.meimberg.io "docker logs n8n --tail 100"

# Common: missing env vars, volume permissions, port conflict
```

### HTTPS/SSL Issues

```bash
# Test DNS
dig n8n.meimberg.io +short

# Test from server
ssh deploy@hc-02.meimberg.io "curl http://localhost:5678"

# Check Traefik routing
ssh deploy@hc-02.meimberg.io "docker logs traefik | grep n8n"

# Verify Traefik labels
ssh deploy@hc-02.meimberg.io "docker inspect n8n | grep traefik"
```

### Webhooks Not Working

```bash
# Check WEBHOOK_URL env var
ssh deploy@hc-02.meimberg.io "docker exec n8n env | grep WEBHOOK_URL"
# Should be: https://n8n.meimberg.io

# Test webhook externally
curl -X POST https://n8n.meimberg.io/webhook-test/your-webhook-id
```

### High Memory Usage

```bash
# Check memory
ssh deploy@hc-02.meimberg.io "docker stats n8n --no-stream"

# Restart to clear
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose restart"
```

## Maintenance

### Clean Up Images

```bash
ssh deploy@hc-02.meimberg.io "docker images | grep n8n"
ssh deploy@hc-02.meimberg.io "docker image prune -f"
```

### Database Maintenance (SQLite)

```bash
ssh deploy@hc-02.meimberg.io "docker exec -it n8n sh"
cd /home/node/.n8n
sqlite3 database.sqlite
VACUUM;
PRAGMA optimize;
.exit
```

