# Use the official PHP 8.4 FPM Alpine image (smaller footprint)
FROM php:8.4-fpm-alpine

# Get UID/GID from build arguments (default to 1000 if not provided)
ARG UID=1000
ARG GID=1000

WORKDIR /var/www/html

# Install build dependencies (removed after compilation) and runtime dependencies
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        postgresql-dev \
        libzip-dev \
        oniguruma-dev \
        libxml2-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        imagemagick-dev \
        linux-headers \
        shadow \
    && apk add --no-cache \
        curl \
        unzip \
        git \
        libpq \
        libzip \
        oniguruma \
        libxml2 \
        libpng \
        libjpeg-turbo \
        freetype \
        imagemagick \
        imagemagick-libs \
        nodejs \
        npm \
        jpegoptim \
        optipng \
        pngquant \
        gifsicle \
        libwebp-tools \
        libavif-apps \
        icu-libs \
        icu-dev \
    # Modify www-data user/group to match host UID/GID
    && existing_group=$(getent group ${GID} | cut -d: -f1) \
    && if [ -n "$existing_group" ] && [ "$existing_group" != "www-data" ]; then \
        delgroup $existing_group || true; \
    fi \
    && groupmod -g ${GID} www-data \
    && existing_user=$(getent passwd ${UID} | cut -d: -f1) \
    && if [ -n "$existing_user" ] && [ "$existing_user" != "www-data" ]; then \
        deluser $existing_user || true; \
    fi \
    && usermod -u ${UID} -g ${GID} www-data \
    # Configure and install PHP extensions
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
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
        opcache \
    # Install PECL extensions
    && pecl install redis imagick \
    && docker-php-ext-enable redis imagick \
    # Remove build dependencies
    && apk del .build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

# Install npm global packages
RUN npm install -g svgo && npm cache clean --force

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Ensure www-data owns Composer and working directory
RUN chown -R www-data:www-data /usr/local/bin/composer /var/www

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/dev-server.ini

# Switch to www-data user
USER www-data

EXPOSE 9000

CMD ["php-fpm"]