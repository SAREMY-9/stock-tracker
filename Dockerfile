# Use a specific, stable PHP 8.3 FPM image (Debian 12 "bookworm" is recommended)
FROM php:8.3-fpm-bookworm

# Set working directory
WORKDIR /var/www/html

# ----------------------------------------------------------------------
# STEP 1: Install System Dependencies 💾
# ----------------------------------------------------------------------
# Install system packages and development libraries needed for PHP extensions.
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    libpng-dev \
    libjpeg-dev \
    # Cleanup apt cache immediately
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------
# STEP 2: Install PHP Extensions 🧩
# ----------------------------------------------------------------------
# Compile and install all necessary PHP extensions, including 'gd' for images.
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_sqlite \
    bcmath \
    mbstring \
    exif \
    zip \
    curl \
    xml \
    gd

# ----------------------------------------------------------------------
# STEP 3: Composer and Application Setup 📦
# ----------------------------------------------------------------------

# Install a specific, stable Composer version
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . /var/www/html

# CRITICAL FIX: Create the empty SQLite file and set permissions.
# This resolves the "Database file does not exist" error (HTTP 500).
RUN touch database/database.sqlite \
    && chown www-data:www-data database/database.sqlite

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# Set permissions (needed for Laravel storage and cache)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# ----------------------------------------------------------------------
# FINAL STAGE 🚀
# ----------------------------------------------------------------------

# Expose HTTP port
EXPOSE 8080

# Command to start the application (using Laravel built-in server for simplicity)
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]