# Use official PHP 8.3 FPM image
FROM php:8.3-fpm

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libsqlite3-dev \
    sqlite3 \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    zlib1g-dev \
    gnupg \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        pdo_sqlite \
        bcmath \
        mbstring \
        exif \
        zip \
        curl \
        xml \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . /var/www/html

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev

# Set permissions (needed for Laravel storage and cache)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose HTTP port
EXPOSE 8080

# Start Laravel built-in server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]

