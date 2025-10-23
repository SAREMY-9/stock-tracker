# Stage 1: Builder (Used for Composer)
FROM docker.io/library/composer:2 AS composer_stage

# Stage 2: Application (Base image for the running application)
FROM docker.io/library/php:8.3-apache AS base_stage

# Step 1: Enable Apache mod_rewrite
# (Corresponds to your original step #10)
RUN a2enmod rewrite

# ----------------------------------------------------------------------
# Step 2: Install System Dependencies (from original step #11)
# ----------------------------------------------------------------------
# Update packages, install necessary libraries, and clean up apt cache 
# to keep the layer size down.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        unzip \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        libzip-dev \
        zip \
        sqlite3 \
    # Cleanup to reduce image size
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------
# Step 3: Install PHP Extensions (from original step #11)
# ----------------------------------------------------------------------
# Split the extensions into groups to pinpoint the one causing 'exit code 1'.
# The logs showed PDO passed, so the failure is likely one of the later ones.

# Core Extensions
RUN docker-php-ext-install pdo pdo_sqlite bcmath mbstring exif

# Remaining Extensions (Test this line carefully, one may be the culprit!)
# If the build fails here, try running each extension (pcntl, gd, zip) in 
# its own RUN command to find the exact problematic extension.
RUN docker-php-ext-install pcntl gd zip

# --- Remaining Dockerfile Steps (Placeholder) ---

# Copy Composer dependencies from the composer stage (e.g., if using a framework like Laravel)
# COPY --from=composer_stage /app/vendor /var/www/html/vendor

# Copy application code
# COPY . /var/www/html

# Set directory permissions if needed (e.g., for storage/cache)
# RUN chown -R www-data:www-data /var/www/html/storage
