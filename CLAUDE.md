# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a complete Pterodactyl panel setup for managing Minecraft servers using Docker and Docker Compose. It includes local development environment setup and AWS deployment documentation.

## Key Files

**Local Development:**
- `docker-compose.yml`: Main orchestration file for local development
- `.env`: Environment configuration for local setup
- `setup.sh`: Automated setup script for local development
- `test-setup.sh`: Validation script to test the complete setup
- `cleanup.sh`: Environment cleanup and reset script

**Production Configurations:**
- `docker-compose.small.yml`: 2GB instance optimized configuration
- `docker-compose.medium.yml`: 4GB instance optimized configuration
- `.env.small`: Environment settings for 2GB instances
- `.env.medium`: Environment settings for 4GB instances

**Deployment Scripts:**
- `setup-small.sh`: Automated setup for 2GB instances
- `setup-medium.sh`: Automated setup for 4GB instances
- `optimize-performance.sh`: Performance tuning for 2GB instances
- `optimize-performance-medium.sh`: Advanced tuning for 4GB instances

**Monitoring & Maintenance:**
- `monitor-resources.sh`: Resource monitoring for 2GB instances
- `monitor-resources-medium.sh`: Enhanced monitoring for 4GB instances
- `backup-medium.sh`: Comprehensive backup script for 4GB instances

**Server Configurations:**
- `minecraft-eggs/minecraft-java-small.json`: Optimized egg for 2GB instances
- `minecraft-eggs/minecraft-java-medium.json`: Optimized egg for 4GB instances
- `minecraft-keypair.pem`: SSH private key for AWS EC2 server access
- `volumes/wings/config.yml`: Wings daemon configuration (needs manual setup)

## Common Development Commands

```bash
# Initial setup (creates admin user, runs migrations)
./setup.sh

# Test the complete environment
./test-setup.sh

# Start services
docker-compose up -d

# View service logs
docker-compose logs -f [panel|wings|database|cache]

# Stop services
docker-compose down

# Complete environment reset
./cleanup.sh
```

## Architecture

**Multi-container Docker setup:**
- **Panel**: Pterodactyl web interface (port 80)
- **Wings**: Game server daemon (port 8080, manages actual Minecraft containers)
- **Database**: MariaDB for panel data
- **Cache**: Redis for session/queue management

**Service Dependencies:**
1. Database and Cache start first
2. Panel connects to both and runs migrations
3. Wings connects to Panel API for server management

## Development Workflow

1. Run `./setup.sh` for initial environment setup
2. Access panel at http://localhost (admin@example.com / admin123)
3. Create node in Admin → Nodes (FQDN: localhost, port 8080)
4. Copy Wings config from panel to `volumes/wings/config.yml`
5. Restart Wings: `docker-compose restart wings`
6. Import Minecraft egg from `minecraft-eggs/minecraft-java.json`
7. Create Minecraft servers through the web interface

## AWS Deployment Options

See `aws-deployment.md` and `deploy-size-guide.md` for complete EC2 deployment process.

### Small Instance (2GB) - Budget Setup
**Cost:** ~$15-22/month | **Players:** 2-5 | **Memory:** 512-768MB Minecraft
```bash
cp .env.small .env && cp docker-compose.small.yml docker-compose.yml
./setup-small.sh
```

### Medium Instance (4GB) - Better Performance  
**Cost:** ~$30-40/month | **Players:** 5-15 | **Memory:** 1536-2048MB Minecraft
```bash
cp .env.medium .env && cp docker-compose.medium.yml docker-compose.yml
./setup-medium.sh
```

**Key considerations:**
- Use `minecraft-keypair.pem` for EC2 instance access
- Instance size determines available tools and optimizations
- Security groups configured per instance type
- Automated environment variable setup included

## Security Notes

- Change default passwords in `.env` for production
- `minecraft-keypair.pem` contains sensitive SSH key material (chmod 600)
- Wings requires privileged Docker access for container management
- Use SSL certificates in production environments