# Stage 1: Build the Laravel PHP-FPM application image
# Use an official PHP-FPM image with Alpine Linux for a lightweight and secure base.
# Laravel 12 typically requires PHP 8.2 or newer, so PHP 8.3 is a suitable choice.
FROM php:8.3-fpm-alpine

# Set the working directory inside the container to /var/www.
# All subsequent commands will be executed relative to this directory.
WORKDIR /usr/share

# Install system dependencies required for PHP extensions and general operation.
# The --no-cache flag reduces the final image size by not storing package lists.
# - curl: Used for downloading Composer.
# - libpng-dev, libjpeg-turbo-dev, freetype-dev: Development libraries for the GD extension (image manipulation).
# - icu-dev: Development library for the intl extension (internationalization support).
# - libxml2-dev: Development library for various XML-related PHP extensions.
# - zip, unzip: Required by Composer to handle archives.
# - oniguruma-dev: Development library for the mbstring extension (multibyte string functions).
# - mysql-client: Provides the MySQL client binaries, which are necessary for the pdo_mysql PHP extension.
# - git: Included as some Composer dependencies might rely on Git.
RUN apk add --no-cache \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    mysql-client \
    git \
    nodejs \
    npm

# Install and enable essential PHP extensions.
# docker-php-ext-install is a helper script provided by the PHP Docker images.
# - pdo_mysql: Enables PHP Data Objects (PDO) for MySQL database access.
# - mbstring: Provides multi-byte string functions, which are crucial for Laravel.
# - exif: Reads EXIF data from images.
# - pcntl: Process Control functions, useful for Artisan commands.
# - bcmath: Arbitrary precision mathematics, often used in financial calculations.
# - opcache: Improves PHP performance by storing precompiled script bytecode in shared memory.
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    opcache

# Configure and install the GD extension with FreeType and JPEG support.
# -j$(nproc) uses all available CPU cores for faster compilation.
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Clean up the APK cache to further reduce the final image size.
RUN rm -rf /usr/cache/apk/*

# Copy the Composer executable from the official Composer Docker image.
# This ensures we have a reliable and up-to-date Composer version.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /usr/share/nginx/html

# Copy the entire Laravel application from your local machine into the container's working directory.
# Ensure you run `docker build` from your Laravel project's root directory.
COPY . .

# Install PHP dependencies using Composer.
# - --no-dev: Skips the installation of development dependencies, making the production image smaller.
# - --optimize-autoloader: Optimizes Composer's autoloader for faster class loading in production.
# - --no-interaction: Runs Composer commands non-interactively.
RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && composer clear-cache

# Set appropriate permissions for Laravel's storage and bootstrap/cache directories.
# The `www-data` user and group are typically used by PHP-FPM inside the container.
# These directories require write permissions for Laravel to function correctly (e.g., logging, caching, session files).
RUN chown -R www-data:www-data storage \
    && chmod -R 775 storage \
    && mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache

# Generate the Laravel application key.
# IMPORTANT: For production deployments, it is highly recommended to set APP_KEY via environment variables
# (e.g., in your Azure App Service configuration, Kubernetes secrets, or Azure Key Vault)
# rather than baking it into the Docker image directly. This command is included for a basic setup.
RUN php artisan key:generate

# Optimize Laravel for production by caching configurations, routes, and views.
# - optimize:clear: Clears any previously cached files.
# - config:cache: Caches the application's configuration files.
# - route:cache: Caches the application's route definitions for faster routing.
# - view:cache: Caches the Blade views for improved rendering performance.
# RUN php artisan optimize:clear \
#     && php artisan config:cache \
#     && php artisan route:cache \
#     && php artisan view:cache

# Copy entrypoint
COPY ./php-fpm-entrypoint.sh /usr/local/bin/docker-php-entrypoint.sh
# Give permision
RUN chmod a+x /usr/local/bin/*

# Expose port 9000, which is the default listening port for PHP-FPM.
# This port will be used by the web server (like Nginx) to communicate with this PHP-FPM container.
EXPOSE 9000

ENTRYPOINT [ "/usr/local/bin/docker-php-entrypoint.sh" ]

# Define the command to run when the container starts.
# This starts the PHP-FPM process in the foreground.
CMD ["php-fpm"]
