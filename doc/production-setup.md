# Production Setup Guide

This guide walks you through the initial setup of n8n for production with automatic restart on server reboot.

> **After setup:** See [Operations Guide](operations.md) for service management, monitoring, and troubleshooting.

## Architecture Overview

The production setup uses:
- **Docker** to run the n8n container
- **Systemd** to manage the service lifecycle (auto-start, auto-restart)
- **Deployment scripts** for starting/stopping the container
- **GitHub Actions** for automated deployments

## Initial Server Setup

### 1. Install Docker

```bash
# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 2. Create n8n User

```bash
# Create user with home directory at /opt/n8n
sudo useradd -d /opt/n8n -s /bin/bash n8n

# Add to docker group
sudo usermod -aG docker n8n

# Create directory structure
sudo mkdir -p /opt/n8n/deploy
sudo mkdir -p /opt/n8n/backup

# Set ownership
sudo chown -R n8n:docker /opt/n8n
```

### 3. Setup SSH Access for Deployment

```bash
# Switch to n8n user
sudo su - n8n

# Create SSH directory
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys

# Add your GitHub deployment SSH public key
# (Copy from GitHub secrets configuration)
vim ~/.ssh/authorized_keys

# Exit back to root/sudo user
exit
```

### 4. Configure Sudo Permissions for Deployment

Allow the n8n user to manage the n8n service:

```bash
# Create sudoers file for n8n
sudo vim /etc/sudoers.d/n8n
```

Add the following content:

```
# Allow n8n user to manage n8n.service without password
n8n ALL=(ALL) NOPASSWD: /usr/bin/systemctl start n8n, /usr/bin/systemctl stop n8n, /usr/bin/systemctl restart n8n, /usr/bin/systemctl status n8n
```

Save and set correct permissions:

```bash
sudo chmod 0440 /etc/sudoers.d/n8n
```

> **Note:** Docker will automatically create the `n8n_data` volume when the container first starts, so no manual volume creation is needed.

## Systemd Service Setup

### 5. Create the Service File

Create the systemd service file:

```bash
sudo vim /etc/systemd/system/n8n.service
```

Paste the following content and adjust the `WEBHOOK_URL` and `N8N_PORT` for your environment:

```ini
[Unit]
Description=n8n Workflow Automation
Documentation=https://docs.n8n.io
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=forking
User=n8n
Group=docker
WorkingDirectory=/opt/n8n

# Environment variables for the container
Environment="WEBHOOK_URL=https://n8n.meimberg.io"
Environment="N8N_PORT=5678"

# Use the deployment scripts
ExecStart=/opt/n8n/deploy/scripts/start.sh
ExecStop=/opt/n8n/deploy/scripts/stop.sh
ExecReload=/opt/n8n/deploy/scripts/restart.sh

# Restart policy
Restart=on-failure
RestartSec=10s

# Security settings
NoNewPrivileges=true
PrivateTmp=true

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=n8n

[Install]
WantedBy=multi-user.target
```

### 6. Enable the Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable n8n
```

> **Note:** Don't start the service yet - it will be started automatically by the deployment pipeline.

## First Deployment

Trigger the first deployment via GitHub Actions:

1. Push your code to the `main` branch
2. GitHub Actions will automatically:
   - Build the Docker image
   - Transfer it to the server
   - Deploy the scripts
   - Start the n8n service

The pipeline handles everything - no manual start needed!

## Verify Installation

After starting the service:

```bash
# Check service status
sudo systemctl status n8n

# Check if container is running
docker ps | grep n8n

# View logs
sudo journalctl -u n8n -f

# Test connection
curl http://localhost:5678
```

## Security Considerations

The systemd service includes security hardening:
- Runs as non-root user (`n8n`)
- `NoNewPrivileges=true` prevents privilege escalation
- `PrivateTmp=true` provides isolated temp directory

Additional recommendations:
- Set up HTTPS with reverse proxy (nginx/caddy)
- Configure firewall rules
- Enable automatic security updates
- Regular backups (see [Operations Guide](../doc/operations.md))

## Next Steps

✅ **Setup Complete!** Your n8n instance is now running in production.

### What's Next?

1. **Configure GitHub Actions** - See [Deployment Guide](../doc/deployment.md) for CI/CD setup
2. **Daily Operations** - Read [Operations Guide](../doc/operations.md) for management and troubleshooting
3. **Set Up Reverse Proxy** - Configure HTTPS access
4. **Configure Backups** - Set up automated backups (see Operations Guide)

### Automatic Restart

Your n8n instance will automatically restart after:
- ✅ Server reboot
- ✅ Container crash  
- ✅ Service failure
- ✅ Deployment updates

### Useful Commands

```bash
# Service management
sudo systemctl status n8n
sudo systemctl restart n8n

# View logs
sudo journalctl -u n8n -f
docker logs n8n -f

# Check container
docker ps | grep n8n
```

For detailed operations, monitoring, and troubleshooting, see the [Operations Guide](../doc/operations.md).
