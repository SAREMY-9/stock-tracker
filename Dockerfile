# ----------------------------------------------------------------------
# STAGE 0: Frontend Builder (Vite/Node.js) 🌐
# Builds the front-end assets (JS/CSS) and generates the manifest.json file.
# ----------------------------------------------------------------------
FROM node:20-alpine AS vite_builder

WORKDIR /app

# Copy package files (for caching)
COPY package.json package-lock.json ./

# Install Node dependencies
RUN npm install

# Copy application files needed for the build
COPY . .

# Run the Vite production build
RUN npm run build

# ----------------------------------------------------------------------
# STAGE 1: Composer Builder 🎼
# Downloads the Composer executable.
# ----------------------------------------------------------------------
FROM composer:2.7 AS composer_builder

# ----------------------------------------------------------------------
# FINAL STAGE: Application Runtime 🚀
# Combines all required components into the final, small image.
# ----------------------------------------------------------------------
FROM php:8.3-fpm-bookworm AS final_stage

# Set working directory
WORKDIR /var/www/html

## System Setup (Steps 1 & 2)

# Install system packages (libjpeg-dev for GD is included) and clean cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip curl libzip-dev libsqlite3-dev sqlite3 libonig-dev libxml2-dev \
    libcurl4-openssl-dev libssl-dev zlib1g-dev gnupg libpng-dev libjpeg-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install all necessary PHP extensions
RUN docker-php-ext-install \
    pdo pdo_mysql pdo_sqlite bcmath mbstring exif zip curl xml gd

## Application Copy and Initialization (Step 3)

# Copy Composer from builder stage
COPY --from=composer_builder /usr/bin/composer /usr/bin/composer

# Copy application files
COPY . /var/www/html

# CRITICAL FIX 1: Copy compiled frontend assets from the Vite stage
# This resolves the "Vite manifest not found" error.
COPY --from=vite_builder /app/public/build /var/www/html/public/build

# CRITICAL FIX 2: Create the empty SQLite file and set permissions.
# This prevents the initial "Database file does not exist" error.
RUN touch database/database.sqlite \
    && chown www-data:www-data database/database.sqlite

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# CRITICAL FIX 3: Run Migrations
# This prevents the "no such table: sessions" error.
RUN php artisan migrate --force

# Set final permissions for storage, cache, and the database file
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

## Final Runtime

# Expose HTTP port
EXPOSE 8080

ENV APP_ENV=production
ENV APP_DEBUG=false
ENV VITE_DEV_SERVER=false

# Command to start the application
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]

