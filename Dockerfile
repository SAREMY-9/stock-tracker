# Use the official PHP 8.3 image with Apache
FROM php:8.3-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql gd zip bcmath exif \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache modules required by Laravel
RUN a2enmod rewrite headers

# Set working directory
WORKDIR /var/www/html

# Copy project files to the container
COPY . /var/www/html

# Update Apache DocumentRoot to point to Laravel's "public" directory
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Add rewrite rules so Laravel routes work properly
RUN echo '<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf

# Copy Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Generate application key (safe if .env.example exists)
RUN cp .env.example .env || true && php artisan key:generate --force

# Set file permissions for storage and cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80 to Render
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]

