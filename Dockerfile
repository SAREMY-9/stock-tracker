# Use a specific, stable PHP 8.3 FPM image (Debian 12 "bookworm" is recommended)
FROM php:8.3-fpm-bookworm

# Set working directory
WORKDIR /var/www/html

# ----------------------------------------------------------------------
# STEP 1: Install System Dependencies 💾
# ----------------------------------------------------------------------
# Install necessary libraries and development headers.
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
# Compile and install all necessary PHP extensions.
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

# CRITICAL FIX 1: Create the empty SQLite file and set permissions.
# This prevents the initial "Database file does not exist" error.
RUN touch database/database.sqlite \
    && chown www-data:www-data database/database.sqlite

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# CRITICAL FIX 2: Run Migrations ⚙️
# This creates the 'sessions' table and all other required schema tables,
# preventing the "no such table: sessions" error.
RUN php artisan migrate --force

# Set permissions (needed for Laravel storage/cache and the database file)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# ----------------------------------------------------------------------
# FINAL STAGE 🚀
# ----------------------------------------------------------------------

# Expose HTTP port
EXPOSE 8080

# Command to start the application (using Laravel built-in server)
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]