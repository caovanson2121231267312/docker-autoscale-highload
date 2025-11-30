#!/bin/bash

LOG_DIR="/var/www/laravel-production/logs"
RETENTION_DAYS=30

# Function to rotate logs
rotate_logs() {
    local dir=$1
    local pattern=$2
    
    find "$dir" -name "$pattern" -type f -mtime +$RETENTION_DAYS -delete
    find "$dir" -name "$pattern" -type f -size +100M -exec gzip {} \;
}

# Rotate Nginx logs
rotate_logs "$LOG_DIR/nginx" "*.log"

# Rotate PHP logs
rotate_logs "$LOG_DIR/php" "*.log"

# Rotate MySQL logs
rotate_logs "$LOG_DIR/mysql" "*.log"

# Compress old logs
find "$LOG_DIR" -name "*.log" -type f -mtime +7 -exec gzip {} \;

echo "Log rotation completed at $(date)"