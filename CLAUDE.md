# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Minecraft server project using PaperMC with GeyserMC for cross-platform play. The setup allows both Java Edition and Bedrock Edition (mobile/console) players to connect to the same server.

## Architecture

- **PaperMC**: High-performance Minecraft server implementation
- **GeyserMC**: Plugin that allows Bedrock Edition players to connect
- **Floodgate**: Authentication plugin that works with GeyserMC
- **Docker**: Containerized deployment using itzg/minecraft-server image

## Key Files

- `docker-compose.yml`: Main server configuration and deployment
- `config/geyser-config.yml`: GeyserMC plugin configuration for Bedrock compatibility
- `server.properties`: Core Minecraft server settings
- `.env.example`: Environment variables template
- `start.sh`: Quick start script

## Common Commands

Start the server:
```bash
./start.sh
# or
docker-compose up
```

Stop the server:
```bash
docker-compose down
```

View server logs:
```bash
docker-compose logs -f minecraft
```

Access server console:
```bash
docker exec -it minecraft-server rcon-cli
```

## Network Configuration

- **Java Edition**: Port 25565 (TCP)
- **Bedrock Edition**: Port 19132 (UDP)
- **Online Mode**: Disabled (required for GeyserMC)

## Server Management

Server data is persisted in the `data/` directory. Plugin configurations go in `plugins/` and additional configs in `config/`.

The server automatically downloads and installs GeyserMC and Floodgate plugins on first startup.