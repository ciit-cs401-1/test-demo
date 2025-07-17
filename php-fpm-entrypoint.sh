#!/bin/sh
set -e

main() {
  prepare_file_permissions
  prepare_storage
  wait_for_db
  generate_app_key
  run_migration
  #run_seeder
  optimize_app
  #run_server "$@"
}

prepare_file_permissions() {
  echo "Prepare artisan file permission..."
  chmod a+x ./artisan
}

prepare_storage() {
  echo "Prepare storage and permissions..."
  mkdir -p /var/www/storage/framework/cache/data
  mkdir -p /var/www/storage/framework/sessions
  mkdir -p /var/www/storage/framework/views
  chown -R www-data:www-data /var/www/storage
  chmod -R 775 /var/www/storage
}

wait_for_db() {
  echo "Waiting for database to be ready..."
  DB_HOST=${DB_HOST:-mysql}
  DB_PORT=${DB_PORT:-3306}
  while ! nc -z $DB_HOST $DB_PORT; do
    sleep 1
  done
  echo "Database is ready!"
}

generate_app_key() {
  echo "Generating Laravel app key..."
  php artisan key:generate --force
}

run_migration() {
  echo "Running database migrations..."
  php artisan migrate --force
}

run_seeder() {
  echo "Running database seeders..."
  php artisan db:seed --force
}

optimize_app() {
  echo "Optimizing Laravel app for production..."
#   php artisan config:clear
  php artisan cache:clear
  php artisan view:clear
#   php artisan optimize:clear
#   php artisan config:cache
#   php artisan route:cache
#   php artisan view:cache
#   php artisan event:cache
  php artisan optimize
}

# run_server() {
#   exec php-fpm
# }

main 
exec "$@"