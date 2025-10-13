# Local Development Guide

This guide explains how to set up and run n8n locally for development purposes.

## Quick Start

### 1. Build the Docker Image

First, build the custom n8n Docker image:

**Linux/Unix/macOS:**
```bash
./scripts/build.sh
```

**Windows:**
```powershell
.\scripts\build.ps1
```

### 2. Configure Environment (Optional)

Copy the example environment file and customize it:

```bash
# Create your local .env file
cp env.example .env

# Edit .env with your preferred settings
```

The default values work fine for most local development scenarios.

### 3. Start n8n in Development Mode

**Linux/Unix/macOS:**
```bash
./scripts/dev.sh
```

**Windows:**
```powershell
.\scripts\dev.ps1
```

The development script will:
- Load environment variables from `.env` if it exists
- Start n8n with hot console output (not detached)
- Use container name `n8n-dev` (separate from production)
- Automatically remove the container when stopped (Ctrl+C)

### 4. Access n8n

Open your browser and navigate to:
```
http://localhost:5678
```

## Environment Configuration

The `env.example` file contains all available configuration options. Copy it to `.env` and uncomment/modify the values you need.

### Basic Configuration

```env
# Webhook URL - Use localhost for local development
WEBHOOK_URL=http://localhost:5678

# Port to expose n8n on the host machine
N8N_PORT=5678
```

### Optional: Basic Authentication

```env
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password
```

### Optional: PostgreSQL Database

By default, n8n uses SQLite for local development. To use PostgreSQL:

```env
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=password
```

### Optional: Timezone

```env
GENERIC_TIMEZONE=Europe/Berlin
TZ=Europe/Berlin
```

## Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| Container name | `n8n-dev` | `n8n` |
| Mode | Interactive (console output) | Detached (background) |
| Auto-restart | No (manual restart) | Yes (`--restart always`) |
| Container removal | Automatic on stop | Manual |
| Scripts | `dev.sh` / `dev.ps1` | `start.sh` / `start.ps1` |

## Common Development Tasks

### Rebuild the Docker Image

After modifying the `Dockerfile`, rebuild the image:

**Linux/Unix/macOS:**
```bash
./scripts/build.sh
```

**Windows:**
```powershell
.\scripts\build.ps1
```

### Stop n8n

Press `Ctrl+C` in the terminal where n8n is running. The container will automatically be removed.

Or from another terminal:
```bash
docker stop n8n-dev
```

### View Logs

Since the dev script runs in the foreground, logs are displayed directly in the console.

For background containers, use:
```bash
docker logs n8n-dev -f
```

### Access the Container Shell

```bash
docker exec -it n8n-dev sh
```

### Check Data Persistence

n8n data is stored in the `n8n_data` Docker volume:

```bash
# List volumes
docker volume ls

# Inspect the volume
docker volume inspect n8n_data

# View volume contents
docker run --rm -v n8n_data:/data alpine ls -la /data
```

### Reset Development Data

To start fresh (⚠️ this will delete all workflows and credentials):

```bash
# Stop n8n
docker stop n8n-dev

# Remove the volume
docker volume rm n8n_data

# Recreate the volume
docker volume create n8n_data

# Start n8n again
./scripts/dev.sh
```

## Backup and Restore

### Backup Location

Backups are stored in the `backup` folder at the project root. This folder is:
- Automatically created by the scripts
- Mounted to `/home/node/backup` inside the container
- Excluded from Git (in `.gitignore`)

### Create a Manual Backup

From inside the n8n UI:
1. Go to Settings → Data
2. Export workflows and credentials

Or use the n8n CLI inside the container:
```bash
docker exec -it n8n-dev n8n export:workflow --backup --output=/home/node/backup
docker exec -it n8n-dev n8n export:credentials --backup --output=/home/node/backup
```

### Restore from Backup

Place your backup files in the `backup` folder, then:

```bash
docker exec -it n8n-dev n8n import:workflow --input=/home/node/backup/workflows.json
docker exec -it n8n-dev n8n import:credentials --input=/home/node/backup/credentials.json
```

## Troubleshooting

### Port Already in Use

If port 5678 is already in use, change it in your `.env` file:

```env
N8N_PORT=8080
```

### Permission Issues (Linux/Unix)

If you encounter permission issues with the Docker volume:

```bash
# Option 1: Run with your user ID
docker run --user $(id -u):$(id -g) ...

# Option 2: Fix volume permissions
docker run --rm -v n8n_data:/data alpine chown -R 1000:1000 /data
```

### Container Won't Start

Check if the image was built successfully:

```bash
docker images | grep n8n-custom
```

If not, rebuild:
```bash
./scripts/build.sh
```

### Can't Access n8n at localhost:5678

1. Check if the container is running:
   ```bash
   docker ps | grep n8n-dev
   ```

2. Check container logs:
   ```bash
   docker logs n8n-dev
   ```

3. Verify port mapping:
   ```bash
   docker port n8n-dev
   ```

## VS Code Integration

If using VS Code, you can add these tasks to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "n8n: Build",
      "type": "shell",
      "command": "./scripts/build.sh",
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "n8n: Start Dev",
      "type": "shell",
      "command": "./scripts/dev.sh",
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    }
  ]
}
```

## Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Environment Variables](https://docs.n8n.io/hosting/environment-variables/)
- [Docker Documentation](https://docs.docker.com/)

