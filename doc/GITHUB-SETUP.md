# GitHub Setup

Initial configuration required for automatic deployment.

## GitHub Variables

**Settings → Secrets and variables → Actions → Variables**

| Name | Value | Description |
|------|-------|-------------|
| `APP_DOMAIN` | `n8n.meimberg.io` | n8n application domain (**required**) |
| `SERVER_HOST` | `hc-02.meimberg.io` | Server hostname (**required**) |
| `SERVER_USER` | `deploy` | SSH user (**required**) |
| `WEBHOOK_URL` | `https://n8n.meimberg.io` | n8n webhook base URL (**required**) |

## GitHub Secrets

**Settings → Secrets and variables → Actions → Secrets**

| Name | Value | Description |
|------|-------|-------------|
| `SSH_PRIVATE_KEY` | `<private key contents>` | Deploy user private key (**required**) |

**Get SSH private key:**
```bash
# Linux/Mac
cat ~/.ssh/id_rsa
# Or your deploy key: cat ~/.ssh/deploy_key

# Windows PowerShell
Get-Content C:\Users\YourName\.ssh\id_rsa
```

Copy entire output including `-----BEGIN` and `-----END` lines.

---

## DNS Configuration

**Add CNAME record:**
```
n8n.meimberg.io  →  CNAME  →  hc-02.meimberg.io
```

**Verify DNS propagation:**
```bash
dig n8n.meimberg.io +short
# Should return: hc-02.meimberg.io
```

---

## Server Infrastructure

**Prerequisites (one-time setup):**

The server must have infrastructure in place before first deployment:

✅ **Already done for meimberg.io servers:**
- Docker + Docker Compose
- Traefik reverse proxy (automatic SSL)
- `deploy` user (for deployments)
- Firewall rules (SSH, HTTP, HTTPS)
- Traefik network (`docker network create traefik`)

**If setting up a new server**, run Ansible first:

```bash
cd ../io.meimberg.ansible

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Run infrastructure setup
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --vault-password-file vault_pass
```

---

## First Deployment

### Checklist

Before first deployment:

- [ ] GitHub Variables added: `APP_DOMAIN`, `SERVER_HOST`, `SERVER_USER`, `WEBHOOK_URL`
- [ ] GitHub Secrets added: `SSH_PRIVATE_KEY`
- [ ] DNS CNAME record configured
- [ ] Server infrastructure ready (Ansible deployed)
- [ ] Can SSH to server: `ssh deploy@hc-02.meimberg.io`
- [ ] Traefik network exists: `docker network ls | grep traefik`

### Deploy

```bash
git add .
git commit -m "Setup deployment"
git push origin main
```

**Monitor:** https://github.com/meimberg-io/io.meimberg.n8n/actions

**Deployment takes ~3-4 minutes:**
1. ✅ Build custom n8n Docker image
2. ✅ Push to GitHub Container Registry
3. ✅ SSH to server
4. ✅ Create docker-compose.yml with Traefik labels
5. ✅ Pull and start container
6. ✅ Traefik automatically provisions SSL certificate

---

## Verify Deployment

### Check GitHub Actions

1. Go to **Actions** tab in GitHub
2. Click on latest workflow run
3. Verify all steps completed successfully
4. Check deployment logs

### Test Application

```bash
# Test DNS
dig n8n.meimberg.io +short

# Test HTTP redirect to HTTPS
curl -I http://n8n.meimberg.io

# Test HTTPS and SSL
curl -I https://n8n.meimberg.io

# View container on server
ssh deploy@hc-02.meimberg.io "docker ps | grep n8n"

# View logs
ssh deploy@hc-02.meimberg.io "docker logs n8n -f"
```

### Access n8n

Open browser: **https://n8n.meimberg.io**

- [ ] n8n UI loads
- [ ] SSL certificate is valid (green padlock)
- [ ] Can create account/login
- [ ] Can create a test workflow

---

## Troubleshooting

### GitHub Actions Fails

**Build fails:**
- Check Dockerfile syntax
- Verify base image exists: `docker.n8n.io/n8nio/n8n:1.115.2`

