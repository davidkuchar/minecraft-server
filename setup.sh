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