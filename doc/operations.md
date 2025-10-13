# n8n Operations Guide

This guide covers daily operations, maintenance, monitoring, and troubleshooting of your production n8n instance.

> **Prerequisites:** You should have completed the [Production Setup](production-setup.md) before using this guide.

## Service Management

### Check Status
```bash
sudo systemctl status n8n
```

### View Logs
```bash
# View recent logs
sudo journalctl -u n8n -n 50

# Follow logs in real-time
sudo journalctl -u n8n -f

# View Docker container logs
docker logs n8n -f
```

### Manual Control
```bash
# Start
sudo systemctl start n8n

# Stop
sudo systemctl stop n8n

# Restart
sudo systemctl restart n8n

# Reload (graceful restart)
sudo systemctl reload n8n
```

### Enable/Disable Auto-start
```bash
# Enable (start on boot)
sudo systemctl enable n8n

# Disable auto-start on boot
sudo systemctl disable n8n
```

## Automatic Restart Behavior

The service is configured to restart automatically in these scenarios:

### 1. Server Reboot
- **Systemd** ensures the service starts after Docker is ready
- Service will start automatically on boot (if enabled)

### 2. Container Crashes
- **Docker** `--restart always` policy handles container crashes
- **Systemd** `Restart=on-failure` provides additional safety

### 3. Service Failures
- If the service fails, systemd will restart it after 10 seconds
- Configurable via `RestartSec` in the service file

## Deployment Updates

When GitHub Actions deploys updates:

1. New Docker image is transferred to `/opt/n8n/deploy/`
2. Deployment script runs `./scripts/restart.sh`
3. Systemd detects the change and monitors the new container
4. Service continues running with the new version

**Note:** The systemd service doesn't need to be restarted during deployments - the restart happens at the Docker container level.

## Monitoring

### Check if n8n Starts on Boot

```bash
# Reboot the server
sudo reboot

# After reboot, check if n8n is running
systemctl status n8n
docker ps | grep n8n
```

### Check Startup Time

```bash
# See when the service was started
systemctl show n8n --property=ActiveEnterTimestamp

# See boot time
systemd-analyze
systemd-analyze blame | grep n8n
```

### Monitor Resource Usage

```bash
# Check container resource usage
docker stats n8n

# Check disk usage
docker system df

# Check volume size
docker volume inspect n8n_data

# Check backup directory size
du -sh /opt/n8n/backup
```

### Check Container Health

```bash
# Container status
docker ps -a | grep n8n

# Container details
docker inspect n8n

# Check if port is accessible
curl -f http://localhost:5678 || echo "n8n not responding"
```

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status n8n

# Check detailed logs
sudo journalctl -u n8n -n 100 --no-pager

# Check if scripts are executable
ls -la /opt/n8n/deploy/scripts/

# Check if Docker image exists
docker images | grep n8n-custom
```

### Container Keeps Restarting

```bash
# Check Docker logs
docker logs n8n

# Check if volume exists
docker volume ls | grep n8n_data

# Check permissions
ls -la /opt/n8n/

# Check Docker daemon
sudo systemctl status docker
```

### Service Doesn't Start on Boot

```bash
# Check if service is enabled
systemctl is-enabled n8n

# Enable it if not
sudo systemctl enable n8n

# Check service dependencies
systemctl list-dependencies n8n

# Check boot logs
journalctl -b | grep n8n
```

### High Memory Usage

```bash
# Check container memory
docker stats n8n --no-stream

# Restart to clear memory
sudo systemctl restart n8n

# Set memory limits (edit systemd service)
sudo vim /etc/systemd/system/n8n.service
# Add: Environment="DOCKER_MEMORY=2g"
```

### Port Already in Use

```bash
# Check what's using port 5678
sudo lsof -i :5678
sudo netstat -tlnp | grep 5678

# Stop conflicting service or change n8n port
# Edit: /etc/systemd/system/n8n.service
```

### Cannot Connect to n8n

```bash
# Check if container is running
docker ps | grep n8n

# Check port mapping
docker port n8n

