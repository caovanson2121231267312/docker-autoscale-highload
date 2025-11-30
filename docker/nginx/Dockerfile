FROM nginx:1.25-alpine

LABEL maintainer="DevOps Team"
LABEL description="Production Nginx with security headers"

# Install additional tools
RUN apk add --no-cache curl

# Remove default config
RUN rm -f /etc/nginx/conf.d/default.conf

# Create log directory
RUN mkdir -p /var/log/nginx && chown -R nginx:nginx /var/log/nginx

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]