# Setup

Initial GitHub Actions and DNS configuration for automated deployment.

## GitHub Configuration

### Variables

**Settings → Secrets and variables → Actions → Variables**

| Name | Value |
|------|-------|
| `APP_DOMAIN` | `n8n.meimberg.io` |
| `SERVER_HOST` | `hc-02.meimberg.io` |
| `SERVER_USER` | `deploy` |
| `WEBHOOK_URL` | `https://n8n.meimberg.io` |

### Secrets

**Settings → Secrets and variables → Actions → Secrets**

| Name | Value |
|------|-------|
| `SSH_PRIVATE_KEY` | Deploy user private key |

**Get key:**
```bash
cat ~/.ssh/id_rsa  # or ~/.ssh/deploy_key
```

Copy entire output including `-----BEGIN` and `-----END` lines.

## DNS Configuration

Add CNAME record:
```
n8n.meimberg.io  →  CNAME  →  hc-02.meimberg.io
```

Verify:
```bash
dig n8n.meimberg.io +short
```

## Server Prerequisites

Infrastructure must be deployed via Ansible first:
- Docker + Docker Compose
- Traefik reverse proxy (auto SSL)
- `deploy` user
- Traefik network: `docker network create traefik`

## First Deployment

Checklist:
- [ ] GitHub variables configured
- [ ] GitHub secrets configured
- [ ] DNS CNAME record added
- [ ] Server infrastructure deployed (Ansible)
- [ ] Can SSH: `ssh deploy@hc-02.meimberg.io`
- [ ] Traefik network exists

Deploy:
```bash
git push origin main
```

Monitor: https://github.com/meimberg-io/io.meimberg.n8n/actions

Verify:
- Container running: `ssh deploy@hc-02.meimberg.io "docker ps | grep n8n"`
- HTTPS works: https://n8n.meimberg.io
- SSL cert valid: `curl -vI https://n8n.meimberg.io`

