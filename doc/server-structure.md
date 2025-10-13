# Server Directory Structure

The n8n application is deployed to `/opt/n8n` on the production server.

## Directory Layout

```
/opt/n8n/
├── deploy/              # Deployment artifacts (created by GitHub Actions)
│   ├── n8n-custom.tar.gz   # Docker image (temporary, cleaned up after deployment)
│   └── scripts/            # Deployment scripts
│       ├── start.sh
│       ├── stop.sh
│       ├── restart.sh
│       ├── build.sh
│       └── dev.sh
└── backup/              # Backup directory (mounted into container)
    ├── credentials/     # Exported credentials
    └── workflows/       # Exported workflows
```

## Docker Volumes

- `n8n_data` - Persistent n8n data (workflows, credentials, settings)
  - Mounted at `/home/node/.n8n` inside the container

## Server Setup Requirements

### 1. Create Directory Structure

```bash
sudo mkdir -p /opt/n8n/deploy
sudo mkdir -p /opt/n8n/backup
```

### 2. User Setup

```bash
# Create n8n user
sudo useradd -d /opt/n8n -s /bin/bash n8n

# Add to docker group
sudo usermod -aG docker n8n

# Set ownership
sudo chown -R n8n:docker /opt/n8n
```

### 3. Docker Volume

The `n8n_data` volume is automatically created by Docker when the container first starts. No manual creation needed.

### 4. SSH Access for Deployment

```bash
# As user n8n
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys

# Add your GitHub deployment SSH public key to authorized_keys
```

## GitHub Actions Workflow

The deployment pipeline will:

1. **Build** the Docker image (`n8n-custom`)
2. **Transfer** the image and scripts to `/opt/n8n/deploy`
3. **Deploy** by loading the image and restarting the container
4. **Cleanup** temporary files

## Container Configuration

The n8n container runs with:

- **Name**: `n8n`
- **Image**: `n8n-custom`
- **Port**: `5678` (host) → `5678` (container)
- **Volumes**:
  - `n8n_data:/home/node/.n8n` (persistent data)
  - `/opt/n8n/backup:/home/node/backup` (backups)
- **Environment**:
  - `WEBHOOK_URL` - Webhook base URL
- **User**: `1000:1000` (node user)
- **Restart**: `always`

## Systemd Service (Optional)

If you want to use systemd instead of direct Docker commands, see [server.md](server.md) for systemd unit configuration.

## Monitoring

### Check Container Status
```bash
docker ps | grep n8n
```

### View Logs
```bash
docker logs n8n -f
```

### Check Disk Usage
```bash
# Check directory size
du -sh /opt/n8n/*

# Check volume size
docker system df -v
```

## Backup Strategy

Backups are stored in `/opt/n8n/backup` and are:
- Mounted into the container at `/home/node/backup`
- Accessible by the n8n user on the host
- Not included in the Docker image or volumes

### Manual Backup
```bash
# Export workflows
docker exec n8n n8n export:workflow --backup --output=/home/node/backup

# Export credentials (encrypted)
docker exec n8n n8n export:credentials --backup --output=/home/node/backup
```

### Automated Backup
Consider setting up a cron job:
```bash
# As user n8n
crontab -e

# Add daily backup at 2 AM
0 2 * * * docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows-$(date +\%Y\%m\%d).json
```

