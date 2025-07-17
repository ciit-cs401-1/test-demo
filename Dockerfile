# Use the official PHP image with Apache
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    curl \
    npm \
    nodejs \
    && docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd

# Install Composer globally
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www/html

# Copy project files (adjust the path if needed)
COPY . /var/www/html

# Set permissions for storage and bootstrap cache
RUN chown -R www-data:www-data /var/www/html \ 
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Expose port 80
EXPOSE 80

# Set environment variables if needed
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Update Apache config to serve Laravel from the public directory
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Install Laravel dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Install Node.js dependencies
RUN npm install && npm run build

# Copy .env.example to .env if .env does not exist (optional, for local dev)
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Start Apache in the foreground
CMD ["apache2-foreground"]