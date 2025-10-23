# Use an official PHP + Apache image
FROM php:8.3-apache

# Enable Apache rewrite for Laravel routes
RUN a2enmod rewrite

# Install system packages and PHP extensions
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libonig-dev libxml2-dev libzip-dev zip sqlite3 \
    && docker-php-ext-install pdo pdo_sqlite bcmath mbstring exif pcntl gd zip

# Set working directory
WORKDIR /var/www/html

# Copy app files
COPY . .

# Copy Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy example environment file and generate key
RUN cp .env.example .env || true && php artisan key:generate --force

# Ensure SQLite database file exists and has correct permissions
RUN mkdir -p database && touch database/database.sqlite \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/database

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

