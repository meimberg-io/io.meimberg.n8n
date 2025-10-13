# Deployment Setup

This document describes the automated deployment process for n8n using GitHub Actions.

## Overview

The deployment pipeline automatically:
1. Builds the custom n8n Docker image
2. Transfers it to the production server
3. Loads the image and restarts the service

## GitHub Configuration

Before the pipeline can run, you need to configure secrets and variables in your GitHub repository:

### Secrets (Sensitive Data)
Go to: **Settings → Secrets and variables → Actions → Secrets → New repository secret**

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SSH_PRIVATE_KEY` | SSH private key for authentication | Contents of your private key file |

### Variables (Non-Sensitive Configuration)
Go to: **Settings → Secrets and variables → Actions → Variables → New repository variable**

| Variable Name | Description | Example | Required |
|---------------|-------------|---------|----------|
| `HOST` | Production server hostname or IP | `n8n.meimberg.io` | Yes |
| `USERNAME` | SSH user on the server | `n8n` | No (defaults to `n8n`) |
| `PORT` | SSH port | `22` | No (defaults to `22`) |
| `WEBHOOK_URL` | n8n webhook base URL | `https://n8n.meimberg.io` | Yes |
| `N8N_PORT` | Port to expose n8n on | `5678` | No (defaults to `5678`) |

### Getting the SSH Private Key

If you don't have an SSH key pair yet:

```bash
# Generate a new SSH key pair (on your local machine)
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/n8n_deploy

# Copy the public key to the server
ssh-copy-id -i ~/.ssh/n8n_deploy.pub n8n@your-server.com

# Display the private key to copy into GitHub secrets
cat ~/.ssh/n8n_deploy
```

Copy the entire private key (including `-----BEGIN` and `-----END` lines) into the `DEPLOY_KEY` secret.

## Deployment Scripts

Scripts are available in the `scripts/` directory for both Linux/Unix and Windows:

### Linux/Unix (Bash)

#### start.sh
Starts the n8n container with the correct configuration.
```bash
./scripts/start.sh
```

#### stop.sh
Stops and removes the running n8n container.
```bash
./scripts/stop.sh
```

#### restart.sh
Stops the old container and starts a new one.
```bash
./scripts/restart.sh
```

### Windows (PowerShell)

> **Note:** If you get an execution policy error, run PowerShell as Administrator and execute:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

#### start.ps1
Starts the n8n container with the correct configuration.
```powershell
.\scripts\start.ps1
```

#### stop.ps1
Stops and removes the running n8n container.
```powershell
.\scripts\stop.ps1
```

#### restart.ps1
Stops the old container and starts a new one.
```powershell
.\scripts\restart.ps1
```

### Environment Variables

Both script sets support the following environment variables:
- `WEBHOOK_URL` - The webhook base URL (default: `https://n8n.meimberg.io`)
- `N8N_PORT` - The port to expose n8n on (default: `5678`)

**Linux/Unix Example:**
```bash
export WEBHOOK_URL="https://custom.example.com"
export N8N_PORT="8080"
./scripts/start.sh
```

**Windows Example:**
```powershell
$env:WEBHOOK_URL = "https://custom.example.com"
$env:N8N_PORT = "8080"
.\scripts\start.ps1
```

> **Note:** On Windows, the backup directory is automatically created at `backup` in the project root. On Linux/Unix, it uses `/opt/n8n/backup`.

## Deployment Triggers

The pipeline runs automatically when:
- Code is pushed to the `main` branch
- Manually triggered via the GitHub Actions UI

## Manual Deployment

To manually trigger a deployment:
1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Deploy n8n to Production** workflow
4. Click **Run workflow** button
5. Confirm by clicking **Run workflow**

## First-Time Server Setup

Before the first deployment, ensure the server is prepared:

1. Docker is installed (see [server.md](server.md))
2. User `n8n` exists with home directory `/opt/n8n`
3. Docker volume `n8n_data` is created
4. Directory `/opt/n8n/deploy` exists
5. Directory `/opt/n8n/backup` exists for backups

```bash
# On the server as root
mkdir -p /opt/n8n/deploy
mkdir -p /opt/n8n/backup
chown -R n8n:docker /opt/n8n
```

## Monitoring Deployment

After deployment, check the service status:

```bash
# SSH into the server
ssh n8n@your-server.com

# Check if container is running
docker ps | grep n8n

# Check logs
docker logs n8n -f

# Check service status (if using systemd)
sudo systemctl status n8n
```

## Troubleshooting

### Pipeline fails at "Copy files to server"
- Verify `HOST` variable and `SSH_PRIVATE_KEY` secret are correct
- Check that `USERNAME` variable is set (or defaults to `n8n`)
- Test SSH connection manually: `ssh -i ~/.ssh/key n8n@server`

### Pipeline fails at "Deploy on server"
- Check server has enough disk space: `df -h`
- Verify Docker is running: `systemctl status docker`
- Check logs in GitHub Actions for detailed error messages

### Container won't start
- Check Docker logs: `docker logs n8n`
- Verify volume exists: `docker volume ls | grep n8n_data`
- Ensure port 5678 is not already in use: `netstat -tlnp | grep 5678`

## Rolling Back

If a deployment fails, you can roll back to a previous image:

```bash
# SSH into the server
ssh n8n@your-server.com

# List available images
docker images | grep n8n-custom

# If needed, pull a previous image or rebuild from an older commit
# Then restart the service
cd /opt/n8n/deploy
./scripts/restart.sh
```

