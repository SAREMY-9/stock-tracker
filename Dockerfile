# Use a specific, stable PHP 8.3 FPM image (Debian 12 "bookworm" is recommended)
FROM php:8.3-fpm-bookworm

# Set working directory
WORKDIR /var/www/html

# ----------------------------------------------------------------------
# STEP 1: Install System Dependencies 💾
# ----------------------------------------------------------------------
# We install all necessary libraries first. Added libjpeg-dev for GD.
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
# STEP 2: Install PHP Extensions (Extensions are now separated for stability) 🧩
# ----------------------------------------------------------------------
# The gd extension is included here, which is essential for Laravel image handling.
# If the build fails, the error is in this block.
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

# Install a specific, stable Composer version (2.7 is current at the time of this advice)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . /var/www/html

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# Set permissions (needed for Laravel storage and cache)
# Note: Using 775 is generally better than 777.
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# ----------------------------------------------------------------------
# FINAL STAGE 🚀
# ----------------------------------------------------------------------

# Expose HTTP port
EXPOSE 8080

# The FPM image requires a separate web server (like Nginx), but for testing, 
# this command starts the built-in server.
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]