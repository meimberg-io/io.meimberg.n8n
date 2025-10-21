# Setup Checklist

Quick reference checklist for io.meimberg.n8n setup and deployment.

## Local Development

### 1. Clone Repository

```bash
cd ~/workspace
git clone git@github.com:meimberg-io/io.meimberg.n8n.git
cd io.meimberg.n8n
```

### 2. Environment Setup

```bash
cp env.example .env
```

Edit `.env` with your values:
- [ ] `WEBHOOK_URL` - Set to `http://localhost:5678` for local dev
- [ ] `N8N_PORT` - Port to expose (default: 5678)
- [ ] `N8N_BASIC_AUTH_ACTIVE` - Enable basic auth (optional)
- [ ] `N8N_ENCRYPTION_KEY` - Generate with: `openssl rand -hex 32`

### 3. Docker Development

```bash
# Build and start n8n
docker compose --profile dev up

# Access at http://localhost:5678

# Stop
docker compose --profile dev down
```

### 4. Production Testing (Optional)

```bash
# Test production build locally
docker compose --profile prod up --build

# Access at http://localhost:5678
```

---

## Production Deployment

### 5. GitHub Variables

**Settings → Secrets and variables → Actions → Variables**

- [ ] `APP_DOMAIN` = `n8n.meimberg.io`
- [ ] `SERVER_HOST` = `hc-02.meimberg.io`
- [ ] `SERVER_USER` = `deploy`
- [ ] `WEBHOOK_URL` = `https://n8n.meimberg.io`

### 6. GitHub Secrets

**Settings → Secrets and variables → Actions → Secrets**

- [ ] `SSH_PRIVATE_KEY` - Deploy user SSH key

### 7. DNS Configuration

- [ ] CNAME: `n8n.meimberg.io` → `hc-02.meimberg.io`
- [ ] Test: `dig n8n.meimberg.io +short`

### 8. Server Infrastructure

- [ ] Ansible infrastructure deployed (Docker, Traefik, deploy user)
- [ ] Can SSH to server: `ssh deploy@hc-02.meimberg.io`
- [ ] Traefik network exists: `ssh deploy@hc-02.meimberg.io "docker network ls | grep traefik"`

### 9. Deploy

```bash
git add .
git commit -m "Setup deployment"
git push origin main
```

- [ ] Watch GitHub Actions: https://github.com/meimberg-io/io.meimberg.n8n/actions
- [ ] Verify deployment successful
- [ ] Test app at https://n8n.meimberg.io

---

## Verification

### Check Deployment

```bash
# Container running
ssh deploy@hc-02.meimberg.io "docker ps | grep n8n"

# View logs
ssh deploy@hc-02.meimberg.io "docker logs n8n -f"

# Test health
curl -I https://n8n.meimberg.io

# Check SSL
curl -vI https://n8n.meimberg.io 2>&1 | grep -i "subject:"
```

### Test n8n Functionality

- [ ] n8n UI loads at https://n8n.meimberg.io
- [ ] Can create workflows
- [ ] Webhooks work (test with simple HTTP request node)
- [ ] Credentials can be saved

### Test Backups

```bash
# SSH to server
ssh deploy@hc-02.meimberg.io

# Navigate to n8n project
cd /srv/projects/n8n

# Test backup export (requires workflows/credentials)
docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/
docker exec n8n n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json

# Check backup files created
ls -la backup/
```

---

## Common Issues

### Local Development

❌ **Port 5678 in use** → Change `N8N_PORT` in `.env`  
❌ **Container won't start** → Check Docker is running  
❌ **Permission errors** → Check `backupdata/` directory permissions  
❌ **Data not persisting** → Verify Docker volume `n8n_data` exists: `docker volume ls`

### Deployment

❌ **GitHub Actions fails** → Check secrets/variables configured  
❌ **Container not starting** → Check logs with `docker logs n8n`  
❌ **SSL not working** → DNS not propagated or Traefik issue  
❌ **Webhooks not working** → Check `WEBHOOK_URL` is set correctly  
❌ **Backup directory errors** → Ensure `/srv/projects/n8n/backup` owned by UID 1000

---

## Quick Reference

### Local Commands

```bash
# Development
docker compose --profile dev up

# Production test
docker compose --profile prod up --build

# Rebuild
docker compose --profile dev build --no-cache

# Stop
docker compose --profile dev down

# View logs
docker compose --profile dev logs -f
```

### Production Commands

```bash
# View logs
ssh deploy@hc-02.meimberg.io "docker logs n8n -f"

# Restart
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose restart"

# Redeploy
ssh deploy@hc-02.meimberg.io "cd /srv/projects/n8n && docker compose pull && docker compose up -d"

# SSH into container
ssh deploy@hc-02.meimberg.io "docker exec -it n8n sh"

# Export workflows
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/"

# Export credentials
ssh deploy@hc-02.meimberg.io "docker exec n8n n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json"
```

---

## Estimated Time

- **Local setup**: 5-10 minutes
- **GitHub configuration**: 5 minutes
- **First deployment**: 3-4 minutes
- **Total**: ~15-20 minutes

---

## Related Documentation

- [README.md](../README.md) - Project overview
- [GITHUB-SETUP.md](GITHUB-SETUP.md) - Detailed GitHub setup
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment operations
- [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) - Docker usage
- [Ansible Structure](../../io.meimberg.meta/doc/ANSIBLE-STRUCTURE.md) - Infrastructure overview

