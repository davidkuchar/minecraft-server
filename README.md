# Pterodactyl Minecraft Server Setup

A complete Docker-based setup for running Minecraft servers with Pterodactyl panel for local testing and AWS deployment.

## Quick Start

1. **Prerequisites**
   - Docker and Docker Compose installed
   - At least 4GB RAM available

2. **Local Setup**
   ```bash
   ./setup.sh
   ```

3. **Access Panel**
   - URL: http://localhost
   - Email: admin@example.com
   - Password: admin123

## Project Structure

```
├── docker-compose.yml          # Main Docker Compose configuration
├── .env                        # Environment variables
├── setup.sh                   # Automated setup script
├── cleanup.sh                 # Environment cleanup script
├── aws-deployment.md           # AWS deployment guide
├── volumes/
│   ├── wings/config.yml       # Wings daemon configuration
│   └── panel/                 # Panel data and logs
└── minecraft-eggs/
    └── minecraft-java.json    # Minecraft server egg configuration
```

## Manual Configuration Steps

After running `setup.sh`, complete these steps in the web panel:

1. **Create Node**
   - Go to Admin → Nodes → Create New
   - FQDN: `localhost`
   - SSL: Disabled
   - Daemon Port: `8080`

2. **Configure Wings**
   - Copy the auto-generated configuration from the web panel
   - Update `volumes/wings/config.yml`
   - Restart Wings: `docker-compose restart wings`

3. **Import Minecraft Egg**
   - Go to Admin → Nests → Minecraft
   - Import egg from `minecraft-eggs/minecraft-java.json`

4. **Create Server**
   - Go to Admin → Servers → Create New
   - Select your node and Minecraft egg
   - Configure memory allocation (minimum 512MB)

## Port Configuration

- **80**: Pterodactyl web panel
- **8080**: Wings API
- **2022**: SFTP access
- **25565**: Minecraft server (default)

## Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f [service]

# Stop services
docker-compose down

# Complete cleanup
./cleanup.sh
```

## Troubleshooting

- **Wings not connecting**: Check `volumes/wings/config.yml` has correct token and UUID
- **Database errors**: Ensure database container is fully started before panel
- **Permission issues**: Verify Docker daemon is running and user has permissions

## AWS Deployment Options

See `aws-deployment.md` for complete AWS EC2 deployment instructions with two optimized configurations.

### Small Instance (2GB) - Budget Option
**Best for:** 2-5 players, ~$15-22/month
```bash
# Use small instance configuration
cp .env.small .env
cp docker-compose.small.yml docker-compose.yml
./setup-small.sh
```

### Medium Instance (4GB) - Better Performance  
**Best for:** 5-15 players, multiple servers, ~$30-40/month
```bash
# Use medium instance configuration
cp .env.medium .env
cp docker-compose.medium.yml docker-compose.yml
./setup-medium.sh
```

**Resource management:**
```bash
# Small instance tools
./monitor-resources.sh          # Resource monitoring
./optimize-performance.sh       # Performance tuning

# Medium instance tools  
./monitor-resources-medium.sh   # Enhanced monitoring
./optimize-performance-medium.sh # Advanced tuning
./backup-medium.sh              # Comprehensive backup
```

## Security Notes

- Change default passwords in production
- Use strong database credentials
- Configure SSL certificates for production
- Restrict access to admin panel