#!/bin/bash

DOCKER_COMPOSE_FILE="/var/www/laravel-production/docker-compose.yml"
WEBHOOK_URL="${SLACK_WEBHOOK_URL}"

# Check container health
check_containers() {
    local unhealthy=$(docker ps --filter health=unhealthy --format "{{.Names}}")
    
    if [ ! -z "$unhealthy" ]; then
        send_alert "⚠️ Unhealthy containers detected: $unhealthy"
        return 1
    fi
    return 0
}

# Check disk usage
check_disk() {
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ $usage -gt 85 ]; then
        send_alert "⚠️ Disk usage critical: ${usage}%"
        return 1
    fi
    return 0
}

# Check memory usage
check_memory() {
    local usage=$(free | grep Mem | awk '{print ($3/$2) * 100.0}' | cut -d'.' -f1)
    
    if [ $usage -gt 90 ]; then
        send_alert "⚠️ Memory usage high: ${usage}%"
        return 1
    fi
    return 0
}

# Send alert
send_alert() {
    local message=$1
    
    if [ ! -z "$WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$WEBHOOK_URL"
    fi
    
    echo "$message" | mail -s "Production Alert" admin@example.com
}

# Run checks
check_containers
check_disk
check_memory

echo "Monitoring check completed at $(date)"