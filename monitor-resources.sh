#!/bin/bash

# Resource monitoring script for 2GB instance

echo "=== System Resource Monitor ==="
echo "Timestamp: $(date)"
echo ""

# System memory usage
echo "🖥️  System Memory:"
free -h | grep -E "Mem:|Swap:"
echo ""

# Docker container resources
echo "🐳 Container Resources:"
if docker ps -q > /dev/null 2>&1; then
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
else
    echo "Docker not running or no containers"
fi
echo ""

# Disk usage
echo "💾 Disk Usage:"
df -h / | tail -1
echo ""
echo "Docker data usage:"
docker system df 2>/dev/null || echo "Docker not available"
echo ""

# Load average
echo "⚡ System Load:"
uptime
echo ""

# Network connections
echo "🌐 Active Connections:"
MINECRAFT_CONN=$(netstat -tn 2>/dev/null | grep :25565 | grep ESTABLISHED | wc -l)
echo "Minecraft players connected: $MINECRAFT_CONN"
echo ""

# Check for memory pressure
MEMORY_PERCENT=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

echo "🚨 Alerts:"
if [ "$MEMORY_PERCENT" -gt 85 ]; then
    echo "⚠️  HIGH MEMORY USAGE: ${MEMORY_PERCENT}%"
    echo "   Consider reducing Minecraft server memory allocation"
fi

if [ "$DISK_PERCENT" -gt 80 ]; then
    echo "⚠️  HIGH DISK USAGE: ${DISK_PERCENT}%"
    echo "   Run: docker system prune -f"
fi

if [ "$MINECRAFT_CONN" -gt 5 ]; then
    echo "⚠️  HIGH PLAYER COUNT: ${MINECRAFT_CONN} (recommended max: 5)"
fi

# Docker log sizes
echo ""
echo "📋 Docker Log Sizes:"
docker ps --format "table {{.Names}}" | tail -n +2 | while read container; do
    if [ ! -z "$container" ]; then
        LOG_SIZE=$(docker inspect --format='{{.LogPath}}' "$container" 2>/dev/null | xargs ls -lah 2>/dev/null | awk '{print $5}' || echo "N/A")
        echo "$container: $LOG_SIZE"
    fi
done

echo ""
echo "=== End Report ==="

# Auto-cleanup if disk usage is high
if [ "$DISK_PERCENT" -gt 85 ]; then
    echo ""
    echo "🧹 Auto-cleanup triggered (disk >85% full)"
    docker system prune -f --volumes
    echo "Cleanup completed"
fi