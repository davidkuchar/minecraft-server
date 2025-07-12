#!/bin/bash

# Performance optimization script for 2GB instance

echo "🚀 Optimizing system for 2GB Minecraft server..."

# System optimizations
echo "Applying system memory optimizations..."
sudo sysctl -w vm.swappiness=1
sudo sysctl -w vm.vfs_cache_pressure=50
sudo sysctl -w vm.dirty_ratio=15
sudo sysctl -w vm.dirty_background_ratio=5

# Docker cleanup
echo "Cleaning up Docker resources..."
docker system prune -f --volumes
docker image prune -f

# Log rotation for containers
echo "Setting up log rotation..."
docker ps --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        docker update --log-opt max-size=10m --log-opt max-file=3 "$container" 2>/dev/null
    fi
done

# Optimize container memory if running
if docker ps | grep -q minecraft; then
    echo "Found Minecraft container - checking configuration..."
    
    # Check current memory allocation
    MINECRAFT_MEM=$(docker inspect $(docker ps | grep minecraft | awk '{print $1}') 2>/dev/null | grep -i memory | head -1 || echo "Not limited")
    echo "Current Minecraft memory: $MINECRAFT_MEM"
fi

# Create performance monitoring cron job
echo "Setting up performance monitoring..."
(crontab -l 2>/dev/null; echo "*/15 * * * * /home/ubuntu/minecraft-server/monitor-resources.sh >> /var/log/minecraft-monitor.log") | crontab -

# Optimize Java garbage collection for small heap
echo "Creating optimized Java startup parameters..."
cat > minecraft-java-opts.txt << 'EOF'
# Optimized Java options for 512-768MB Minecraft servers
-Xms128M
-Xmx512M
-XX:+UseG1GC
-XX:+ParallelRefProcEnabled
-XX:MaxGCPauseMillis=200
-XX:+UnlockExperimentalVMOptions
-XX:+DisableExplicitGC
-XX:+AlwaysPreTouch
-XX:G1NewSizePercent=30
-XX:G1MaxNewSizePercent=40
-XX:G1HeapRegionSize=8M
-XX:G1ReservePercent=20
-XX:G1HeapWastePercent=5
-XX:G1MixedGCCountTarget=4
-XX:InitiatingHeapOccupancyPercent=15
-XX:G1MixedGCLiveThresholdPercent=90
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:SurvivorRatio=32
-XX:+PerfDisableSharedMem
-XX:MaxTenuringThreshold=1
EOF

# Create world pre-generation script
cat > pregenerate-world.sh << 'EOF'
#!/bin/bash
# World pre-generation to reduce CPU load during gameplay

echo "Pre-generating world chunks..."
echo "This reduces CPU load when players explore new areas"

# These commands should be run in the Minecraft server console
cat << 'MCEOF'
To pre-generate your world, run these commands in the server console:

For vanilla servers:
/tp @s 0 64 0
/fill -1000 0 -1000 1000 255 1000 air replace #minecraft:air

For Paper/Spigot servers with WorldBorder plugin:
/worldborder set 2000
/worldborder fill
/worldborder fill confirm

This creates a 2000x2000 block world (4 square km) which is sufficient for 2-5 players.
MCEOF
EOF

chmod +x pregenerate-world.sh

echo ""
echo "✅ Performance optimizations applied!"
echo ""
echo "📋 Recommendations for 2GB instance:"
echo "   • Minecraft server: 512MB RAM maximum"
echo "   • Max players: 5"
echo "   • View distance: 6 chunks"
echo "   • Simulation distance: 6 chunks"
echo "   • Pre-generate world chunks (see pregenerate-world.sh)"
echo ""
echo "🔧 Available tools:"
echo "   ./monitor-resources.sh    - Check system resources"
echo "   ./pregenerate-world.sh    - Instructions for world pre-gen"
echo "   docker stats              - Live container resource usage"
echo ""
echo "📊 Performance monitoring enabled (every 15 minutes)"
echo "   Logs: /var/log/minecraft-monitor.log"
echo ""
echo "⚠️  If you experience lag:"
echo "   1. Reduce max-players in server.properties"
echo "   2. Lower view-distance to 4-5"
echo "   3. Pre-generate world chunks"
echo "   4. Restart containers: docker-compose restart"
echo ""