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

- **`n8n_data`** - Persistent n8n data (workflows, credentials, settings)
  - Mounted at `/home/node/.n8n` inside the container
  - Automatically created by Docker on first run

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

## See Also

- [Production Setup](production-setup.md) - Initial server setup
- [Operations Guide](operations.md) - Updates, monitoring, backup, and maintenance
- [Deployment Guide](deployment.md) - GitHub Actions configuration
