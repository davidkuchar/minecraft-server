# Instance Size Selection Guide

Choose the right instance size for your Minecraft server based on your needs and budget.

## Quick Decision Matrix

| Players | Budget | Instance Type | Monthly Cost | Configuration |
|---------|--------|---------------|--------------|---------------|
| 2-5     | Low    | 2GB (t2.small) | $15-22 | Small setup |
| 5-10    | Medium | 4GB (t3.medium) | $30-40 | Medium setup |
| 10-15   | Higher | 4GB (t3.medium) | $30-40 | Medium optimized |
| 15+     | Custom | Contact for scaling options | Varies | Multiple instances |

## Configuration Comparison

### Small Instance (2GB)
```bash
# Deployment commands
cp .env.small .env
cp docker-compose.small.yml docker-compose.yml
./setup-small.sh
```

**Specifications:**
- **Instance:** t2.small (1 vCPU, 2GB RAM)
- **Storage:** 12GB EBS
- **Minecraft Memory:** 512-768MB
- **View Distance:** 6 chunks
- **Max Players:** 5 (recommended: 2-3)
- **World Size:** 2000x2000 blocks

**Best For:**
- Friends and family server
- Casual gaming
- Testing and development
- Budget-conscious users

**Limitations:**
- Limited concurrent players
- Reduced view distance
- Single server only
- Basic performance

### Medium Instance (4GB)  
```bash
# Deployment commands
cp .env.medium .env
cp docker-compose.medium.yml docker-compose.yml
./setup-medium.sh
```

**Specifications:**
- **Instance:** t3.medium (2 vCPU, 4GB RAM)
- **Storage:** 20GB EBS
- **Minecraft Memory:** 1536-2048MB
- **View Distance:** 8-10 chunks
- **Max Players:** 15 (recommended: 5-10)
- **World Size:** 4000x4000 blocks

**Best For:**
- Small community servers
- Better performance requirements
- Multiple small servers
- Modded Minecraft (light mods)

**Advantages:**
- Higher view distances
- More concurrent players
- Can run 2-3 small servers
- Better CPU performance
- Command blocks enabled
- Enhanced monitoring tools

## Performance Expectations

### Small Instance Performance
- **Lag-free players:** 2-3
- **Acceptable performance:** 4-5
- **World generation:** Slower, pre-generate recommended
- **Backup time:** 2-5 minutes
- **Startup time:** 3-5 minutes

### Medium Instance Performance
- **Lag-free players:** 5-8
- **Acceptable performance:** 10-12
- **World generation:** Faster, larger worlds supported
- **Backup time:** 5-10 minutes
- **Startup time:** 2-4 minutes

## Cost Analysis

### Small Instance Annual Costs
- **On-Demand:** $180-264/year
- **Reserved (1-year):** $144-204/year
- **Spot Instances:** $60-96/year (unreliable)

### Medium Instance Annual Costs
- **On-Demand:** $336-444/year
- **Reserved (1-year):** $288-360/year
- **Spot Instances:** $120-180/year (unreliable)

## Migration Between Sizes

### Upgrading from Small to Medium
1. Create backup: `./backup-medium.sh`
2. Launch new medium instance
3. Transfer data and restore
4. Update DNS if using domain
5. Terminate small instance

### Downgrading from Medium to Small
1. Reduce server memory allocation
2. Lower view distances
3. Limit max players
4. Create backup
5. Deploy to small instance
6. May require world optimization

## Monitoring and Maintenance

### Small Instance Tools
```bash
./monitor-resources.sh          # Every 15 minutes
./optimize-performance.sh       # Run once after setup
./pregenerate-world.sh          # World optimization guide
```

### Medium Instance Tools
```bash
./monitor-resources-medium.sh   # Every 10 minutes  
./optimize-performance-medium.sh # Advanced optimizations
./backup-medium.sh              # Comprehensive backup
./pregenerate-world-medium.sh   # Larger world support
```

## Recommendations by Use Case

### Personal/Family Server (2-4 people)
- **Choose:** Small Instance (2GB)
- **Reason:** Cost-effective, sufficient performance
- **Setup:** Basic configuration with pre-generated world

### Friend Group Server (5-8 people)
- **Choose:** Medium Instance (4GB)  
- **Reason:** Better performance, room for growth
- **Setup:** Optimized configuration with monitoring

### Small Community (8-15 people)
- **Choose:** Medium Instance (4GB)
- **Reason:** Can handle peak usage, multiple servers possible
- **Setup:** Full optimization with backup strategy

### Large Community (15+ people)
- **Consider:** Multiple instances or dedicated hosting
- **Reason:** Single instance limitations
- **Setup:** Contact for custom scaling solutions

## Decision Checklist

Before choosing, consider:

- [ ] How many concurrent players do you expect?
- [ ] What's your monthly budget limit?
- [ ] Do you need multiple servers/worlds?
- [ ] Will you use mods or plugins?
- [ ] How important is performance vs. cost?
- [ ] Do you need advanced monitoring/backup?
- [ ] Is this temporary or long-term?

## Getting Started

1. **Start Small:** If unsure, begin with the 2GB instance
2. **Monitor Usage:** Use provided monitoring tools for 1-2 weeks
3. **Upgrade if Needed:** Migrate to 4GB if performance is insufficient
4. **Optimize:** Use performance scripts regardless of size chosen

Both configurations are production-ready and can be deployed immediately with the provided automation scripts.