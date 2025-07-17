#!/bin/bash

# Docker entrypoint script for Laravel application
# This script runs when the container starts and handles initialization tasks

# Enable strict error handling
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Function to log messages with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to wait for MySQL database to be ready
wait_for_db() {
    log "Waiting for database to be ready..."
    
    # Maximum number of attempts to connect to database
    max_attempts=30
    attempt=1
    
    # Keep trying to connect until successful or max attempts reached
    while [ $attempt -le $max_attempts ]; do
        # Use PHP to test database connection
        if php -r "
            try {
                \$pdo = new PDO(
                    'mysql:host=${DB_HOST};port=${DB_PORT}',
                    '${DB_USERNAME}',
                    '${DB_PASSWORD}',
                    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
                );
                echo 'Database connection successful';
                exit(0);
            } catch (Exception \$e) {
                exit(1);
            }
        " 2>/dev/null; then
            log "Database is ready!"
            break
        fi
        
        log "Database not ready yet (attempt $attempt/$max_attempts). Retrying in 2 seconds..."
        sleep 2
        ((attempt++))
    done
    
    # If we've exhausted all attempts, exit with error
    if [ $attempt -gt $max_attempts ]; then
        log "ERROR: Could not connect to database after $max_attempts attempts"
        exit 1
    fi
}

# Function to run Laravel-specific initialization
laravel_init() {
    log "Starting Laravel initialization..."
    
    # Wait for database to be ready
    wait_for_db
    
    # Generate application key if it doesn't exist
    if ! grep -q "APP_KEY=" .env || grep -q "APP_KEY=$" .env || grep -q "APP_KEY=base64:$" .env; then
        log "Generating application key..."
        php artisan key:generate --force
    else
        log "Application key already exists"
    fi
    
    # Clear and cache configuration for better performance
    log "Optimizing Laravel configuration..."
    php artisan config:clear
    php artisan config:cache
    
    # Clear and cache routes for better performance
    log "Optimizing Laravel routes..."
    php artisan route:clear
    php artisan route:cache
    
    # Clear and cache views for better performance
    log "Optimizing Laravel views..."
    php artisan view:clear
    php artisan view:cache
    
    # Run database migrations
    log "Running database migrations..."
    php artisan migrate --force
    
    # Seed the database (uncomment if you have seeders)
    log "Seeding database..."
    php artisan db:seed --force
    
    # Clear application cache
    log "Clearing application cache..."
    php artisan cache:clear
    
    # Create storage symlink if it doesn't exist
    if [ ! -L public/storage ]; then
        log "Creating storage symlink..."
        php artisan storage:link
    else
        log "Storage symlink already exists"
    fi
    
    # Set proper permissions for Laravel directories
    log "Setting proper permissions..."
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    chmod -R 775 /var/www/html/storage
    chmod -R 775 /var/www/html/bootstrap/cache
    
    # Start Laravel queue worker in the background if needed
    # Uncomment the lines below if you use Laravel queues
    # log "Starting Laravel queue worker..."
    # php artisan queue:work --daemon --quiet &
    
    log "Laravel initialization completed successfully!"
}

# Function to check if .env file exists
check_env_file() {
    if [ ! -f .env ]; then
        log "WARNING: .env file not found. Creating from .env.example..."
        if [ -f .env.example ]; then
            cp .env.example .env
            log ".env file created from .env.example"
        else
            log "ERROR: Neither .env nor .env.example found"
            exit 1
        fi
    fi
}

# Function to install/update NPM dependencies
npm_install() {
    log "Installing/updating NPM dependencies..."
    
    # Check if package.json exists
    if [ ! -f package.json ]; then
        log "ERROR: package.json not found"
        exit 1
    fi
    
    # Install dependencies
    npm install
    npm run build
    
    log "NPM dependencies installed successfully"
}

# Function to install/update Composer dependencies
composer_install() {
    log "Installing/updating Composer dependencies..."
    
    # Check if composer.json exists
    if [ ! -f composer.json ]; then
        log "ERROR: composer.json not found"
        exit 1
    fi
    
    # Install dependencies
    composer install --optimize-autoloader --no-interaction
    
    log "Composer dependencies installed successfully"
}

# Function to handle graceful shutdown
cleanup() {
    log "Received shutdown signal. Performing cleanup..."
    
    # Kill any background processes
    jobs -p | xargs -r kill
    
    # Additional cleanup tasks can be added here
    
    log "Cleanup completed"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Main execution starts here
log "Starting Laravel application container..."

# Check if .env file exists
check_env_file

# Install/update Composer dependencies
composer_install

# Install/update Composer dependencies
npm_install

# Run Laravel initialization
laravel_init

# Start cron service if needed (uncomment if you use Laravel scheduled tasks)
# log "Starting cron service..."
# service cron start

log "Container initialization completed. Starting Apache..."

# Execute the main command (Apache in this case)
# This keeps the container running and serves the Laravel application
exec "$@"