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

# Create nginx configuration if it doesn't exist
if [ ! -f volumes/panel/nginx/nginx.conf ]; then
    echo "Creating nginx configuration..."
    cat > volumes/panel/nginx/nginx.conf << 'EOF'
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    server {
        listen 80;
        server_name _;
        
        root /app/public;
        index index.html index.htm index.php;

        client_max_body_size 100m;
        client_body_timeout 120s;

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param HTTP_PROXY "";
            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
            fastcgi_read_timeout 300;
        }

        location ~ /\.ht {
            deny all;
        }
    }
}
EOF
fi

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