# Setup Files

This directory contains setup documentation for deploying n8n in production.

## Contents

### production-setup.md
Complete guide for setting up n8n in production with systemd service management, automatic restart, and monitoring.

**📖 [Read the Production Setup Guide](production-setup.md)**

This guide covers:
- Docker installation
- User and directory setup
- SSH configuration
- Systemd service creation (inline)
- First deployment
- Verification steps

The systemd service file content is included directly in the guide - no separate files needed.

## Production vs Development

| Feature | Development | Production |
|---------|-------------|------------|
| Location | Local machine | `/opt/n8n/` on server |
| Management | Manual scripts | Systemd service |
| Auto-restart | Manual | Automatic |
| Startup on boot | No | Yes |

## Documentation

- **[Production Setup Guide](production-setup.md)** - Initial one-time setup
- **[Operations Guide](../doc/operations.md)** - Daily operations, monitoring, troubleshooting
- [Server Structure](../doc/server-structure.md) - Directory layout
- [Deployment Guide](../doc/deployment.md) - CI/CD configuration

## Deployment

The setup documentation is automatically deployed to the server via GitHub Actions for reference, but the actual systemd service is created manually following the guide.

