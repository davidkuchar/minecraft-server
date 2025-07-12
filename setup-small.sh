#!/bin/bash

echo "Setting up Pterodactyl for 2GB Small Instance Environment..."

# Check available memory
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%d", $2}')
if [ $TOTAL_MEM -lt 1800 ]; then
    echo "Warning: Less than 2GB RAM detected. This setup requires at least 2GB."
    echo "Available: ${TOTAL_MEM}MB"
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

# Copy small instance environment file
cp .env volumes/panel/env/.env

# Set memory limits for better resource management
export COMPOSE_HTTP_TIMEOUT=120
export DOCKER_CLIENT_TIMEOUT=120

# Start database and cache first (small memory footprint)
echo "Starting database and cache services..."
docker-compose up -d database cache

# Wait for database to be ready
echo "Waiting for database initialization (60 seconds)..."
sleep 60

# Generate application key
echo "Generating application key..."
docker run --rm -v "$(pwd)/volumes/panel/env:/app" --network minecraft_pterodactyl ghcr.io/pterodactyl/panel:latest php artisan key:generate --no-interaction --force

# Start panel with memory constraints
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
ADMIN_PASSWORD=$(openssl rand -base64 12)
docker-compose exec panel php artisan p:user:make \
    --email=admin@minecraft-server.local \
    --username=admin \
    --name-first=Admin \
    --name-last=User \
    --password="$ADMIN_PASSWORD" \
    --admin=1

# Start Wings with resource limits
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
echo "✅ Small instance (2GB) setup complete!"
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
echo "   - Memory: 768 MB (leave 1GB+ for system)"
echo "   - Disk: 8192 MB"
echo "4. Copy Wings config and update volumes/wings/config.yml"
echo "5. Restart Wings: docker-compose restart wings"
echo "6. Import minecraft-eggs/minecraft-java-small.json"
echo "7. Create Minecraft server with 512MB RAM limit"
echo ""
echo "💡 Resource monitoring:"
echo "   docker stats          # Monitor container resources"
echo "   free -h               # Check system memory"
echo "   df -h                 # Check disk space"
echo ""
echo "⚠️  Important: Keep Minecraft server memory ≤ 768MB for stable operation"
echo ""

# Save admin password to file for reference
echo "$ADMIN_PASSWORD" > admin-password.txt
chmod 600 admin-password.txt
echo "Admin password saved to admin-password.txt"