**Push fails:**
- Check GitHub Container Registry permissions
- Verify `GITHUB_TOKEN` has write access

**Deploy fails:**
```bash
# Test SSH connection
ssh -i ~/.ssh/deploy_key deploy@hc-02.meimberg.io

# Check if deploy user can run docker
ssh deploy@hc-02.meimberg.io "docker ps"

# Check Traefik network
ssh deploy@hc-02.meimberg.io "docker network ls | grep traefik"
```

### Container Not Starting

```bash
# Check container status
ssh deploy@hc-02.meimberg.io "docker ps -a | grep n8n"

# View logs
ssh deploy@hc-02.meimberg.io "docker logs n8n"

# Check volume
ssh deploy@hc-02.meimberg.io "docker volume inspect n8n_data"

# Check backup directory permissions
ssh deploy@hc-02.meimberg.io "ls -la /srv/projects/n8n/backup"
# Should be owned by UID 1000
```

### SSL/HTTPS Issues

**Certificate not provisioning:**
- DNS must be fully propagated (wait 5-10 minutes)
- Check Traefik logs: `docker logs traefik`
- Verify domain in Traefik labels matches DNS

**403/404 errors:**
- Check Traefik routing rules in docker-compose.yml
- Verify container is on traefik network: `docker inspect n8n`

### Webhooks Not Working

```bash
# Check WEBHOOK_URL is set
ssh deploy@hc-02.meimberg.io "docker exec n8n env | grep WEBHOOK_URL"

# Should show: WEBHOOK_URL=https://n8n.meimberg.io

# Test webhook endpoint
curl -X POST https://n8n.meimberg.io/webhook-test/your-webhook-id
```

---

## Manual Deployment

If GitHub Actions is unavailable, deploy manually:

```bash
# 1. SSH to server
ssh deploy@hc-02.meimberg.io

# 2. Navigate to project directory
cd /srv/projects/n8n

# 3. Login to GitHub Container Registry
echo $GITHUB_PAT | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 4. Pull latest image
docker compose pull

# 5. Restart container
docker compose up -d

# 6. Verify
docker ps | grep n8n
docker logs n8n -f
```

---

## Updating n8n Version

To update the n8n base image version:

```bash
# 1. Edit Dockerfile
vim Dockerfile

# 2. Change version
FROM docker.n8n.io/n8nio/n8n:1.120.0  # Update version number

# 3. Commit and push
git add Dockerfile
git commit -m "chore: update n8n to v1.120.0"
git push origin main
```

GitHub Actions will automatically build and deploy the new version.

---

## Environment Variables

### Available in Production

Set in `docker-compose.yml` (created by GitHub Actions):

| Variable | Value | Purpose |
|----------|-------|---------|
| `WEBHOOK_URL` | From GitHub variable | Base URL for webhooks |
| `GENERIC_TIMEZONE` | `Europe/Berlin` | n8n timezone |
| `TZ` | `Europe/Berlin` | Container timezone |
| `N8N_LOG_LEVEL` | `info` | Logging verbosity |

### Adding New Variables

To add environment variables to production:

1. Add to GitHub Actions workflow (`.github/workflows/deploy.yml`)
2. Pass via `envs:` in SSH action
3. Add to docker-compose.yml template in workflow

---

## Backup Configuration

Backups are stored in `/srv/projects/n8n/backup` on the server, mounted to the container at `/home/node/backup`.

**Setup:**
```bash
# Directory already created by deployment workflow
# Owned by UID 1000 (n8n container user)

# Verify
ssh deploy@hc-02.meimberg.io "ls -la /srv/projects/n8n/backup"
```

**See:** [DEPLOYMENT.md](DEPLOYMENT.md) for backup operations.

---

## Related Documentation

- [README.md](../README.md) - Project overview
- [SETUP-CHECKLIST.md](SETUP-CHECKLIST.md) - Quick setup guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Operations and troubleshooting
- [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) - Docker Compose usage
- [Ansible Structure](../../io.meimberg.meta/doc/ANSIBLE-STRUCTURE.md) - Infrastructure overview

---

**Last Updated:** October 2025

