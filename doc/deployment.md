# Deployment Configuration

This document describes the GitHub Actions deployment pipeline configuration.

## Overview

The deployment pipeline automatically:
1. Builds the custom n8n Docker image
2. Transfers it to the production server
3. Starts or restarts the n8n service

**Trigger:** Automatically runs on push to `main` branch

## GitHub Configuration

Configure these in your GitHub repository settings:

### Secrets

Go to: **Settings → Secrets and variables → Actions → Secrets**

| Secret Name | Description |
|-------------|-------------|
| `SSH_PRIVATE_KEY` | SSH private key for server authentication |

### Variables

Go to: **Settings → Secrets and variables → Actions → Variables**

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `HOST` | Production server hostname/IP | - | ✅ Yes |
| `USERNAME` | SSH username | `n8n` | No |
| `PORT` | SSH port | `22` | No |
| `WEBHOOK_URL` | n8n webhook base URL | - | ✅ Yes |
| `N8N_PORT` | n8n port | `5678` | No |

## SSH Key Setup

Generate an SSH key pair for deployment:

```bash
# Generate key
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/n8n_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/n8n_deploy.pub n8n@your-server.com

# Copy private key to GitHub secret
cat ~/.ssh/n8n_deploy
```

Add the private key content (including `-----BEGIN` and `-----END` lines) to the `SSH_PRIVATE_KEY` secret.

## Deployment Process

When you push to `main`, the pipeline:

1. **Build** - Creates Docker image with n8n + dependencies
2. **Transfer** - Copies image and scripts to `/opt/n8n/deploy`
3. **Deploy** - Loads image and starts/restarts service
4. **Verify** - Checks if container is running
5. **Cleanup** - Removes old images

## Manual Deployment

Trigger manually from GitHub:
1. Go to **Actions** tab
2. Select **Deploy n8n to Production**
3. Click **Run workflow**

## Troubleshooting

**Pipeline fails at "Copy files to server":**
- Check `HOST`, `USERNAME`, `SSH_PRIVATE_KEY` are correct
- Verify SSH key matches server's authorized_keys

**Pipeline fails at "Deploy on server":**
- Check server has Docker installed
- Verify n8n user has sudo permissions for systemctl
- Check disk space: `df -h`

**Container doesn't start:**
- Check logs in GitHub Actions
- SSH to server and check: `sudo systemctl status n8n`
- View container logs: `docker logs n8n`

## See Also

- [Production Setup](production-setup.md) - Initial server setup
- [Operations Guide](operations.md) - Service management
- [Scripts README](../scripts/README.md) - Deployment scripts
