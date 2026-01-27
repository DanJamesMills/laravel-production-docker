# Use the official PHP 8.2 FPM image
FROM php:8.2-fpm

# Get UID/GID from build arguments (default to 1000 if not provided)
ARG UID=1000
ARG GID=1000

# CRITICAL FIX: Modify the existing 'www-data' user and group to match the host's UID/GID.
# This ensures that when the host volume is mounted, the www-data user (which runs PHP-FPM) 
# has correct read/write permissions on the files.
# Handle macOS where GID 20 (staff) already exists
RUN if getent group ${GID} > /dev/null 2>&1; then \
        # GID exists, add www-data to that group and change user's primary group
        usermod -u ${UID} www-data && \
        usermod -g ${GID} www-data; \
    else \
        # GID doesn't exist, create it normally
        usermod -u ${UID} www-data && \
        groupmod -g ${GID} www-data; \
    fi

# Set the working directory to the container mount point, /var/www/html
WORKDIR /var/www/html

# Install system dependencies and PHP extensions in optimized layers
# Layer 1: Install system packages only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    git \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
    zlib1g-dev \
    nodejs \
    npm \
    libmagickwand-dev \
    imagemagick \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    webp \
    libavif-bin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Layer 2: Install npm global packages separately for better caching
RUN npm install -g svgo

# Layer 3: Configure and install PHP extensions with parallel builds
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    mysqli \
    pdo_pgsql \
    mbstring \
    zip \
    exif \
    gd \
    bcmath \
    intl \
    pcntl \
    opcache

# Layer 4: Install PECL extensions
RUN pecl install redis imagick \
    && docker-php-ext-enable redis imagick

# Layer 5: Install Composer using official installer with verification
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Ensure the 'www-data' user owns Composer and the application code directory
RUN chown -R www-data:www-data /usr/local/bin/composer && \
    chown -R www-data:www-data /var/www

# Copy PHP configuration early for better layer caching
COPY php.ini /usr/local/etc/php/conf.d/dev-server.ini

# Switch to the 'www-data' user (now UID 1000)
USER www-data

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Start PHP-FPM server
CMD ["php-fpm"]