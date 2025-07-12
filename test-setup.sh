#!/bin/bash

echo "Testing Pterodactyl Minecraft Setup..."

# Function to check if service is responding
check_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1

    echo "Checking $name..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
            echo "✓ $name is responding"
            return 0
        fi
        echo "  Attempt $attempt/$max_attempts - waiting for $name..."
        sleep 10
        ((attempt++))
    done
    echo "✗ $name failed to respond after $max_attempts attempts"
    return 1
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "✗ Docker is not running"
    exit 1
fi
echo "✓ Docker is running"

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    echo "✗ Services are not running. Run './setup.sh' first."
    exit 1
fi
echo "✓ Docker Compose services are running"

# Test database connectivity
if docker-compose exec -T database mysql -u pterodactyl -pCHANGE_ME -e "SELECT 1;" > /dev/null 2>&1; then
    echo "✓ Database is accessible"
else
    echo "✗ Database connection failed"
    exit 1
fi

# Test Redis connectivity
if docker-compose exec -T cache redis-cli ping | grep -q "PONG"; then
    echo "✓ Redis is responding"
else
    echo "✗ Redis connection failed"
    exit 1
fi

# Test web panel
check_service "http://localhost" "Pterodactyl Panel"

# Test Wings API
check_service "http://localhost:8080" "Wings API"

# Test SFTP port
if nc -z localhost 2022; then
    echo "✓ SFTP port (2022) is open"
else
    echo "✗ SFTP port (2022) is not accessible"
fi

# Test Minecraft port
if nc -z localhost 25565; then
    echo "✓ Minecraft port (25565) is open"
else
    echo "⚠ Minecraft port (25565) not in use (normal if no server created yet)"
fi

echo ""
echo "Testing complete!"
echo ""
echo "If all tests pass, you can:"
echo "1. Access the panel at http://localhost"
echo "2. Login with admin@example.com / admin123"
echo "3. Create a node and configure Wings"
echo "4. Import the Minecraft egg"
echo "5. Create your first Minecraft server"
echo ""