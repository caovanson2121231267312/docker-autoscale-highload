#!/bin/bash

BACKUP_DIR="/var/backups/laravel"
MYSQL_CONTAINER="laravel_mysql"
DB_NAME="laravel"
RETENTION_DAYS=7

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database
BACKUP_FILE="$BACKUP_DIR/db-backup-$(date +%Y%m%d-%H%M%S).sql.gz"

docker exec $MYSQL_CONTAINER sh -c \
    "mysqldump -u root -p\$(cat /run/secrets/mysql_root_password) $DB_NAME" | \
    gzip > "$BACKUP_FILE"

# Backup Redis
docker exec laravel_redis redis-cli -a $(cat secrets/redis_password.txt) \
    --rdb /data/backup.rdb BGSAVE

# Remove old backups
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Upload to S3 (optional)
# aws s3 cp "$BACKUP_FILE" s3://your-bucket/backups/

echo "Backup completed: $BACKUP_FILE"