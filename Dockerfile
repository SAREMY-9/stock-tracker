# Use official PHP image with FPM
FROM php:8.3-fpm

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    libonig-dev \
    libzip-dev \
    unzip \
    git \
    curl \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_sqlite bcmath mbstring exif zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application code
COPY . .

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 8080 and start PHP-FPM
EXPOSE 8080
CMD php artisan serve --host=0.0.0.0 --port=8080

