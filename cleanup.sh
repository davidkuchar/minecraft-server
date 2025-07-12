#!/bin/bash

echo "Stopping and cleaning up Pterodactyl environment..."

# Stop all services
docker-compose down -v

# Remove volumes (optional - comment out if you want to keep data)
echo "Removing volumes..."
sudo rm -rf volumes/

echo "Cleanup complete!"