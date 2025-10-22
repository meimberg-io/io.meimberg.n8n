# n8n Backup Setup

Setup instructions for automated n8n workflow and credential backups.

## Architecture

n8n exports its own backups to a mounted directory that Ansible then archives:

```
Host: /srv/backups/n8n/
           ↕ (mounted)
Container: /home/node/backup/
```

- n8n exports to `/home/node/backup/` (inside container)
- This is `/srv/backups/n8n/` on the host
- Ansible backs up `/srv/backups/` nightly at 3 AM

## Setup Steps

### 1. Verify Mount Point

The directory is created by Ansible and mounted in `docker-compose.prod.yml`:

```yaml
volumes:
  - n8n_data:/home/node/.n8n
  - /srv/backups/n8n:/home/node/backup  # ← Backup mount
```

### 2. Add Export Script to Container

**Option A: Copy Script After Deployment (Quick)**

After n8n is deployed, copy the export script:

```bash
# SSH to server
ssh deploy@hc-02.meimberg.io

# Copy script to container
cd /srv/projects/n8n
docker cp scripts/export-backup.sh n8n:/usr/local/bin/export-backup.sh

# Make executable
docker exec n8n chmod +x /usr/local/bin/export-backup.sh

# Test it
docker exec n8n /usr/local/bin/export-backup.sh
```

**Option B: Add to Dockerfile (Permanent)**

Update `Dockerfile` to include the script:

```dockerfile
# Copy backup script
COPY scripts/export-backup.sh /usr/local/bin/export-backup.sh
RUN chmod +x /usr/local/bin/export-backup.sh
```

Rebuild and redeploy.

**Option C: Use Deployment Script**

Add to `.github/workflows/deploy.yml` after container is started:

```yaml
- name: Setup n8n backup export
  run: |
    docker cp scripts/export-backup.sh n8n:/usr/local/bin/export-backup.sh
    docker exec n8n chmod +x /usr/local/bin/export-backup.sh
```

### 3. Test Manual Export

```bash
ssh deploy@hc-02.meimberg.io

# Run export
docker exec n8n /usr/local/bin/export-backup.sh

# Verify exports on host
ls -lh /srv/backups/n8n/workflows/
ls -lh /srv/backups/n8n/credentials/
cat /srv/backups/n8n/last_export.txt
```

### 4. Setup Automated Export (Cron)

Add cron job to export before Ansible backup (2:30 AM):

```bash
ssh deploy@hc-02.meimberg.io

# Install cron in container (if not present)
docker exec -u root n8n apk add --no-cache dcron

# Create cron directory for logs
docker exec n8n mkdir -p /home/node/.n8n/logs

# Add cron job (runs at 2:30 AM)
docker exec n8n sh -c 'echo "30 2 * * * /usr/local/bin/export-backup.sh >> /home/node/.n8n/logs/backup.log 2>&1" | crontab -'

# Verify cron is set
docker exec n8n crontab -l

# Start crond (if not running)
docker exec -u root n8n crond
```

**Timeline**:
- 2:30 AM - n8n exports workflows/credentials to `/srv/backups/n8n/`
- 3:00 AM - Ansible backs up `/srv/backups/` to Storage Box

### 5. Verify Automated Backup

Check after first automated run:

```bash
# Check export log
ssh deploy@hc-02.meimberg.io
docker exec n8n cat /home/node/.n8n/logs/backup.log

# Check exports
ls -lh /srv/backups/n8n/workflows/
cat /srv/backups/n8n/last_export.txt

# Check Ansible backup includes n8n
ssh root@hc-02.meimberg.io
cat /var/log/backup.log
```

## Alternative: Manual Backup Only

If you don't want automated exports, you can export manually before important changes:

```bash
# SSH to server
ssh deploy@hc-02.meimberg.io

# Export workflows
docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows/

# Export credentials
docker exec n8n n8n export:credentials --all --output=/home/node/backup/credentials/credentials.json

# Exports are now in /srv/backups/n8n/ and will be included in next Ansible backup
```

## Restore from Backup

See [io.meimberg.ansible/docs/N8N-BACKUP.md](../../io.meimberg.ansible/docs/N8N-BACKUP.md) for restore procedures.

Quick restore:

```bash
# Copy exports to server
scp -r workflows/*.json deploy@hc-02.meimberg.io:/srv/backups/n8n/workflows/
scp credentials.json deploy@hc-02.meimberg.io:/srv/backups/n8n/credentials/

# Import from mounted directory
ssh deploy@hc-02.meimberg.io
docker exec n8n n8n import:workflow --input=/home/node/backup/workflows/My_Workflow.json
docker exec n8n n8n import:credentials --input=/home/node/backup/credentials/credentials.json
```

## Troubleshooting

### Export Script Not Found

```bash
# Verify script is in container
docker exec n8n ls -l /usr/local/bin/export-backup.sh

# If missing, copy from host
docker cp scripts/export-backup.sh n8n:/usr/local/bin/export-backup.sh
docker exec n8n chmod +x /usr/local/bin/export-backup.sh
```

### Cron Not Running

```bash
# Check if crond is running
docker exec n8n ps | grep crond

# Start crond
docker exec -u root n8n crond

# Check cron logs
docker exec n8n cat /home/node/.n8n/logs/backup.log
```

### Empty Exports

```bash
# Check n8n has workflows
docker exec n8n n8n list:workflow

# Run export manually with verbose output
docker exec n8n /usr/local/bin/export-backup.sh
```

## Best Practices

1. ✅ Test manual export after deployment
2. ✅ Verify cron job runs successfully once
3. ✅ Check backup logs weekly
4. ✅ Test restore procedure periodically
5. ✅ Save n8n encryption key securely

## See Also

- [io.meimberg.ansible/docs/N8N-BACKUP.md](../../io.meimberg.ansible/docs/N8N-BACKUP.md) - Full backup documentation
- [scripts/export-backup.sh](scripts/export-backup.sh) - Export script
- [docker-compose.prod.yml](docker-compose.prod.yml) - Container configuration

