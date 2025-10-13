# How-To Guide

Common tasks and workflows for n8n.

## Update n8n Version

Update the n8n version via Git:

```bash
# Edit Dockerfile
vim Dockerfile

# Change version
FROM docker.n8n.io/n8nio/n8n:1.120.0  # Update version number

# Commit and push
git add Dockerfile
git commit -m "chore: update n8n to v1.120.0"
git push origin main
```

GitHub Actions will automatically deploy the new version.

## Add System Dependencies

To add Alpine packages (e.g., for custom nodes):

```bash
# Edit Dockerfile
vim Dockerfile

# Add package to RUN command
RUN apk update && apk add --no-cache perl poppler-utils imagemagick mynewpackage

# Commit and push
git add Dockerfile
git commit -m "feat: add mynewpackage system dependency"
git push origin main
```

## Install Community Nodes

To install n8n community nodes:

```bash
# Edit Dockerfile
vim Dockerfile

# Add at the end (before any commented sections)
USER node
WORKDIR /home/node/.n8n/nodes
RUN npm install n8n-nodes-package-name

# Commit and push
git add Dockerfile
git commit -m "feat: add n8n-nodes-package-name"
git push origin main
```

## Quick Commands

### Restart n8n
```bash
# On server
sudo systemctl restart n8n
```

### View Logs
```bash
# Service logs
sudo journalctl -u n8n -f

# Container logs
docker logs n8n -f
```

### Manual Backup
```bash
# Export workflows
docker exec n8n n8n export:workflow --backup --output=/home/node/backup

# Export credentials
docker exec n8n n8n export:credentials --backup --output=/home/node/backup
```

### Restore from Backup
```bash
# Import workflows
docker exec n8n n8n import:workflow --input=/home/node/backup/workflows.json

# Import credentials
docker exec n8n n8n import:credentials --input=/home/node/backup/credentials.json
```

## See Also

- [Operations Guide](operations.md) - Detailed operations documentation
- [Local Development](local-development.md) - Run n8n locally
