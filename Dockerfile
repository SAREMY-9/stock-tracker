# ----------------------------------------------------------------------
# STAGE 0: Frontend Builder (Vite/Node.js) 🌐
# ----------------------------------------------------------------------
FROM node:20-alpine AS vite_builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install Node dependencies
RUN npm install

# Copy application files needed for the build
COPY . .

# Run the Vite production build
RUN npm run build

# ----------------------------------------------------------------------
# STAGE 1: Backend Builder (Composer) 🎼
# ----------------------------------------------------------------------
FROM composer:2.7 AS composer_builder

# ----------------------------------------------------------------------
# FINAL STAGE: Application Runtime 🚀
# ----------------------------------------------------------------------
FROM php:8.3-fpm-bookworm

# Set working directory
WORKDIR /var/www/html

# STEP 1: Install System Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip curl libzip-dev libsqlite3-dev sqlite3 libonig-dev libxml2-dev \
    libcurl4-openssl-dev libssl-dev zlib1g-dev gnupg libpng-dev libjpeg-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# STEP 2: Install PHP Extensions
RUN docker-php-ext-install \
    pdo pdo_mysql pdo_sqlite bcmath mbstring exif zip curl xml gd

# STEP 3: Copy Files and Setup

# Copy Composer from builder stage
COPY --from=composer_builder /usr/bin/composer /usr/bin/composer

# Copy application files
COPY . /var/www/html

# CRITICAL FIX: Copy compiled frontend assets from the Vite stage
COPY --from=vite_builder /app/public/build /var/www/html/public/build
COPY --from=vite_builder /app/public/manifest.json /var/www/html/public/manifest.json

# CRITICAL FIX 1: Create the empty SQLite file and set permissions.
RUN touch database/database.sqlite \
    && chown www-data:www-data database/database.sqlite

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# CRITICAL FIX 2: Run Migrations
RUN php artisan migrate --force

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# FINAL STAGE
EXPOSE 8080
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]