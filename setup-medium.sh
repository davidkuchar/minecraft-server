#!/bin/bash

echo "Setting up Pterodactyl for 4GB Medium Production Environment..."

# Check available memory
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%d", $2}')
if [ $TOTAL_MEM -lt 3800 ]; then
    echo "Warning: Less than 4GB RAM detected. This setup requires at least 4GB."
    echo "Available: ${TOTAL_MEM}MB"
    echo "Consider using setup-small.sh for 2GB instances instead."
fi

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

# Copy medium environment file
cp .env volumes/panel/env/.env

# Set memory limits for better resource management
export COMPOSE_HTTP_TIMEOUT=120
export DOCKER_CLIENT_TIMEOUT=120

# Start database and cache first
echo "Starting database and cache services..."
docker-compose up -d database cache

# Wait for database to be ready
echo "Waiting for database initialization (60 seconds)..."
sleep 60

# Generate application key
echo "Generating application key..."
docker run --rm -v "$(pwd)/volumes/panel/env:/app" --network minecraft_pterodactyl ghcr.io/pterodactyl/panel:latest php artisan key:generate --no-interaction --force

# Start panel
echo "Starting Pterodactyl panel..."
docker-compose up -d panel

# Wait for panel to be ready
echo "Waiting for panel to start (90 seconds)..."
sleep 90

# Check if panel is responding
PANEL_READY=false
for i in {1..30}; do
    if curl -s --connect-timeout 5 http://localhost > /dev/null 2>&1; then
        PANEL_READY=true
        break
    fi
    echo "Waiting for panel to respond... (attempt $i/30)"
    sleep 10
done

if [ "$PANEL_READY" != true ]; then
    echo "Error: Panel failed to start. Check logs with: docker-compose logs panel"
    exit 1
fi

# Run database migrations
echo "Running database migrations..."
docker-compose exec panel php artisan migrate --seed --force

# Create admin user
echo "Creating admin user..."
ADMIN_PASSWORD=$(openssl rand -base64 16)
docker-compose exec panel php artisan p:user:make \
    --email=admin@minecraft-server.local \
    --username=admin \
    --name-first=Admin \
    --name-last=User \
    --password="$ADMIN_PASSWORD" \
    --admin=1

# Start Wings
echo "Starting Wings daemon..."
docker-compose up -d wings

# Wait for Wings to start
echo "Waiting for Wings to start..."
sleep 30

# Display memory usage
echo ""
echo "Memory usage after startup:"
docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "✅ Medium (4GB) production setup complete!"
echo ""
echo "🌐 Access panel at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost')"
echo "👤 Admin credentials:"
echo "   Email: admin@minecraft-server.local"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "📋 Next steps:"
echo "1. Login to the panel"
echo "2. Go to Admin → Nodes → Create New"
echo "3. Configure node:"
echo "   - FQDN: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost')"
echo "   - SSL: No"
echo "   - Port: 8080"
echo "   - Memory: 2048 MB (can allocate more for 4GB instance)"
echo "   - Disk: 16384 MB"
echo "4. Copy Wings config and update volumes/wings/config.yml"
echo "5. Restart Wings: docker-compose restart wings"
echo "6. Import minecraft-eggs/minecraft-java-medium.json"
echo "7. Create Minecraft server with 1536-2048MB RAM allocation"
echo ""
echo "💡 Resource monitoring:"
echo "   docker stats              # Monitor container resources"
echo "   ./monitor-resources.sh    # Comprehensive resource check"
echo "   free -h                   # Check system memory"
echo "   df -h                     # Check disk space"
echo ""
echo "🚀 Performance recommendations for 4GB instance:"
echo "   • Minecraft server: 1536-2048MB RAM"
echo "   • Max players: 10-15"
echo "   • View distance: 8-10 chunks"
echo "   • Simulation distance: 8 chunks"
echo "   • Can run multiple small servers or one large server"
echo ""
echo "⚡ For optimal performance, run: ./optimize-performance-medium.sh"
echo ""

# Save admin password to file for reference
echo "$ADMIN_PASSWORD" > admin-password.txt
chmod 600 admin-password.txt
echo "Admin password saved to admin-password.txt"