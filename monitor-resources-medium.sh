#!/bin/bash

# Resource monitoring script for 4GB medium instance

echo "=== Medium Instance Resource Monitor ==="
echo "Timestamp: $(date)"
echo ""

# System memory usage
echo "🖥️  System Memory (4GB Instance):"
free -h | grep -E "Mem:|Swap:"
MEMORY_PERCENT=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
echo "Memory utilization: ${MEMORY_PERCENT}%"
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
DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo ""
echo "Docker data usage:"
docker system df 2>/dev/null || echo "Docker not available"
echo ""

# Load average
echo "⚡ System Load:"
uptime
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
echo ""

# Network connections and server status
echo "🌐 Minecraft Server Status:"
MINECRAFT_CONN=$(netstat -tn 2>/dev/null | grep :25565 | grep ESTABLISHED | wc -l)
MINECRAFT_PORTS=$(netstat -ln 2>/dev/null | grep :2556 | wc -l)
echo "Active Minecraft servers: $MINECRAFT_PORTS"
echo "Total players connected: $MINECRAFT_CONN"

# Check for specific server ports
echo "Server ports in use:"
netstat -ln 2>/dev/null | grep :2556 | awk '{print $4}' | sed 's/.*://' | sort | while read port; do
    CONN_COUNT=$(netstat -tn 2>/dev/null | grep :$port | grep ESTABLISHED | wc -l)
    echo "  Port $port: $CONN_COUNT players"
done
echo ""

# Performance metrics
echo "📊 Performance Metrics:"
echo "CPU Load Average: $LOAD_AVG (optimal: < 2.0 for 2-core instances)"
echo "Memory Usage: ${MEMORY_PERCENT}% (warning: > 80%, critical: > 90%)"
echo "Disk Usage: ${DISK_PERCENT}% (warning: > 75%, critical: > 85%)"
echo ""

# Check for performance issues and alerts
echo "🚨 Performance Alerts:"
ALERTS=0

if (( $(echo "$LOAD_AVG > 2.0" | bc -l) )); then
    echo "⚠️  HIGH CPU LOAD: $LOAD_AVG (consider reducing max-players or view-distance)"
    ALERTS=$((ALERTS + 1))
fi

if [ "$MEMORY_PERCENT" -gt 80 ]; then
    echo "⚠️  HIGH MEMORY USAGE: ${MEMORY_PERCENT}%"
    if [ "$MEMORY_PERCENT" -gt 90 ]; then
        echo "🔴 CRITICAL MEMORY: Consider reducing Minecraft server memory allocation"
    else
        echo "🟡 Consider monitoring server performance closely"
    fi
    ALERTS=$((ALERTS + 1))
fi

if [ "$DISK_PERCENT" -gt 75 ]; then
    echo "⚠️  HIGH DISK USAGE: ${DISK_PERCENT}%"
    echo "   Recommend: docker system prune -f && ./backup-medium.sh"
    ALERTS=$((ALERTS + 1))
fi

if [ "$MINECRAFT_CONN" -gt 15 ]; then
    echo "⚠️  HIGH PLAYER COUNT: ${MINECRAFT_CONN} (recommended max: 15 for 4GB)"
    ALERTS=$((ALERTS + 1))
fi

if [ "$ALERTS" -eq 0 ]; then
    echo "✅ All systems operating normally"
fi

echo ""

# Docker log sizes
echo "📋 Docker Log Sizes:"
docker ps --format "table {{.Names}}" | tail -n +2 | while read container; do
    if [ ! -z "$container" ]; then
        LOG_SIZE=$(docker inspect --format='{{.LogPath}}' "$container" 2>/dev/null | xargs ls -lah 2>/dev/null | awk '{print $5}' || echo "N/A")
        echo "$container: $LOG_SIZE"
    fi
done

# Check Minecraft server logs for errors (last 10 lines)
echo ""
echo "🎮 Recent Minecraft Server Activity:"
MINECRAFT_CONTAINERS=$(docker ps --filter "ancestor=ghcr.io/pterodactyl/yolks:java_17" --format "{{.Names}}" 2>/dev/null)
if [ ! -z "$MINECRAFT_CONTAINERS" ]; then
    echo "$MINECRAFT_CONTAINERS" | while read container; do
        echo "=== $container ==="
        docker logs --tail 5 "$container" 2>/dev/null | grep -E "(joined|left|WARN|ERROR)" | tail -3 || echo "No recent activity"
    done
else
    echo "No active Minecraft servers found"
fi

echo ""
echo "=== End Medium Instance Report ==="

# Auto-cleanup if disk usage is high
if [ "$DISK_PERCENT" -gt 85 ]; then
    echo ""
    echo "🧹 Auto-cleanup triggered (disk >85% full)"
    docker system prune -f --volumes
    echo "Cleanup completed"
fi

# Performance recommendations based on current state
if [ "$ALERTS" -gt 2 ]; then
    echo ""
    echo "💡 Performance Recommendations:"
    echo "   • Consider upgrading to a larger instance"
    echo "   • Reduce Minecraft server memory allocation"
    echo "   • Lower view-distance and simulation-distance"
    echo "   • Pre-generate world chunks to reduce CPU load"
    echo "   • Monitor player count and set limits"
fi