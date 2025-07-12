# AWS EC2 Deployment Guide - 2GB & 4GB Options

This guide covers deploying your Pterodactyl + Minecraft setup to AWS EC2 instances with two optimized configurations.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Your `minecraft-keypair.pem` file
- A tested local setup

## Choose Your Instance Size

### Option 1: Small Instance (2GB) - Budget Setup

**Best for:** 2-5 players, casual gaming, tight budget (~$15-22/month)

```bash
# Create security group for small instance
aws ec2 create-security-group --group-name minecraft-pterodactyl-small --description "Small Minecraft Pterodactyl Server"

# Add security group rules
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-small --protocol tcp --port 22 --cidr 0.0.0.0/0    # SSH
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-small --protocol tcp --port 80 --cidr 0.0.0.0/0    # HTTP
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-small --protocol tcp --port 25565 --cidr 0.0.0.0/0 # Minecraft
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-small --protocol tcp --port 8080 --cidr 0.0.0.0/0  # Wings API
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-small --protocol tcp --port 2022 --cidr 0.0.0.0/0  # SFTP

# Launch 2GB instance
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --instance-type t2.small \
    --key-name minecraft-keypair \
    --security-groups minecraft-pterodactyl-small \
    --block-device-mappings DeviceName=/dev/xvda,Ebs='{VolumeSize=12,VolumeType=gp3}' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=minecraft-pterodactyl-small}]'
```

**Small Instance Specs:**
- **t2.small** (1 vCPU, 2GB RAM) - **RECOMMENDED** 
- **Memory Allocation:** OS(512MB) + Panel(256MB) + Wings(256MB) + Minecraft(512-768MB)
- **Max Players:** 2-5
- **View Distance:** 6 chunks
- **Cost:** ~$15-22/month

### Option 2: Medium Instance (4GB) - Better Performance

**Best for:** 5-15 players, better performance, multiple servers (~$30-40/month)

```bash
# Create security group for medium instance
aws ec2 create-security-group --group-name minecraft-pterodactyl-medium --description "Medium Minecraft Pterodactyl Server"

# Add security group rules
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-medium --protocol tcp --port 22 --cidr 0.0.0.0/0      # SSH
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-medium --protocol tcp --port 80 --cidr 0.0.0.0/0      # HTTP
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-medium --protocol tcp --port 25565-25575 --cidr 0.0.0.0/0 # Minecraft range
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-medium --protocol tcp --port 8080 --cidr 0.0.0.0/0    # Wings API
aws ec2 authorize-security-group-ingress --group-name minecraft-pterodactyl-medium --protocol tcp --port 2022 --cidr 0.0.0.0/0    # SFTP

# Launch 4GB instance
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --instance-type t3.medium \
    --key-name minecraft-keypair \
    --security-groups minecraft-pterodactyl-medium \
    --block-device-mappings DeviceName=/dev/xvda,Ebs='{VolumeSize=20,VolumeType=gp3}' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=minecraft-pterodactyl-medium}]'
```

**Medium Instance Specs:**
- **t3.medium** (2 vCPU, 4GB RAM) - **RECOMMENDED**
- **Memory Allocation:** OS(512MB) + Panel(512MB) + Wings(512MB) + Minecraft(1536-2048MB)
- **Max Players:** 5-15
- **View Distance:** 8-10 chunks
- **Multiple Servers:** Can run 2-3 small servers
- **Cost:** ~$30-40/month

### 3. Connect and Setup

```bash
# Connect to your instance  
ssh -i minecraft-keypair.pem ubuntu@<INSTANCE_IP>

# Update system and optimize for low memory
sudo apt update && sudo apt upgrade -y
sudo swapoff -a
echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf

# Install Docker with optimizations
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Configure Docker for low memory usage
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Reboot to apply memory settings
sudo reboot
```

### 4. Deploy Application