# Test local connection
curl http://localhost:5678

# Check firewall
sudo ufw status
sudo iptables -L | grep 5678
```

## Backup and Restore

### Manual Backup

```bash
# Export workflows
docker exec n8n n8n export:workflow --backup --output=/home/node/backup

# Export credentials (encrypted)
docker exec n8n n8n export:credentials --backup --output=/home/node/backup

# Backup files are in /opt/n8n/backup on the host
ls -lh /opt/n8n/backup
```

### Automated Backup

Create a cron job for regular backups:

```bash
# As n8n user
crontab -e

# Add daily backup at 2 AM
0 2 * * * docker exec n8n n8n export:workflow --backup --output=/home/node/backup/workflows-$(date +\%Y\%m\%d).json
0 2 * * * docker exec n8n n8n export:credentials --backup --output=/home/node/backup/credentials-$(date +\%Y\%m\%d).json
```

### Restore from Backup

```bash
# List available backups
ls -lh /opt/n8n/backup

# Restore workflows
docker exec n8n n8n import:workflow --input=/home/node/backup/workflows.json

# Restore credentials
docker exec n8n n8n import:credentials --input=/home/node/backup/credentials.json
```

## Updating n8n

### Via GitHub Actions (Recommended)

1. Update the n8n version in `Dockerfile`
2. Commit and push to `main` branch
3. GitHub Actions will automatically build and deploy
4. Monitor deployment logs in GitHub Actions
5. Verify deployment:
   ```bash
   docker logs n8n
   systemctl status n8n
   ```

### Manual Update

```bash
# As n8n user
cd /opt/n8n/deploy

# Pull latest changes
git pull origin main

# Rebuild image
docker build -t n8n-custom .

# Restart service
sudo systemctl restart n8n

# Verify
docker logs n8n -f
```

## Maintenance Tasks

### Clean Up Old Docker Images

```bash
# List images
docker images | grep n8n

# Remove old images (keep latest)
docker image prune -f

# Remove specific old image
docker rmi <image-id>
```

### Clean Up Old Logs

```bash
# View log disk usage
journalctl --disk-usage

# Clean logs older than 7 days
sudo journalctl --vacuum-time=7d

# Limit log size to 500MB
sudo journalctl --vacuum-size=500M
```

### Update System Service

If you need to update the systemd service configuration:

```bash
# Edit the service file
sudo vim /etc/systemd/system/n8n.service

# Reload systemd
sudo systemctl daemon-reload

# Restart service
sudo systemctl restart n8n
```

## Security Best Practices

1. **Keep n8n Updated** - Regularly update to latest version
2. **Use HTTPS** - Set up reverse proxy (nginx/caddy) with SSL
3. **Secure Credentials** - Use n8n's encryption for credentials
4. **Backup Regularly** - Automate backups and test restores
5. **Monitor Logs** - Watch for suspicious activity
6. **Restrict Access** - Use firewall rules and/or VPN
7. **Update System** - Keep Ubuntu and Docker updated:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

## Alternative: Docker-Only Approach

If you prefer not to use systemd, you can rely solely on Docker's restart policy:

### Ensure Docker Starts on Boot

```bash
sudo systemctl enable docker
```

### Start Container with Restart Policy

The deployment scripts already include `--restart always`, so the container will:
- Restart if it crashes
- Start automatically when Docker daemon starts
- Start after server reboot (if Docker is enabled)

However, **systemd is still recommended** because it provides:
- Better logging
- Service management
- Dependency control
- Easier troubleshooting

## Getting Help

### Check Documentation
- [Production Setup](production-setup.md)
- [Server Structure](server-structure.md)
- [Deployment Guide](deployment.md)

### Useful Commands Reference

```bash
# Service
sudo systemctl status n8n
sudo systemctl restart n8n
sudo journalctl -u n8n -f

# Docker
docker ps | grep n8n
docker logs n8n -f
docker stats n8n

# System
df -h
free -h
top
```

### n8n Community Resources
- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub Issues](https://github.com/n8n-io/n8n/issues)

