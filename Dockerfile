# Use the official PHP 8.3 image with Apache as the base image
# This provides PHP with Apache web server pre-configured
FROM php:8.3-apache

# Set the working directory inside the container
# All subsequent commands will be executed from this directory
WORKDIR /var/www/html

# Install system dependencies required for Laravel and PHP extensions
# - libpng-dev, libjpeg62-turbo-dev, libfreetype6-dev: For image processing (GD extension)
# - libonig-dev: For mbstring extension (multibyte string handling)
# - libxml2-dev: For XML processing
# - libzip-dev: For ZIP file handling
# - zip, unzip: For Composer dependency management
# - curl: For HTTP requests
# - git: For version control and Composer dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    git \
    npm \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions required by Laravel
# - gd: For image processing (configure with freetype and jpeg support)
# - pdo_mysql: For MySQL database connections
# - mbstring: For multibyte string handling
# - exif: For reading image metadata
# - pcntl: For process control (used by Laravel queues)
# - bcmath: For arbitrary precision mathematics
# - zip: For ZIP file handling
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath zip

# Install Composer (PHP dependency manager)
# - Download the installer, verify it, install globally, then clean up
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite for Laravel's pretty URLs
# This allows .htaccess files to work properly for URL rewriting
RUN a2enmod rewrite headers

# Copy the custom Apache configuration
# This will set up the document root and other Apache settings
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf

# Copy the application code into the container
# The . refers to the current directory on the host machine
COPY . /var/www/html

# Set proper permissions for Laravel directories
# - www-data is the Apache user that needs to write to these directories
# - storage: For logs, cache, sessions, and uploaded files
# - bootstrap/cache: For compiled views and configuration cache
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Copy and make the entrypoint script executable
# This script will run initialization tasks when the container starts
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port 80 for HTTP traffic
# This allows external access to the web server
EXPOSE 80

# Set the entrypoint script to run when the container starts
# This will handle Laravel-specific initialization before starting Apache
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command to start Apache in the foreground
# apache2-foreground keeps the container running by not daemonizing Apache
CMD ["apache2-foreground"]