```bash
# Reconnect after reboot
ssh -i minecraft-keypair.pem ubuntu@<INSTANCE_IP>

# Copy files to server (from your local machine)
scp -i minecraft-keypair.pem -r . ubuntu@<INSTANCE_IP>:/home/ubuntu/minecraft-server/

# On the server: Setup production environment
cd minecraft-server

# FOR SMALL INSTANCE (2GB):
cp .env.small .env
cp docker-compose.small.yml docker-compose.yml
# Update environment variables
sed -i "s/YOUR_EC2_IP_OR_DOMAIN/$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/" .env
sed -i "s/CHANGE_TO_STRONG_PASSWORD/$(openssl rand -base64 32)/" .env
sed -i "s/CHANGE_TO_STRONG_ROOT_PASSWORD/$(openssl rand -base64 32)/" .env
# Run small instance setup
./setup-small.sh

# FOR MEDIUM INSTANCE (4GB):
cp .env.medium .env
cp docker-compose.medium.yml docker-compose.yml
# Update environment variables
sed -i "s/YOUR_EC2_IP_OR_DOMAIN/$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/" .env
sed -i "s/CHANGE_TO_STRONG_PASSWORD/$(openssl rand -base64 32)/" .env
sed -i "s/CHANGE_TO_STRONG_ROOT_PASSWORD/$(openssl rand -base64 32)/" .env
# Run medium instance setup
./setup-medium.sh
```

## Domain and SSL Setup (Optional)

### 1. Point Domain to Instance

Create an A record pointing your domain to the EC2 instance's public IP.

### 2. Configure SSL with Let's Encrypt

```bash
# Install certbot
sudo apt install certbot

# Get SSL certificate
sudo certbot certonly --standalone -d yourdomain.com

# Update docker-compose.yml to use SSL certificates
# Mount certificates and update panel environment
```

## Small Instance Considerations

### Memory Management
- Monitor memory usage: `docker stats`
- Minecraft server limited to 512-768MB max
- Use view-distance=6, simulation-distance=6
- Maximum 5 concurrent players recommended
- Pre-generate world chunks to reduce CPU load

### Performance Optimization
```bash
# Monitor system resources
htop
docker stats
df -h

# Cleanup Docker logs
docker system prune -f
```

### Backup Strategy (Minimal)
```bash
# Essential backup script
#!/bin/bash
DATE=$(date +%Y%m%d)
docker-compose exec -T database mysqldump -u pterodactyl -p$DB_PASSWORD panel > backup-$DATE.sql
tar -czf minecraft-backup-$DATE.tar.gz volumes/wings/ backup-$DATE.sql
aws s3 cp minecraft-backup-$DATE.tar.gz s3://your-backup-bucket/
rm backup-$DATE.sql minecraft-backup-$DATE.tar.gz
```

### Cost Optimization for Small Setup
- **t2.small Reserved Instance**: ~$12/month vs ~$17/month on-demand
- **Spot Instances**: ~$5-8/month (may be interrupted)
- **Schedule shutdown**: Stop during off-peak hours
- **12GB EBS**: ~$1.20/month (sufficient for small setup)

### Expected Costs (Monthly)

**Small Instance (2GB):**
- **t2.small**: $12-17/month
- **EBS 12GB**: $1.20/month  
- **Data transfer**: $1-3/month (minimal)
- **Total**: ~$15-22/month

**Medium Instance (4GB):**
- **t3.medium**: $24-30/month
- **EBS 20GB**: $2.00/month
- **Data transfer**: $2-5/month
- **Total**: ~$28-37/month

### Monitoring Alerts
```bash
# Simple resource monitoring script
#!/bin/bash
MEMORY=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
DISK=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ $MEMORY -gt 85 ]; then
    echo "HIGH MEMORY USAGE: ${MEMORY}%"
fi

if [ $DISK -gt 80 ]; then
    echo "HIGH DISK USAGE: ${DISK}%"
fi
```

### Instance-Specific Commands

**Small Instance (2GB):**
```bash
./monitor-resources.sh          # Resource monitoring
./optimize-performance.sh       # Performance tuning
./pregenerate-world.sh          # World pre-generation guide
```

**Medium Instance (4GB):**
```bash
./monitor-resources-medium.sh   # Enhanced monitoring
./optimize-performance-medium.sh # Advanced tuning
./backup-medium.sh              # Comprehensive backup
./pregenerate-world-medium.sh   # Larger world pre-gen
```

### Troubleshooting by Instance Type

**Small Instance Issues (2GB):**
- **Out of Memory**: Reduce Minecraft memory allocation to 512MB
- **Slow Performance**: Lower view-distance to 4-6, reduce max-players to 3-5
- **Disk Full**: Clean Docker logs: `docker system prune -f`
- **High CPU**: Pre-generate world, reduce simulation-distance to 4-6

**Medium Instance Issues (4GB):**
- **Out of Memory**: Check if multiple servers are running, reduce memory allocation
- **Slow Performance**: Lower view-distance to 6-8, check player count
- **High CPU**: Pre-generate larger world, optimize multiple servers
- **Network Issues**: Check if too many servers are running simultaneously