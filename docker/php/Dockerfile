ARG PHP_VERSION=8.1
FROM php:${PHP_VERSION}-fpm-alpine3.18

LABEL maintainer="DevOps Team"
LABEL description="Production-ready PHP-FPM with optimizations"

# Install system dependencies
RUN apk add --no-cache \
    curl \
    fcgi \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    postgresql-dev \
    linux-headers \
    $PHPIZE_DEPS

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        pdo_pgsql \
        mysqli \
        gd \
        zip \
        intl \
        opcache \
        pcntl \
        bcmath \
        exif

# Install Redis extension
RUN pecl install redis-6.0.2 \
    && docker-php-ext-enable redis

# Install APCu for additional caching
RUN pecl install apcu-5.1.22 \
    && docker-php-ext-enable apcu

# Clean up
RUN apk del $PHPIZE_DEPS \
    && rm -rf /tmp/* /var/cache/apk/*

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Create log directory
RUN mkdir -p /var/log/php && chown -R www-data:www-data /var/log/php

# Create healthcheck script
RUN echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck \
    && echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000' >> /usr/local/bin/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

# Set working directory
WORKDIR /var/www/html

# Switch to non-root user
USER www-data

EXPOSE 9000

CMD ["php-fpm"]