# n8n Plattform für meimberg.io

## Quick Start

### Local Development
```bash
# Build the custom Docker image
./scripts/build.sh         # Linux/macOS
.\scripts\build.ps1        # Windows

# Start n8n in development mode
./scripts/dev.sh           # Linux/macOS
.\scripts\dev.ps1          # Windows

# Access at http://localhost:5678
```

### Production Deployment
Automated deployment via GitHub Actions on push to `main` branch.

## Dokumentation

### Production
* [Production Setup](doc/production-setup.md) ⭐ **Initial production setup** (one-time)
* [Operations Guide](doc/operations.md) 🔧 **Daily operations** (updates, maintenance, monitoring, troubleshooting)
* [Server Structure](doc/server-structure.md) - Directory layout on production
* [Deployment](doc/deployment.md) - GitHub Actions deployment configuration

### Development
* [Local Development](doc/local-development.md) - Running n8n locally
