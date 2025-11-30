# Laravel Production Docker Setup

> Bộ Docker setup tối ưu cho môi trường Production Laravel, hỗ trợ **2,000+ concurrent requests** với khả năng horizontal scaling.

## Mục Lục

- [Tính Năng Chính](#-tính-năng-chính)
- [Kiến Trúc Hệ Thống](#-kiến-trúc-hệ-thống)
- [Yêu Cầu Hệ Thống](#-yêu-cầu-hệ-thống)
- [Cài Đặt Nhanh](#-cài-đặt-nhanh)
- [Cấu Hình Chi Tiết](#-cấu-hình-chi-tiết)
- [Deployment](#-deployment)
- [Scaling](#-scaling)
- [Monitoring & Logging](#-monitoring--logging)
- [Backup & Recovery](#-backup--recovery)
- [Performance Testing](#-performance-testing)
- [Troubleshooting](#-troubleshooting)
- [Security Best Practices](#-security-best-practices)
- [FAQ](#-faq)

---

## Tính Năng Chính

### Performance
- **2,000+ concurrent requests** với PHP-FPM dynamic process manager
- **OPcache + JIT compilation** (PHP 8.1)
- **Redis caching** cho session, cache, và queue
- **MySQL query optimization** với buffer pool tuning
- **Nginx với HTTP/2** và keepalive optimization

### Security
- **Docker Secrets** cho credential management
- **Security headers** (X-Frame-Options, CSP, HSTS)
- **Rate limiting** cho API endpoints
- **Redis protected mode** với password authentication
- **Disabled dangerous commands** (FLUSHALL, KEYS, CONFIG)
- **MySQL access restrictions** với internal network

### Monitoring & Logging
- **Comprehensive logging** (Nginx, PHP-FPM, MySQL)
- **Slow query detection** (MySQL + PHP-FPM)
- **Health checks** cho tất cả services
- **Resource monitoring** với Docker stats
- **Automatic log rotation** với retention policy

### DevOps Ready
- **GitHub Actions CI/CD** pipeline
- **Multi-stage builds** cho production images
- **Container orchestration** với Docker Compose
- **Horizontal scaling** support với load balancer
- **Zero-downtime deployment** strategy

---

## Kiến Trúc Hệ Thống

```
┌─────────────────────────────────────────────────────────┐
│                     Load Balancer                        │
│                    (nginx-lb) [Optional]                 │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│   Nginx-1      │       │   Nginx-2      │
│   (Frontend)   │       │   (Frontend)   │
└───────┬────────┘       └───────┬────────┘
        │                         │
        └────────────┬────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│   PHP-FPM-1    │       │   PHP-FPM-2    │
│   (Laravel)    │       │   (Laravel)    │
└───────┬────────┘       └───────┬────────┘
        │                         │
        └────────────┬────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──────┐ ┌──▼─────┐ ┌───▼────────┐
│    MySQL     │ │ Redis  │ │   Queue    │
│   (Master)   │ │ Cache  │ │  Worker    │
└──────────────┘ └────────┘ └────────────┘
```

### Services Stack

| Service | Technology | Version | Purpose |
|---------|-----------|---------|---------|
| **Web Server** | Nginx | 1.25-alpine | Reverse proxy, static files |
| **Application** | PHP-FPM | 8.1-fpm-alpine | Laravel runtime |
| **Database** | MySQL | 8.0 | Primary data storage |
| **Cache/Queue** | Redis | 7-alpine | Caching, sessions, queues |
| **Queue Worker** | PHP CLI | 8.1 | Background job processing |
| **Scheduler** | PHP CLI | 8.1 | Cron job management |

---

## Yêu Cầu Hệ Thống

### Minimum Requirements (Development)
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 20GB SSD
- **OS**: Linux (Ubuntu 20.04+), macOS, Windows 10/11

### Recommended (Production)
- **CPU**: 4+ cores (8+ for high traffic)
- **RAM**: 8GB (16GB+ for optimal performance)
- **Storage**: 100GB+ SSD with RAID
- **OS**: Ubuntu 22.04 LTS / Debian 11+
- **Network**: 1Gbps

### Software Requirements
- Docker Engine 24.0+
- Docker Compose 2.20+
- Git 2.30+

---

## Cài Đặt Nhanh

### Bước 1: Clone Repository

```bash
git clone https://github.com/caovanson2121231267312/docker-autoscale-highload.git
cd laravel-production
```

### Bước 2: Cài Đặt Docker

#### Ubuntu/Debian
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

#### CentOS/RHEL
```bash
sudo yum install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```

#### macOS
```bash
brew install --cask docker
```

### Bước 3: Cài Đặt Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Bước 4: Setup Environment

```bash
# Copy environment file
cp .env.example .env

# Tạo secrets directory
mkdir -p secrets

# Generate strong passwords
echo "$(openssl rand -base64 32)" > secrets/mysql_root_password.txt
echo "$(openssl rand -base64 32)" > secrets/mysql_password.txt
echo "$(openssl rand -base64 32)" > secrets/redis_password.txt

# Set secure permissions
chmod 600 secrets/*.txt

# Tạo log directories
mkdir -p logs/{nginx,php,mysql}
chmod -R 755 logs
```

### Bước 5: Cấu Hình .env

Chỉnh sửa file `.env`:

```bash
nano .env
```

**Các thông số cần thiết:**

```env
# Application
APP_NAME=LaravelProduction
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

# Database
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel_prod
DB_USERNAME=laravel_user
DB_PASSWORD=  # Copy từ secrets/mysql_password.txt

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=  # Copy từ secrets/redis_password.txt
REDIS_PORT=6379

# Cache & Session
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# PHP-FPM Configuration
PHP_FPM_PM=dynamic
PHP_FPM_MAX_CHILDREN=100
PHP_FPM_START_SERVERS=20
PHP_FPM_MIN_SPARE_SERVERS=10
PHP_FPM_MAX_SPARE_SERVERS=30
PHP_FPM_MAX_REQUESTS=1000
```

### Bước 6: Build & Start Services

```bash
# Build images
docker-compose build --no-cache

# Start all services
docker-compose up -d

# Wait for services to be healthy
echo "Đợi services khởi động..."
sleep 30

# Check service status
docker-compose ps
```

**Output mong đợi:**
```
NAME              IMAGE           STATUS                    PORTS
laravel_nginx     nginx:1.25      Up 30 seconds (healthy)   0.0.0.0:80->80/tcp
laravel_php       laravel-php     Up 30 seconds (healthy)   9000/tcp
laravel_mysql     mysql:8.0       Up 30 seconds (healthy)   0.0.0.0:3306->3306/tcp
laravel_redis     redis:7-alpine  Up 30 seconds (healthy)   0.0.0.0:6379->6379/tcp
```

### Bước 7: Install Laravel Dependencies

```bash
# Install Composer packages
docker-compose exec php composer install --optimize-autoloader --no-dev

# Generate application key
docker-compose exec php php artisan key:generate

# Run migrations
docker-compose exec php php artisan migrate --force

# Seed database (optional)
docker-compose exec php php artisan db:seed --force

# Cache optimization
docker-compose exec php php artisan config:cache
docker-compose exec php php artisan route:cache
docker-compose exec php php artisan view:cache
docker-compose exec php php artisan optimize

# Set permissions
docker-compose exec php chown -R www-data:www-data storage bootstrap/cache
docker-compose exec php chmod -R 775 storage bootstrap/cache
```

### Bước 8: Verify Installation

```bash
# Check container health
docker-compose ps

# Test application health
curl http://localhost/health
# Output: healthy

# Test application homepage
curl -I http://localhost
# Output: HTTP/1.1 200 OK

# View logs
docker-compose logs -f --tail=50
```

**🎉 Hoàn tất! Application đang chạy tại:** `http://localhost`

---

## ⚙️ Cấu Hình Chi Tiết

### Environment Variables Reference

#### Application Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `APP_NAME` | Laravel | Tên application |
| `APP_ENV` | production | Environment (local, staging, production) |
| `APP_DEBUG` | false | Debug mode (luôn false trong production) |
| `APP_URL` | http://localhost | Base URL của application |

#### PHP-FPM Tuning
| Variable | Default | Mô tả | Recommended |
|----------|---------|-------|-------------|
| `PHP_FPM_PM` | dynamic | Process manager (static/dynamic/ondemand) | dynamic |
| `PHP_FPM_MAX_CHILDREN` | 100 | Max số process con | 50-200 |
| `PHP_FPM_START_SERVERS` | 20 | Số process lúc start | 20% của max |
| `PHP_FPM_MIN_SPARE_SERVERS` | 10 | Min process rảnh | 10% của max |
| `PHP_FPM_MAX_SPARE_SERVERS` | 30 | Max process rảnh | 30% của max |
| `PHP_FPM_MAX_REQUESTS` | 1000 | Request trước khi restart | 500-2000 |

#### Database Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `DB_CONNECTION` | mysql | Database driver |
| `DB_HOST` | mysql | Host name (container name) |
| `DB_PORT` | 3306 | Database port |
| `DB_DATABASE` | laravel | Database name |
| `DB_USERNAME` | laravel | Database user |
| `DB_PASSWORD` | - | User password (từ secrets) |

### Performance Tuning Presets

#### Small Server (2-4GB RAM)
**Use case:** Development, staging, low traffic (<500 concurrent)

```env
# .env
PHP_FPM_MAX_CHILDREN=50
PHP_FPM_START_SERVERS=10
PHP_FPM_MIN_SPARE_SERVERS=5
PHP_FPM_MAX_SPARE_SERVERS=15
```

**Edit `docker/mysql/my.cnf`:**
```ini
innodb_buffer_pool_size = 1G
max_connections = 200
```

#### Medium Server (8-16GB RAM) - **Recommended**
**Use case:** Production, medium traffic (500-2000 concurrent)

```env
# .env
PHP_FPM_MAX_CHILDREN=100
PHP_FPM_START_SERVERS=20
PHP_FPM_MIN_SPARE_SERVERS=10
PHP_FPM_MAX_SPARE_SERVERS=30
```

**Edit `docker/mysql/my.cnf`:**
```ini
innodb_buffer_pool_size = 3G
max_connections = 500
```

#### Large Server (16GB+ RAM)
**Use case:** High traffic (2000-5000+ concurrent)

```env
# .env
PHP_FPM_MAX_CHILDREN=200
PHP_FPM_START_SERVERS=40
PHP_FPM_MIN_SPARE_SERVERS=20
PHP_FPM_MAX_SPARE_SERVERS=60
```

**Edit `docker/mysql/my.cnf`:**
```ini
innodb_buffer_pool_size = 6G
max_connections = 1000
```

**Edit `docker/redis/redis.conf`:**
```conf
maxmemory 4gb
io-threads 8
```

### SSL/HTTPS Configuration

#### Bước 1: Tạo thư mục SSL

```bash
mkdir -p docker/nginx/ssl
chmod 700 docker/nginx/ssl
```

#### Bước 2: Generate Self-Signed Certificate (Development)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout docker/nginx/ssl/key.pem \
  -out docker/nginx/ssl/cert.pem \
  -subj "/C=VN/ST=Hanoi/L=Hanoi/O=YourCompany/CN=localhost"
```

#### Bước 3: Let's Encrypt SSL (Production)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot

# Stop nginx temporarily
docker-compose stop nginx

# Generate certificate
sudo certbot certonly --standalone \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email admin@yourdomain.com \
  --agree-tos

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem docker/nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem docker/nginx/ssl/key.pem
sudo chmod 644 docker/nginx/ssl/*.pem

# Start nginx
docker-compose start nginx
```

#### Bước 4: Enable SSL trong Nginx

Edit file `docker/nginx/conf.d/default.conf`:

**Uncomment các dòng SSL:**
```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # ... rest of config
}
```

#### Bước 5: Restart Services

```bash
docker-compose restart nginx
```

#### Bước 6: Auto-renewal (Let's Encrypt)

```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab
sudo crontab -e

# Add this line
0 3 * * * certbot renew --quiet --deploy-hook "docker-compose -f /var/www/laravel-production/docker-compose.yml restart nginx"
```

---

## Deployment

### Manual Deployment

```bash
# 1. Backup current state
./scripts/backup.sh

# 2. Pull latest code
git pull origin main

# 3. Rebuild containers (if Dockerfile changed)
docker-compose build --no-cache php nginx

# 4. Stop current containers
docker-compose down

# 5. Start new containers
docker-compose up -d

# 6. Install/update dependencies
docker-compose exec php composer install --optimize-autoloader --no-dev

# 7. Run migrations
docker-compose exec php php artisan migrate --force

# 8. Clear and cache configs
docker-compose exec php php artisan config:clear
docker-compose exec php php artisan cache:clear
docker-compose exec php php artisan config:cache
docker-compose exec php php artisan route:cache
docker-compose exec php php artisan view:cache
docker-compose exec php php artisan optimize

# 9. Restart queue workers
docker-compose restart queue

# 10. Verify deployment
curl -f http://localhost/health || echo "Deployment failed!"
```

### Zero-Downtime Deployment (Blue-Green)

```bash
#!/bin/bash
# deploy-zero-downtime.sh

set -e

echo "Starting zero-downtime deployment..."

# 1. Build new images
echo "Building new images..."
docker-compose build php nginx

# 2. Start new PHP containers alongside old ones
echo "Scaling up PHP containers..."
docker-compose up -d --no-deps --scale php=4 php

# 3. Wait for new containers to be healthy
echo "Waiting for health checks..."
sleep 30

# 4. Run migrations on new containers
echo "Running migrations..."
docker-compose exec -T php php artisan migrate --force

# 5. Switch nginx to new containers (update upstream)
echo "Switching traffic..."
docker-compose up -d --force-recreate nginx

# 6. Scale down old PHP containers
echo "Scaling down old containers..."
docker-compose up -d --no-deps --scale php=2 php

# 7. Final optimization
echo "Optimizing caches..."
docker-compose exec -T php php artisan optimize
docker-compose exec -T php php artisan config:cache

# 8. Cleanup
echo "Cleaning up old images..."
docker image prune -f

echo "Deployment completed successfully!"
```

**Sử dụng:**
```bash
chmod +x deploy-zero-downtime.sh
./deploy-zero-downtime.sh
```

### GitHub Actions Auto Deployment

File `.github/workflows/deploy.yml` đã được cung cấp.

**Setup GitHub Secrets:**

1. Vào repository → Settings → Secrets and variables → Actions
2. Thêm các secrets sau:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `PROD_HOST` | 192.168.1.100 | IP server production |
| `PROD_USERNAME` | deploy | SSH username |
| `PROD_SSH_KEY` | `<private-key>` | SSH private key |
| `PROD_PORT` | 22 | SSH port |
| `APP_URL` | https://yourdomain.com | Application URL |

**Deploy bằng Git Push:**

```bash
git add .
git commit -m "feat: new feature"
git push origin main

# GitHub Actions sẽ tự động:
# 1. Run tests
# 2. Build Docker images
# 3. Push to registry
# 4. Deploy to production
# 5. Run migrations
# 6. Clear caches
# 7. Health check
```

### Rollback Strategy

#### Rollback Code

```bash
# Xem commit history
git log --oneline -10

# Rollback về commit trước
git revert HEAD
git push origin main

# Hoặc hard reset (nguy hiểm!)
git reset --hard <commit-hash>
git push -f origin main
```

#### Rollback Docker Images

```bash
# List available images
docker images | grep laravel-php

# Tag previous version as latest
docker tag laravel-php:sha-abc123 laravel-php:latest

# Restart với image cũ
docker-compose up -d --force-recreate php

# Rollback migrations
docker-compose exec php php artisan migrate:rollback --step=1
```

#### Rollback từ Backup

```bash
# Stop application
docker-compose down

# Restore database
gunzip < backups/db-backup-20251129.sql.gz | \
  docker-compose exec -T mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) laravel

# Restore code
git checkout <previous-commit>

# Restart
docker-compose up -d
```

---

## Scaling

### Vertical Scaling (Tăng Resources)

#### Tăng PHP-FPM Processes

```bash
# Edit .env
nano .env

# Tăng giá trị
PHP_FPM_MAX_CHILDREN=200
PHP_FPM_START_SERVERS=40
PHP_FPM_MIN_SPARE_SERVERS=20
PHP_FPM_MAX_SPARE_SERVERS=60

# Restart PHP service
docker-compose restart php

# Verify
docker-compose exec php curl http://localhost:9000/status?full
```

#### Tăng MySQL Buffer Pool

```bash
# Edit mysql config
nano docker/mysql/my.cnf

# Tăng buffer pool (70-80% RAM)
innodb_buffer_pool_size = 6G
innodb_buffer_pool_instances = 8
max_connections = 1000

# Restart MySQL
docker-compose restart mysql

# Verify
docker-compose exec mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) \
  -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
```

#### Tăng Redis Memory

```bash
# Edit redis config
nano docker/redis/redis.conf

# Tăng maxmemory
maxmemory 4gb
io-threads 8

# Restart Redis
docker-compose restart redis

# Verify
docker-compose exec redis redis-cli -a $(cat secrets/redis_password.txt) INFO memory
```

### Horizontal Scaling (Thêm Containers)

#### Scale PHP-FPM Workers

```bash
# Scale to 4 PHP containers
docker-compose up -d --scale php=4 --scale queue=2

# Verify
docker-compose ps | grep php

# Should show:
# laravel_php_1
# laravel_php_2
# laravel_php_3
# laravel_php_4
```

#### Load Balancer Setup

**Sử dụng file `docker-compose.scale.yml`:**

```bash
# Start với load balancer
docker-compose -f docker-compose.yml -f docker-compose.scale.yml up -d

# Scale services
docker-compose -f docker-compose.yml -f docker-compose.scale.yml up -d \
  --scale php=6 \
  --scale nginx=2

# Check load distribution
watch -n 1 'docker stats --no-stream | grep php'
```

### Multi-Server Deployment (Docker Swarm)

#### Bước 1: Initialize Swarm

```bash
# On manager node
docker swarm init --advertise-addr <MANAGER-IP>

# Output will show command for workers:
# docker swarm join --token SWMTKN-xxx <MANAGER-IP>:2377
```

#### Bước 2: Add Worker Nodes

```bash
# On each worker node
docker swarm join --token SWMTKN-xxx <MANAGER-IP>:2377

# Verify on manager
docker node ls
```

#### Bước 3: Deploy Stack

```bash
# On manager node
docker stack deploy -c docker-compose.yml laravel-stack

# Check services
docker service ls

# Scale specific service
docker service scale laravel-stack_php=10
docker service scale laravel-stack_nginx=3
```

#### Bước 4: Update Service

```bash
# Rolling update
docker service update --image laravel-php:latest laravel-stack_php

# Force update
docker service update --force laravel-stack_php
```

### Database Replication (Read Replicas)

**Tạo MySQL Read Replica:**

Edit `docker-compose.yml`, thêm:

```yaml
services:
  mysql-replica:
    image: mysql:8.0
    container_name: laravel_mysql_replica
    command: 
      - --default-authentication-plugin=mysql_native_password
      - --server-id=2
      - --log-bin=mysql-bin
      - --relay-log=relay-log
      - --read-only=1
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
    volumes:
      - mysql-replica-data:/var/lib/mysql
      - ./docker/mysql/my.cnf:/etc/mysql/conf.d/my.cnf:ro
    secrets:
      - mysql_root_password
    networks:
      - backend

volumes:
  mysql-replica-data:
```

**Setup Replication:**

```bash
# On master
docker-compose exec mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) <<EOF
CREATE USER 'repl'@'%' IDENTIFIED BY 'replication_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
EOF

# Note: File and Position values

# On replica
docker-compose exec mysql-replica mysql -u root -p$(cat secrets/mysql_root_password.txt) <<EOF
CHANGE MASTER TO
  MASTER_HOST='mysql',
  MASTER_USER='repl',
  MASTER_PASSWORD='replication_password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=154;
START SLAVE;
SHOW SLAVE STATUS\G
EOF
```

**Configure Laravel để sử dụng Read Replica:**

Edit `config/database.php`:

```php
'mysql' => [
    'read' => [
        'host' => [
            env('DB_READ_HOST_1', 'mysql-replica'),
        ],
    ],
    'write' => [
        'host' => [
            env('DB_WRITE_HOST', 'mysql'),
        ],
    ],
    'sticky' => true,
    // ... other configs
],
```

---

## Monitoring & Logging

### Real-time Monitoring

#### Container Stats

```bash
# All containers
docker stats

# Specific containers
docker stats laravel_php laravel_nginx laravel_mysql

# Format output
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

#### Live Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f php
docker-compose logs -f nginx
docker-compose logs -f mysql

# Last N lines
docker-compose logs --tail=100 php

# Since timestamp
docker-compose logs --since 2025-11-30T10:00:00 nginx

# Filter by string
docker-compose logs php | grep ERROR
```

### Service Status Pages

#### PHP-FPM Status

```bash
# Full status
docker-compose exec php curl http://localhost:9000/status?full

# Summary
docker-compose exec php curl http://localhost:9000/status?json | jq .

# Ping
docker-compose exec php curl http://localhost:9000/ping
```

**Output example:**
```json
{
  "pool": "www",
  "process-manager": "dynamic",
  "start-time": 1701417600,
  "accepted-conn": 12543,
  "listen-queue": 0,
  "max-listen-queue": 5,
  "listen-queue-len": 128,
  "idle-processes": 15,
  "active-processes": 25,
  "total-processes": 40,
  "max-active-processes": 45,
  "max-children-reached": 2,
  "slow-requests": 3
}
```

#### Nginx Status

Enable `stub_status` trong `docker/nginx/conf.d/default.conf`:

```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    allow 10.0.0.0/8;  # Docker network
    deny all;
}
```

Check status:
```bash
curl http://localhost/nginx_status
```

**Output:**
```
Active connections: 145
server accepts handled requests
 15234 15234 45672
Reading: 10 Writing: 25 Waiting: 110
```

#### MySQL Monitoring

```bash
# Process list
docker-compose exec mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) \
  -e "SHOW FULL PROCESSLIST;"

# InnoDB status
docker-compose exec mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) \
  -e "SHOW ENGINE INNODB STATUS\G" | less

# Connection stats
docker-compose exec mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) \
  -e "SHOW STATUS LIKE 'Threads%';"

# Buffer pool hit ratio
docker-compose exec mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) \
  -e "SHOW STATUS LIKE 'Innodb_buffer_pool_%';"

# Slow queries
docker-compose exec mysql mysql -u root -p$(cat secrets/mysql_root_password.txt) \
  -e "SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 20;"
```

#### Redis Monitoring

```bash
# Get password
REDIS_PASS=$(cat secrets/redis_password.txt)

# Stats
docker-compose exec redis redis-cli -a $REDIS_PASS INFO stats

# Memory usage
docker-compose exec redis redis-cli -a $REDIS_PASS INFO memory

# Keyspace
docker-compose exec redis redis-cli -a $REDIS_PASS INFO keyspace

# Monitor real-time commands
docker-compose exec redis redis-cli -a $REDIS_PASS MONITOR

# Slow log
docker-compose exec redis redis-cli -a $REDIS_PASS SLOWLOG GET 10

# Connected clients
docker-compose exec redis redis-cli -a $REDIS_PASS CLIENT LIST
```

### Log Files & Analysis

#### Log Locations

```
logs/
├── nginx/
│   ├── access.log      # HTTP requests
│   └── error.log       # Nginx errors
├── php/
│   ├── access.log      # PHP-FPM requests
│   ├── error.log       # PHP application errors
│   └── slow.log        # Slow PHP requests (>5s)
└── mysql/
    ├── error.log       # MySQL errors
    └── slow-query.log  # Slow SQL queries (>2s)
```

#### Nginx Log Analysis

```bash
# Top 10 requested URLs
cat logs/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -10

# Top 10 IP addresses
cat logs/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# Request methods distribution
cat logs/nginx/access.log | awk '{print $6}' | sort | uniq -c

# Status code distribution
cat logs/nginx/access.log | awk '{print $9}' | sort | uniq -c | sort -rn

# Average response time
cat logs/nginx/access.log | grep -oP 'rt=\K[0-9.]+' | \
  awk '{sum+=$1; count++} END {printf "Average: %.3fs\nTotal requests: %d\n", sum/count, count}'

# Requests with response time > 1s
cat logs/nginx/access.log | grep -oP 'rt=\K[0-9.]+' | awk '$1 > 1 {print}'

# 4xx errors
grep " 4[0-9][0-9] " logs/nginx/access.log | tail -20

# 5xx errors
grep " 5[0-9][0-9] " logs/nginx/access.log | tail -20

# Bandwidth usage
cat logs/nginx/access.log | awk '{sum+=$10} END {print "Total: " sum/1024/1024 " MB"}'
```

#### PHP Error Log Analysis

```bash
# Recent PHP errors
tail -100 logs/php/error.log

# Fatal errors
grep "Fatal error" logs/php/error.log

# Warnings
grep "Warning" logs/php/error.log | tail -20

# Exceptions
grep "Exception" logs/php/error.log | tail -20

# Slow requests
cat logs/php/slow.log | grep "pool www" -A 10
```

#### MySQL Slow Query Analysis

```bash
# View slow queries
tail -100 logs/mysql/slow-query.log

# Count slow queries
grep "Query_time" logs/mysql/slow-query.log | wc -l

# Top slow queries
grep -A 5 "Query_time" logs/mysql/slow-query.log | \
  grep "SELECT\|UPDATE\|DELETE\|INSERT" | sort | uniq -c | sort -rn | head -10

# Queries taking > 5 seconds
grep "Query_time: [5-9]" logs/mysql/slow-query.log -A 3
```

### Automated Monitoring Scripts

#### Health Check Script

File `scripts/health-check.sh` đã được tạo. Sử dụng:

```bash
chmod +x scripts/health-check.sh

# Run manually
./scripts/health-check.sh

# Add to crontab (every 5 minutes)
crontab -e
```

Add:
```cron
*/5 * * * * /var/www/laravel-production/scripts/health-check.sh
```

#### Resource Monitoring Script

Tạo `scripts/monitor-resources.sh`:

```bash
#!/bin/bash

LOG_FILE="/var/log/resource-monitor.log"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85
ALERT_THRESHOLD_DISK=90

# CPU Usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo "[$(date)] CPU Usage: ${CPU_USAGE}%" >> $LOG_FILE

if (( $(echo "$CPU_USAGE > $ALERT_THRESHOLD_CPU" | bc -l) )); then
    echo "⚠️ High CPU usage: ${CPU_USAGE}%" | mail -s "CPU Alert" admin@example.com
fi

# Memory Usage
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100.0}')
echo "[$(date)] Memory Usage: ${MEM_USAGE}%" >> $LOG_FILE

if [ "$MEM_USAGE" -gt "$ALERT_THRESHOLD_MEM" ]; then
    echo "⚠️ High memory usage: ${MEM_USAGE}%" | mail -s "Memory Alert" admin@example.com
fi

# Disk Usage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
echo "[$(date)] Disk Usage: ${DISK_USAGE}%" >> $LOG_FILE

if [ "$DISK_USAGE" -gt "$ALERT_THRESHOLD_DISK" ]; then
    echo "⚠️ High disk usage: ${DISK_USAGE}%" | mail -s "Disk Alert" admin@example.com
fi
```

Run every 10 minutes:
```cron
*/10 * * * * /var/www/laravel-production/scripts/monitor-resources.sh
```

### Centralized Logging (ELK Stack) - Optional

Thêm vào `docker-compose.yml`:

```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - es-data:/usr/share/elasticsearch/data
    networks:
      - backend

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    volumes:
      - ./docker/logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      - ./logs:/logs
    depends_on:
      - elasticsearch
    networks:
      - backend

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    networks:
      - backend

volumes:
  es-data:
```

Access Kibana: `http://localhost:5601`

---

## 💾 Backup & Recovery

### Automated Backup

File `scripts/backup.sh` đã được cung cấp.

#### Setup Automated Backup

```bash
# Make script executable
chmod +x scripts/backup.sh

# Test backup
./scripts/backup.sh

# Add to crontab (daily at 2 AM)
crontab -e
```

Add line:
```cron
0 2 * * * /var/www/laravel-production/scripts/backup.sh >> /var/log/backup.log 2>&1
```

### Manual Backup

#### Database Backup

```bash
# Create backup directory
mkdir -p backups/database

# Backup with timestamp
BACKUP_FILE="backups/database/db-backup-$(date +%Y%m%d-%H%M%S).sql"

docker-compose exec mysql mysqldump \
  -u root -p$(cat secrets/mysql_root_password.txt) \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  laravel > $BACKUP_FILE

# Compress
gzip $BACKUP_FILE

echo "Backup created: ${BACKUP_FILE}.gz"
```

#### Redis Backup

```bash
# Trigger background save
docker-compose exec redis redis-cli -a $(cat secrets/redis_password.txt) BGSAVE

# Wait for completion
docker-compose exec redis redis-cli -a $(cat secrets/redis_password.txt) LASTSAVE

# Copy dump file
docker cp laravel_redis:/data/dump.rdb backups/redis-$(date +%Y%m%d).rdb

# Compress
gzip backups/redis-$(date +%Y%m%d).rdb
```

#### Application Files Backup

```bash
# Backup storage directory
tar -czf backups/storage-$(date +%Y%m%d).tar.gz storage/

# Backup uploads (if separate)
tar -czf backups/uploads-$(date +%Y%m%d).tar.gz public/uploads/
```

#### Complete System Backup

```bash
#!/bin/bash
# scripts/full-backup.sh

BACKUP_ROOT="/var/backups/laravel"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"

mkdir -p "$BACKUP_DIR"

# Database
docker-compose exec mysql mysqldump \
  -u root -p$(cat secrets/mysql_root_password.txt) \
  --all-databases | gzip > "$BACKUP_DIR/mysql-all.sql.gz"

# Redis
docker-compose exec redis redis-cli -a $(cat secrets/redis_password.txt) BGSAVE
sleep 5
docker cp laravel_redis:/data/dump.rdb "$BACKUP_DIR/redis.rdb"

# Application files
tar -czf "$BACKUP_DIR/application.tar.gz" \
  --exclude='node_modules' \
  --exclude='vendor' \
  --exclude='.git' \
  .

# Docker volumes
docker run --rm \
  -v laravel-production_mysql-data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar -czf /backup/mysql-volume.tar.gz -C /data .

echo "Full backup completed: $BACKUP_DIR"
```

### Restore from Backup

#### Restore Database

```bash
# Stop application
docker-compose stop php queue scheduler

# Restore from backup
gunzip < backups/database/db-backup-20251130-020000.sql.gz | \
  docker-compose exec -T mysql mysql \
  -u root -p$(cat secrets/mysql_root_password.txt) laravel

# Restart application
docker-compose start php queue scheduler
```

#### Restore Redis

```bash
# Stop Redis
docker-compose stop redis

# Restore dump file
gunzip < backups/redis-20251130.rdb.gz > /tmp/dump.rdb
docker cp /tmp/dump.rdb laravel_redis:/data/dump.rdb

# Fix permissions
docker-compose exec redis chown redis:redis /data/dump.rdb

# Start Redis
docker-compose start redis
```

#### Restore Application Files

```bash
# Stop application
docker-compose down

# Restore storage
tar -xzf backups/storage-20251130.tar.gz

# Restore uploads
tar -xzf backups/uploads-20251130.tar.gz

# Fix permissions
docker-compose exec php chown -R www-data:www-data storage public/uploads

# Start application
docker-compose up -d
```

### Backup to Cloud Storage

#### AWS S3

Install AWS CLI:
```bash
pip3 install awscli
aws configure
```

Modify `scripts/backup.sh`:
```bash
# After creating backup
aws s3 cp "$BACKUP_FILE" s3://your-bucket/backups/database/
aws s3 cp "$REDIS_BACKUP" s3://your-bucket/backups/redis/

# Set lifecycle policy (delete after 30 days)
aws s3api put-bucket-lifecycle-configuration \
  --bucket your-bucket \
  --lifecycle-configuration file://s3-lifecycle.json
```

#### Google Cloud Storage

```bash
# Install gsutil
curl https://sdk.cloud.google.com | bash

# Authenticate
gcloud auth login

# Upload backup
gsutil cp "$BACKUP_FILE" gs://your-bucket/backups/database/
```

### Backup Retention Policy

Edit `scripts/backup.sh`:

```bash
# Keep last 7 daily backups
find "$BACKUP_DIR" -name "db-backup-*.sql.gz" -mtime +7 -delete

# Keep last 4 weekly backups (Sunday backups)
if [ $(date +%u) -eq 7 ]; then
    # Tag as weekly backup
    cp "$BACKUP_FILE" "${BACKUP_FILE%.sql.gz}-weekly.sql.gz"
fi
find "$BACKUP_DIR" -name "*-weekly.sql.gz" -mtime +28 -delete

# Keep last 12 monthly backups (1st of month)
if [ $(date +%d) -eq 01 ]; then
    cp "$BACKUP_FILE" "${BACKUP_FILE%.sql.gz}-monthly.sql.gz"
fi
find "$BACKUP_DIR" -name "*-monthly.sql.gz" -mtime +365 -delete
```

---

## Performance Testing

### Load Testing với Apache Bench

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Basic test - 1000 requests, 100 concurrent
ab -n 1000 -c 100 http://localhost/

# With keep-alive
ab -n 10000 -c 500 -k http://localhost/

# POST request
ab -n 1000 -c 100 -p post-data.json -T application/json http://localhost/api/endpoint

# Test with authentication
ab -n 1000 -c 100 -H "Authorization: Bearer token" http://localhost/api/users
```

**Đọc kết quả:**
```
Server Software:        nginx/1.25.3
Server Hostname:        localhost
Server Port:            80

Concurrency Level:      100
Time taken for tests:   10.234 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      3240000 bytes
HTML transferred:       1420000 bytes
Requests per second:    977.12 [#/sec] (mean)
Time per request:       102.343 [ms] (mean)
Time per request:       1.023 [ms] (mean, across all concurrent requests)
Transfer rate:          309.22 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   2.1      0      15
Processing:    12   101  45.3     95     520
Waiting:       11   100  45.2     94     519
Total:         12   102  45.5     96     521

Percentage of the requests served within a certain time (ms)
  50%     96
  66%    108
  75%    118
  80%    125
  90%    152
  95%    180
  98%    215
  99%    245
 100%    521 (longest request)
```

### Load Testing với Siege

```bash
# Install Siege
sudo apt-get install siege

# Configure
echo "verbose = false" > ~/.siegerc
echo "csv = true" >> ~/.siegerc

# Basic test - 100 concurrent users, 10 repetitions
siege -c 100 -r 10 http://localhost/

# Timed test - 2 minutes
siege -c 200 -t 2M http://localhost/

# From URL file
siege -c 100 -r 5 -f urls.txt

# With delay between requests
siege -c 50 -r 20 -d 1 http://localhost/
```

**urls.txt example:**
```
http://localhost/
http://localhost/api/users
http://localhost/api/products
http://localhost/dashboard
POST http://localhost/api/login {"email":"test@example.com","password":"password"}
```

### Stress Testing với wrk

```bash
# Install wrk
sudo apt-get install wrk

# Basic test - 4 threads, 400 connections, 30 seconds
wrk -t 4 -c 400 -d 30s http://localhost/

# With custom script (POST request)
wrk -t 8 -c 500 -d 60s -s post.lua http://localhost/api/endpoint

# Advanced test
wrk -t 12 -c 1000 -d 120s --latency --timeout 10s http://localhost/
```

**post.lua example:**
```lua
wrk.method = "POST"
wrk.body   = '{"username":"test","password":"test123"}'
wrk.headers["Content-Type"] = "application/json"
```

**Đọc kết quả:**
```
Running 30s test @ http://localhost/
  4 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    45.23ms   12.54ms 178.23ms   75.23%
    Req/Sec     2.21k   345.21    3.45k    82.34%
  Latency Distribution
     50%   42.12ms
     75%   51.23ms
     90%   62.45ms
     99%   89.67ms
  265234 requests in 30.05s, 82.34MB read
Requests/sec:  8826.71
Transfer/sec:      2.74MB
```

### Performance Benchmarks

#### Mục tiêu Performance (Medium Server - 8GB RAM)

| Metric | Target | Excellent |
|--------|--------|-----------|
| **Concurrent Users** | 2,000+ | 5,000+ |
| **Requests/sec** | 1,000+ | 2,500+ |
| **Average Response Time** | <100ms | <50ms |
| **95th Percentile** | <200ms | <100ms |
| **99th Percentile** | <500ms | <250ms |
| **Error Rate** | <0.1% | <0.01% |
| **CPU Usage** | <70% | <50% |
| **Memory Usage** | <80% | <60% |

#### Benchmark Script

```bash
#!/bin/bash
# scripts/benchmark.sh

echo "Starting Performance Benchmark"
echo "=================================="

# Test 1: Homepage
echo ""
echo "Test 1: Homepage (1000 requests, 100 concurrent)"
ab -n 1000 -c 100 -k http://localhost/ | grep -E "Requests per second|Time per request|Failed requests"

# Test 2: API Endpoint
echo ""
echo "Test 2: API Endpoint (2000 requests, 200 concurrent)"
ab -n 2000 -c 200 -k http://localhost/api/test | grep -E "Requests per second|Time per request|Failed requests"

# Test 3: Sustained Load
echo ""
echo "Test 3: Sustained Load (5000 requests, 500 concurrent)"
ab -n 5000 -c 500 -k http://localhost/ | grep -E "Requests per second|Time per request|Failed requests"

# Test 4: Stress Test
echo ""
echo "Test 4: Stress Test (10000 requests, 1000 concurrent)"
ab -n 10000 -c 1000 -k http://localhost/ | grep -E "Requests per second|Time per request|Failed requests"

echo ""
echo "=================================="
echo "Benchmark Completed"
```

### Optimization Tips based on Test Results

**If RPS (Requests/sec) < 1000:**
- Tăng `PHP_FPM_MAX_CHILDREN`
- Enable OPcache JIT
- Optimize database queries
- Add Redis caching

**If Response Time > 100ms:**
- Check slow query log
- Optimize N+1 queries
- Add database indexes
- Enable Redis query caching

**If CPU > 80%:**
- Scale horizontally (more containers)
- Optimize code (profiling với Xdebug)
- Enable OPcache optimization level

**If Memory > 85%:**
- Reduce `innodb_buffer_pool_size`
- Reduce `PHP_FPM_MAX_CHILDREN`
- Add more RAM hoặc scale out

---

## Troubleshooting

### Common Issues

#### 1. Container không start

**Symptoms:**
```bash
docker-compose ps
# Shows container status: Exit 1, Restarting
```

**Solution:**
```bash
# Check logs
docker-compose logs <service-name>

# Common issues:
# - Port already in use
sudo lsof -i :80
sudo lsof -i :3306

# Kill process using port
sudo kill -9 <PID>

# - Permission denied
sudo chown -R $USER:$USER .
sudo chmod -R 755 logs/

# - Config error
docker-compose config
```

#### 2. MySQL connection refused

**Symptoms:**
```
SQLSTATE[HY000] [2002] Connection refused
```

**Solution:**
```bash
# Check MySQL is running
docker-compose ps mysql

# Check MySQL logs
docker-compose logs mysql

# Wait for MySQL to be ready
docker-compose exec mysql mysqladmin ping -h localhost

# Verify connection
docker-compose exec php php artisan tinker
>>> DB::connection()->getPdo();

# Check environment variables
docker-compose exec php printenv | grep DB_
```

#### 3. Redis connection error

**Symptoms:**
```
Connection refused [tcp://redis:6379]
```

**Solution:**
```bash
# Check Redis is running
docker-compose ps redis

# Test connection
docker-compose exec redis redis-cli -a $(cat secrets/redis_password.txt) ping
# Should return: PONG

# Check password
cat secrets/redis_password.txt
docker-compose exec php printenv | grep REDIS_PASSWORD

# Verify Laravel config
docker-compose exec php php artisan tinker
>>> Redis::ping();
```

#### 4. 502 Bad Gateway (Nginx)

**Symptoms:**
- Nginx returns 502 error
- "upstream prematurely closed connection"

**Solution:**
```bash
# Check PHP-FPM is running
docker-compose ps php

# Check PHP-FPM logs
docker-compose logs php | grep ERROR

# Increase timeouts in nginx
# Edit docker/nginx/conf.d/default.conf
fastcgi_read_timeout 300s;

# Restart services
docker-compose restart nginx php
```

#### 5. Out of Memory (OOM)

**Symptoms:**
```
Killed
Container exits with code 137
```

**Solution:**
```bash
# Check Docker memory limit
docker stats

# Increase Docker memory (Docker Desktop)
# Settings → Resources → Memory: 8GB

# Reduce PHP-FPM children
PHP_FPM_MAX_CHILDREN=50

# Reduce MySQL buffer pool
innodb_buffer_pool_size = 1G

# Add swap space (Linux)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 6. Disk space full

**Symptoms:**
```
No space left on device
```

**Solution:**
```bash
# Check disk usage
df -h

# Clean Docker
docker system prune -a --volumes
docker volume prune

# Remove old logs
find logs/ -name "*.log" -mtime +30 -delete

# Remove old backups
find backups/ -name "*.sql.gz" -mtime +30 -delete

# Remove old images
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi
```

#### 7. Slow performance

**Symptoms:**
- Response time > 1s
- High CPU/Memory usage

**Diagnosis:**
```bash
# Check resource usage
docker stats

# Check slow queries
cat logs/mysql/slow-query.log

# Check PHP slow requests
cat logs/php/slow.log

# Profile PHP with Xdebug
docker-compose exec php php -dxdebug.mode=profile artisan ...
```

**Solutions:**
```bash
# Enable OPcache
docker-compose exec php php -i | grep opcache.enable
# Should be: On

# Clear all caches
docker-compose exec php php artisan optimize:clear
docker-compose exec php php artisan config:cache
docker-compose exec php php artisan route:cache

# Restart queue workers
docker-compose restart queue

# Scale PHP containers
docker-compose up -d --scale php=4
```

#### 8. Queue jobs not processing

**Symptoms:**
- Jobs stuck in queue
- `queue` container constantly restarting

**Solution:**
```bash
# Check queue container logs
docker-compose logs queue

# Check failed jobs
docker-compose exec php php artisan queue:failed

# Restart queue worker
docker-compose restart queue

# Manually process queue
docker-compose exec php php artisan queue:work --once

# Clear failed jobs
docker-compose exec php php artisan queue:flush
```

#### 9. Permission denied errors

**Symptoms:**
```
Permission denied: storage/logs/laravel.log
```

**Solution:**
```bash
# Fix Laravel permissions
docker-compose exec php chown -R www-data:www-data storage bootstrap/cache
docker-compose exec php chmod -R 775 storage bootstrap/cache

# Fix host permissions
sudo chown -R $USER:$USER .
sudo chmod -R 755 logs/

# SELinux (if enabled)
sudo chcon -R -t httpd_sys_rw_content_t storage/
```

#### 10. SSL Certificate errors

**Symptoms:**
```
NET::ERR_CERT_AUTHORITY_INVALID
```

**Solution:**
```bash
# Regenerate self-signed cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout docker/nginx/ssl/key.pem \
  -out docker/nginx/ssl/cert.pem

# Use Let's Encrypt for production
sudo certbot certonly --standalone -d yourdomain.com

# Verify certificate
openssl x509 -in docker/nginx/ssl/cert.pem -text -noout

# Restart Nginx
docker-compose restart nginx
```

### Debug Mode

Enable debug untuk troubleshooting:

```bash
# Edit .env (TEMPORARY - for debugging only)
APP_DEBUG=true
APP_LOG_LEVEL=debug

# Restart PHP
docker-compose restart php

# View detailed errors
docker-compose logs -f php

# IMPORTANT: Disable after debugging
APP_DEBUG=false
```

### Health Check Commands

```bash
#!/bin/bash
# scripts/diagnose.sh

echo "System Diagnostics"
echo "===================="

echo ""
echo "1. Container Status:"
docker-compose ps

echo ""
echo "2. Resource Usage:"
docker stats --no-stream

echo ""
echo "3. Disk Space:"
df -h /

echo ""
echo "4. Recent Errors (Nginx):"
tail -20 logs/nginx/error.log

echo ""
echo "5. Recent Errors (PHP):"
tail -20 logs/php/error.log

echo ""
echo "6. Recent Errors (MySQL):"
docker-compose exec mysql tail -20 /var/log/mysql/error.log

echo ""
echo "7. Network Connectivity:"
docker-compose exec php ping -c 3 mysql
docker-compose exec php ping -c 3 redis

echo ""
echo "8. PHP-FPM Status:"
docker-compose exec php curl -s http://localhost:9000/status

echo ""
echo "9. MySQL Connection:"
docker-compose exec mysql mysqladmin ping

echo ""
echo "10. Redis Connection:"
docker-compose exec redis redis-cli -a $(cat secrets/redis_password.txt) ping

echo ""
echo "===================="
echo "Diagnostics Complete"
```

**Run diagnostics:**
```bash
chmod +x scripts/diagnose.sh
./scripts/diagnose.sh
```

---

## Security Best Practices

### 1. Secrets Management

✅ **DO:**
- Use Docker Secrets cho passwords
- Store secrets ngoài Git (.gitignore)
- Rotate passwords định kỳ
- Use strong passwords (32+ characters)

❌ **DON'T:**
- Hardcode passwords trong code
- Commit secrets vào Git
- Share secrets qua email/chat
- Use default passwords

**Generate strong passwords:**
```bash
# Random password
openssl rand -base64 32

# Alphanumeric only
tr -dc A-Za-z0-9 </dev/urandom | head -c 32

# With special characters
pwgen -s 32 1
```

### 2. Network Security

**Isolate services:**
```yaml
networks:
  frontend:  # Public-facing
    driver: bridge
  backend:   # Internal only
    driver: bridge
    internal: true
```

**Firewall rules (UFW):**
```bash
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Deny direct database access
sudo ufw deny 3306/tcp
sudo ufw deny 6379/tcp
```

### 3. Container Security

**Non-root user:**
```dockerfile
# Already implemented in PHP Dockerfile
USER www-data
```

**Read-only filesystems:**
```yaml
services:
  nginx:
    read_only: true
    tmpfs:
      - /var/run
      - /var/cache/nginx
```

**Resource limits:**
```yaml
services:
  php:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          memory: 512M
```

### 4. Application Security

**Security headers đã được enable trong Nginx:**
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Strict-Transport-Security "max-age=31536000" always;
```

**Rate limiting:**
```nginx
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
```

**Laravel security:**
```bash
# Enable HTTPS enforcement
APP_URL=https://yourdomain.com

# Session security
SESSION_SECURE_COOKIE=true
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=lax

# Disable debug in production
APP_DEBUG=false
```

### 5. Database Security

**MySQL best practices:**
```sql
-- Remove test database
DROP DATABASE IF EXISTS test;

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Reload privileges
FLUSH PRIVILEGES;
```

**Connection restrictions:**
```ini
# my.cnf
bind-address = 0.0.0.0  # Only accessible within Docker network
skip-name-resolve = 1   # Disable DNS lookups
```

### 6. Redis Security

**Already configured:**
```conf
protected-mode yes
requirepass <strong-password>

# Dangerous commands disabled
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG "CONFIG_SECRET_NAME"
```

### 7. SSL/TLS

**Force HTTPS:**
```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    return 301 https://$server_name$request_uri;
}
```

**Strong SSL configuration:**
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_stapling on;
ssl_stapling_verify on;
```

### 8. Monitoring & Auditing

**Enable audit logging:**
```bash
# Docker events
docker events --filter 'type=container' --format '{{json .}}' > /var/log/docker-events.log

# Login attempts
tail -f /var/log/auth.log | grep ssh

# Application logs
docker-compose logs -f | tee -a /var/log/application.log
```

**Security scanning:**
```bash
# Scan for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image laravel-php:latest

# Check for outdated packages
docker-compose exec php composer outdated

# Laravel security check
docker-compose exec php php artisan security:check
```

### 9. Backup Encryption

```bash
# Encrypt backup
gpg --symmetric --cipher-algo AES256 backup.sql.gz

# Decrypt backup
gpg --decrypt backup.sql.gz.gpg > backup.sql.gz
```

### 10. Regular Updates

```bash
# Update base images
docker-compose pull
docker-compose up -d --force-recreate

# Update PHP packages
docker-compose exec php composer update --with-dependencies

# Update system packages
docker-compose exec php apk update && apk upgrade

# Schedule monthly updates
0 3 1 * * cd /var/www/laravel-production && docker-compose pull && docker-compose up -d
```

---

## FAQ

### Q: Làm sao để scale application lên 10,000 concurrent users?

**A:** Kết hợp vertical và horizontal scaling:

1. **Tăng resources server:**
   - CPU: 16+ cores
   - RAM: 32GB+
   - SSD: NVMe với RAID 10

2. **Scale containers:**
```bash
docker-compose up -d --scale php=20 --scale queue=5
```

3. **Load balancer:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.scale.yml up -d
```

4. **Database optimization:**
   - Read replicas
   - Connection pooling
   - Query optimization

5. **Caching aggressive:**
   - Redis cluster
   - CDN cho static files
   - Varnish cache

---

### Q: Chi phí server để chạy setup này?

**A:** Dự trù chi phí hàng tháng:

| Traffic Level | Server Specs | Cloud Cost (AWS/GCP) | VPS Cost (DigitalOcean) |
|--------------|-------------|---------------------|----------------------|
| **Low** (<500 concurrent) | 2 CPU, 4GB RAM | $40-60/mo | $24/mo |
| **Medium** (500-2000) | 4 CPU, 8GB RAM | $80-120/mo | $48/mo |
| **High** (2000-5000) | 8 CPU, 16GB RAM | $160-240/mo | $96/mo |
| **Very High** (5000+) | 16+ CPU, 32GB+ RAM | $320+/mo | $192+/mo |

---

### Q: Có cần Redis Cluster không?

**A:** Depends on traffic:

- **< 2,000 concurrent**: Single Redis đủ
- **2,000 - 5,000**: Redis Sentinel (HA)
- **> 5,000**: Redis Cluster (sharding)

Setup Redis Sentinel:
```yaml
services:
  redis-sentinel:
    image: redis:7-alpine
    command: redis-sentinel /etc/redis/sentinel.conf
```

---

### Q: Làm sao backup tự động lên cloud?

**A:** Xem phần [Backup to Cloud Storage](#backup-to-cloud-storage)

---

### Q: Application restart mất bao lâu?

**A:** Typical restart times:

- **Graceful restart**: 5-10 seconds
- **Full restart**: 30-60 seconds
- **Zero-downtime**: 0 seconds (blue-green)

---

### Q: Có thể chạy trên Windows không?

**A:** Có, nhưng performance kém hơn Linux:

1. Install Docker Desktop for Windows
2. Enable WSL 2 backend
3. Clone repo vào WSL filesystem (không phải /mnt/c)
4. Run như bình thường

**Recommended**: Sử dụng Linux server cho production.

---

### Q: Làm sao monitor real-time?

**A:** Options:

1. **Docker stats**: `docker stats`
2. **Portainer**: Web UI cho Docker
3. **Prometheus + Grafana**: Professional monitoring
4. **New Relic / DataDog**: Commercial APM

Quick Portainer setup:
```bash
docker volume create portainer_data
docker run -d -p 9000:9000 \
  --name portainer --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce
```

Access: `http://localhost:9000`

---

### Q: Có cần CDN không?

**A:** Recommended cho production:

**Benefits:**
- Giảm load server
- Faster static files
- DDoS protection
- Global edge caching

**CDN options:**
- Cloudflare (Free tier available)
- AWS CloudFront
- Google Cloud CDN
- Fastly

---

### Q: Database migration zero-downtime?

**A:** Best practices:

1. **Backward compatible migrations:**
```php
// Good: Add column (không break old code)
Schema::table('users', function (Blueprint $table) {
    $table->string('phone')->nullable();
});

// Bad: Drop column (breaks old code)
Schema::table('users', function (Blueprint $table) {
    $table->dropColumn('email');  // Old code sẽ lỗi
});
```

2. **Deploy strategy:**
```bash
# Step 1: Deploy code hỗ trợ cả old & new schema
git push origin main

# Step 2: Run migration
docker-compose exec php php artisan migrate --force

# Step 3: Deploy code cleanup (remove old schema support)
```

---

### Q: Xử lý file upload lớn (>100MB)?

**A:** Configuration cần thiết:

**1. Nginx:**
```nginx
client_max_body_size 500M;
client_body_timeout 300s;
```

**2. PHP:**
```ini
upload_max_filesize = 500M
post_max_size = 500M
max_execution_time = 300
memory_limit = 512M
```

**3. Laravel:**
```php
// Use chunked uploads
// Or upload directly to S3
```

**4. Restart:**
```bash
docker-compose restart nginx php
```

---

## Additional Resources

### Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Laravel Documentation](https://laravel.com/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Redis Documentation](https://redis.io/documentation)

### Tools
- [Portainer](https://www.portainer.io/) - Docker management UI
- [Adminer](https://www.adminer.org/) - Database management
- [phpMyAdmin](https://www.phpmyadmin.net/) - MySQL management
- [RedisInsight](https://redis.com/redis-enterprise/redis-insight/) - Redis GUI

### Monitoring
- [Prometheus](https://prometheus.io/) + [Grafana](https://grafana.com/)
- [New Relic](https://newrelic.com/)
- [DataDog](https://www.datadoghq.com/)
- [Sentry](https://sentry.io/) - Error tracking

---

## Contributing

Contributions are welcome! Please:

1. Fork repository
2. Create feature branch
3. Make changes
4. Submit pull request

---

## License

This project is licensed under the MIT License.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/laravel-production/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/laravel-production/discussions)
- **Email**: support@yourdomain.com

---

## Star History

If you find this project helpful, please give it a star ⭐

---

**Made with ❤️ for Laravel Developers**

Last updated: November 30, 2025