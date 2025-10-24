# ----------------------------------------------------------------------
# STAGE 0: Frontend Builder (Vite/Node.js) 🌐
# ----------------------------------------------------------------------
FROM node:20-alpine AS vite_builder

WORKDIR /app

# Copy package files (Use package-lock.json or yarn.lock if present)
COPY package.json package-lock.json ./

# Install Node dependencies
RUN npm install

# Copy application files needed for the build
COPY . .

# Run the Vite production build
# This creates the public/build/manifest.json file
RUN npm run build

# ----------------------------------------------------------------------
# STAGE 1: Composer Builder 🎼
# ----------------------------------------------------------------------
# We use a separate stage just to fetch the Composer executable
FROM composer:2.7 AS composer_builder

# ----------------------------------------------------------------------
# FINAL STAGE: Application Runtime 🚀
# ----------------------------------------------------------------------
# Use a specific, stable PHP 8.3 FPM image
FROM php:8.3-fpm-bookworm AS final_stage

# Set working directory
WORKDIR /var/www/html

## System Setup (Step 1 & 2)
# Install system packages (libjpeg-dev for GD is included) and PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip curl libzip-dev libsqlite3-dev sqlite3 libonig-dev libxml2-dev \
    libcurl4-openssl-dev libssl-dev zlib1g-dev gnupg libpng-dev libjpeg-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install \
        pdo pdo_mysql pdo_sqlite bcmath mbstring exif zip curl xml gd

## Application Copy and Initialization (Step 3)

# Copy Composer from builder stage
COPY --from=composer_builder /usr/bin/composer /usr/bin/composer

# Copy application files
COPY . /var/www/html

# CRITICAL FIX 1: Copy compiled frontend assets from the Vite stage
# This resolves the "Vite manifest not found" error.
COPY --from=vite_builder /app/public/build /var/www/html/public/build
# Manifest is sometimes created directly in public, copy it just in case
COPY --from=vite_builder /app/public/manifest.json /var/www/html/public/manifest.json

# CRITICAL FIX 2: Create the empty SQLite file and set permissions.
# This prevents the initial "Database file does not exist" error.
RUN touch database/database.sqlite \
    && chown www-data:www-data database/database.sqlite

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# CRITICAL FIX 3: Run Migrations
# This creates the 'sessions' table and all other required schema tables,
# preventing the "no such table: sessions" error.
RUN php artisan migrate --force

# Set final permissions (for storage, cache, and the database file)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

## Final Runtime

# Expose HTTP port
EXPOSE 8080

# Command to start the application
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]