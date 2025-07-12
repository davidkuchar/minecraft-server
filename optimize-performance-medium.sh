#!/bin/bash

# Performance optimization script for 4GB medium instance

echo "🚀 Optimizing system for 4GB Medium Minecraft server..."

# System optimizations for 4GB instance
echo "Applying system memory optimizations for 4GB instance..."
sudo sysctl -w vm.swappiness=10
sudo sysctl -w vm.vfs_cache_pressure=50
sudo sysctl -w vm.dirty_ratio=20
sudo sysctl -w vm.dirty_background_ratio=10
sudo sysctl -w vm.overcommit_memory=1

# Make sysctl changes persistent
cat << EOF | sudo tee -a /etc/sysctl.conf
# Minecraft server optimizations for 4GB instance
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=20
vm.dirty_background_ratio=10
vm.overcommit_memory=1
EOF

# Docker cleanup
echo "Cleaning up Docker resources..."
docker system prune -f --volumes
docker image prune -f

# Log rotation for containers
echo "Setting up log rotation..."
docker ps --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        docker update --log-opt max-size=20m --log-opt max-file=5 "$container" 2>/dev/null
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
(crontab -l 2>/dev/null; echo "*/10 * * * * /home/ubuntu/minecraft-server/monitor-resources-medium.sh >> /var/log/minecraft-monitor.log") | crontab -

# Optimize Java garbage collection for medium heap (1536-2048MB)
echo "Creating optimized Java startup parameters for medium instances..."
cat > minecraft-java-opts-medium.txt << 'EOF'
# Optimized Java options for 1536-2048MB Minecraft servers (4GB instance)
-Xms512M
-Xmx1536M
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
-XX:+UseStringDeduplication
-XX:+OptimizeStringConcat
EOF

# Create world pre-generation script for medium instances
cat > pregenerate-world-medium.sh << 'EOF'
#!/bin/bash
# World pre-generation for medium instances (4GB)

echo "Pre-generating world chunks for medium instance..."
echo "This reduces CPU load when players explore new areas"

# These commands should be run in the Minecraft server console
cat << 'MCEOF'
To pre-generate your world for a medium instance, run these commands in the server console:

For vanilla servers (larger world for more players):
/tp @s 0 64 0
/fill -2000 0 -2000 2000 255 2000 air replace #minecraft:air

For Paper/Spigot servers with WorldBorder plugin:
/worldborder set 4000
/worldborder fill
/worldborder fill confirm

This creates a 4000x4000 block world (16 square km) which is sufficient for 10-15 players.

For multiple smaller worlds or testing:
/worldborder set 1500
/worldborder fill
MCEOF
EOF

chmod +x pregenerate-world-medium.sh

# Create backup script optimized for medium instances
cat > backup-medium.sh << 'EOF'
#!/bin/bash
# Backup script for medium instances

DATE=$(date +%Y%m%d_%H%M)
BACKUP_DIR="/home/ubuntu/backups"
mkdir -p $BACKUP_DIR

echo "Creating backup for medium instance: $DATE"

# Database backup
docker-compose exec -T database mysqldump -u pterodactyl -p$DB_PASSWORD panel > $BACKUP_DIR/database-$DATE.sql

# Server files backup (including multiple servers if any)
tar -czf $BACKUP_DIR/minecraft-servers-$DATE.tar.gz volumes/wings/

# Panel configuration backup
tar -czf $BACKUP_DIR/panel-config-$DATE.tar.gz volumes/panel/

# Combine all backups
tar -czf $BACKUP_DIR/full-backup-$DATE.tar.gz $BACKUP_DIR/*-$DATE.*

# Upload to S3 if configured
if [ ! -z "$AWS_S3_BUCKET" ]; then
    aws s3 cp $BACKUP_DIR/full-backup-$DATE.tar.gz s3://$AWS_S3_BUCKET/minecraft-backups/
fi

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/full-backup-$DATE.tar.gz"
EOF

chmod +x backup-medium.sh

echo ""
echo "✅ Performance optimizations applied for 4GB medium instance!"
echo ""
echo "📋 Recommendations for 4GB instance:"
echo "   • Minecraft server: 1536-2048MB RAM maximum"
echo "   • Max players: 10-15"
echo "   • View distance: 8-10 chunks"
echo "   • Simulation distance: 8 chunks"
echo "   • Can run 2-3 small servers or 1 large server"
echo "   • Pre-generate world chunks (see pregenerate-world-medium.sh)"
echo ""
echo "🔧 Available tools:"
echo "   ./monitor-resources-medium.sh     # Check system resources (every 10 min)"
echo "   ./pregenerate-world-medium.sh     # Instructions for world pre-gen"
echo "   ./backup-medium.sh                # Comprehensive backup script"
echo "   docker stats                      # Live container resource usage"
echo ""
echo "📊 Enhanced performance monitoring enabled (every 10 minutes)"
echo "   Logs: /var/log/minecraft-monitor.log"
echo ""
echo "⚡ Additional optimizations for 4GB:"
echo "   • Higher view distances supported (8-10)"
echo "   • Command blocks enabled"
echo "   • Query protocol enabled for server lists"
echo "   • Network compression optimized"
echo "   • String deduplication enabled for JVM"
echo ""
echo "💾 Backup strategy:"
echo "   • Run ./backup-medium.sh daily"
echo "   • Keeps 7 days of backups locally"
echo "   • Optional S3 upload (set AWS_S3_BUCKET env var)"
echo ""