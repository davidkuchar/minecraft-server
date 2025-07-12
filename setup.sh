#!/bin/bash

echo "Setting up Pterodactyl Minecraft Server Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Create necessary directories
mkdir -p volumes/database
mkdir -p volumes/panel/var/log/pterodactyl
mkdir -p volumes/panel/nginx/logs
mkdir -p volumes/panel/nginx/ssl
mkdir -p volumes/panel/env

# Copy environment file
cp .env volumes/panel/env/.env

# Generate application key
echo "Generating application key..."
docker run --rm -v "$(pwd)/volumes/panel/env:/app" ghcr.io/pterodactyl/panel:latest php artisan key:generate --no-interaction --force

# Start the services
echo "Starting Pterodactyl services..."
docker-compose up -d database cache

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 30

# Run panel setup
echo "Setting up Pterodactyl panel..."
docker-compose up -d panel

# Wait for panel to be ready
echo "Waiting for panel to start..."
sleep 60

# Run database migrations
echo "Running database migrations..."
docker-compose exec panel php artisan migrate --seed --force

# Create admin user
echo "Creating admin user..."
docker-compose exec panel php artisan p:user:make --email=admin@example.com --username=admin --name-first=Admin --name-last=User --password=admin123 --admin=1

# Start Wings
echo "Starting Wings daemon..."
docker-compose up -d wings

echo ""
echo "Setup complete!"
echo ""
echo "Access the panel at: http://localhost"
echo "Admin credentials:"
echo "  Email: admin@example.com"
echo "  Password: admin123"
echo ""
echo "Next steps:"
echo "1. Login to the panel"
echo "2. Go to Admin > Nodes and create a new node"
echo "3. Configure the node with:"
echo "   - FQDN: localhost"
echo "   - Communicate Over SSL: No"
echo "   - Daemon Port: 8080"
echo "4. Copy the Wings configuration and update volumes/wings/config.yml"
echo "5. Restart Wings: docker-compose restart wings"
echo "6. Import the Minecraft egg from minecraft-eggs/minecraft-java.json"
echo ""