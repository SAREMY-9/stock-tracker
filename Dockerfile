# Use the official PHP 8.3 image with Apache
FROM php:8.3-apache

# Enable Apache mod_rewrite (required by Laravel)
RUN a2enmod rewrite

# Install system dependencies and PHP extensions (including zip)
RUN apt-get update && apt-get install -y \
    git zip unzip libpng-dev libonig-dev libxml2-dev sqlite3 libsqlite3-dev libzip-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite mbstring exif pcntl bcmath gd zip

# Set working directory inside the container
WORKDIR /var/www/html

# Copy the existing application code
COPY . /var/www/html

# Copy Composer from the Composer official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy Laravel environment example and generate key if needed
RUN cp .env.example .env || true && php artisan key:generate --force

# Set proper permissions for Laravel storage and cache directories
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80 for the web server
EXPOSE 80

# Start Apache when the container runs
CMD ["apache2-foreground"]

