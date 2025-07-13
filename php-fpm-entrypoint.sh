#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
# This is crucial for debugging, as it will stop the container if any step fails,
# allowing 'docker-compose logs app' to show the exact error.
set -e

# This script is the custom entrypoint for the Laravel PHP-FPM container.
# It ensures the database is ready before running migrations and then starts PHP-FPM.

# Aggressively remove cached Laravel configuration and service provider files.
# This is crucial to prevent "Class not found" errors for dev-only packages
# when using 'composer install --no-dev', as Laravel might try to load
# non-existent classes from old cached configs during boot-up.
# echo "Removing Laravel cached config and service provider files..."
# rm -f /var/www/bootstrap/cache/config.php
# rm -f /var/www/bootstrap/cache/services.php
# rm -f /var/www/bootstrap/cache/packages.php
# rm -f /var/www/bootstrap/cache/routes-v7.php # For Laravel 12, routes are often cached here
# rm -f /var/www/bootstrap/cache/events.php # Also clear cached events

main() {
  prepare_file_permissions
  run_npm_build
  prepare_storage
  #wait_for_db
  run_migration
  optimize_app
  #run_server
}

prepare_file_permissions() {
  chmod a+x ./artisan
}

run_npm_build() {
  echo "Installing NPM dependencies"
  if [ -f "package.json" ]; then
    echo "Running NPM clean install"
    npm ci

    echo "Running NPM build"
    npm run build
  else
    echo "No package.json found, skipping NPM build"
  fi
}

prepare_storage() {
  # Create required directories for Laravel
  mkdir -p /usr/share/nginx/html/storage/framework/cache/data
  mkdir -p /usr/share/nginx/html/storage/framework/sessions
  mkdir -p /usr/share/nginx/html/storage/framework/views

  # Set permissions for the storage directory
  chown -R www-data:www-data /usr/share/nginx/html/storage
  chmod -R 775 /usr/share/nginx/html/storage

  # Ensure the symlink exists
  # php artisan storage:link
}

# Function to check if the database is available
# It tries to connect to the database using the 'db' host and '3306' port.
# The 'db' host is the service name defined in docker-compose.yml.
wait_for_db() {
  echo "Waiting for database to be ready..."
  # Loop until the database is reachable on the specified host and port.
  # 'nc' (netcat) is used to check if the port is open.
  # '-z' scans for listening daemons, '-w 1' timeout after 1 second.
  # ! (nc -z db 3306) |
  # ./artisan migrate:status 2>&1 | grep -q -E "(Migration table not found|Migration name)"
  while ! nc -z db 3306; do
    sleep 1 # Wait for 1 second before retrying
  done
  echo "Database is ready!"
}

# Run the wait function
# wait_for_db

optimize_app() {
  # Clear any remaining Laravel configuration and cache.
  # This is a good practice even after manual file deletion, ensuring consistency.
  echo "Running Laravel config:clear and cache:clear..."
  php artisan config:clear
  php artisan cache:clear
  echo "Running Laravel optimize..."
  php artisan optimize:clear
  php artisan optimize
}

run_migration() {
  # Run Laravel migrations
  # We use 'php artisan migrate --force' to run migrations without confirmation.
  # The --force flag is essential for non-interactive environments like Docker.
  # Ensure APP_KEY is set in your environment (e.g., in docker-compose.yml or Azure App Service).
  echo "Running database migrations..."
  php artisan migrate --force
}

# Run server
run_server() {
  exec /usr/local/bin/docker-php-entrypoint.sh "$@"
}

# You can also run seeders here if needed for initial data:
# echo "Running database seeders..."
# php artisan db:seed --force

# Execute the original command (php-fpm in this case)
# The 'exec "$@"' command replaces the current shell process with the command passed
# to the Docker container (which is 'php-fpm' from the Dockerfile's CMD).
# This is important for proper signal handling (e.g., stopping the container).
# exec "$@"
main "$@"