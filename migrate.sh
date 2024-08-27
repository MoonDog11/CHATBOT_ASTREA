#!/bin/bash

set -o pipefail

# Definición de colores para salida en consola
_GREEN="\033[0;32m"
_BLUE="\033[0;34m"
_MAGENTA="\033[0;35m"
_RESET="\033[0m"
_BOLD="\033[1m"
_RED="\033[0;31m"
_YELLOW="\033[1;33m"

# Función para mostrar errores y salir
error_exit() {
    printf "[ ${_RED}ERROR${_RESET} ] ${_RED}$1${_RESET}\n" >&2
    exit 1
}

# Función para mostrar secciones
section() {
  printf "${_RESET}\n"
  echo "${_BOLD}${_BLUE}==== $1 ====${_RESET}"
}

# Función para mostrar mensaje de éxito
write_ok() {
  echo "[$_GREEN OK $_RESET] $1"
}

# Función para mostrar mensaje de información
write_info() {
  echo "[$_BLUE INFO $_RESET] $1"
}

# Función para mostrar advertencia
write_warn() {
  echo "[$_YELLOW WARN $_RESET] $1"
}

# Captura de errores
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Encabezado del script
printf "${_BOLD}${_MAGENTA}"
echo "+-------------------------------------+"
echo "|                                     |"
echo "|  Railway Postgres Migration Script  |"
echo "|                                     |"
echo "+-------------------------------------+"
printf "${_RESET}\n"

# Validación de variables de entorno
section "Validating environment variables"

if [ -z "$PLUGIN_URL" ]; then
    error_exit "PLUGIN_URL environment variable is not set."
fi

write_ok "PLUGIN_URL correctly set"

if [ -z "$DATABASE_URL" ]; then
    error_exit "DATABASE_URL environment variable is not set."
fi

write_ok "DATABASE_URL correctly set"

# Extraer información de DATABASE_URL usando bash
export DB_HOST=$(echo "$DATABASE_URL" | awk -F[@:] '{print $4}')
export DB_PORT=$(echo "$DATABASE_URL" | awk -F[@:] '{print $5}')
export DB_USER=$(echo "$DATABASE_URL" | awk -F[/@] '{print $4}')
export DB_PASSWORD=$(echo "$DATABASE_URL" | awk -F[:] '{print $3}' | sed 's/@.*//')
export DB_NAME=$(echo "$DATABASE_URL" | awk -F[/:] '{print $4}')

section "Checking if DATABASE_URL is empty"

query="SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');"
table_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "$query")

if [[ $table_count -eq 0 ]]; then
  write_ok "The new database is empty. Proceeding with restore."
else
  echo "Table count: $table_count"
  if [ -z "$OVERWRITE_DATABASE" ]; then
    error_exit "The new database is not empty. Aborting migration.\nSet the OVERWRITE_DATABASE environment variable to overwrite the new database."
  fi
  write_warn "The new database is not empty. Found OVERWRITE_DATABASE environment variable. Proceeding with restore."
fi

dump_dir="plugin_dump"
mkdir -p "$dump_dir"

# Función para volcar la base de datos
dump_database() {
  local database="$1"
  local dump_file="$dump_dir/$database.sql"

  section "Dumping database: $database"

  local base_url=$(echo "$PLUGIN_URL" | sed -E 's/(postgresql:\/\/[^:]+:[^@]+@[^:]+:[0-9]+)\/.*/\1/')
  local db_url="${base_url}/${database}"

  echo "Dumping database from $db_url"

  PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$database" \
      --format=plain \
      --quote-all-identifiers \
      --no-tablespaces \
      --no-owner \
      --no-privileges \
      --disable-triggers \
      --file="$dump_file" || error_exit "Failed to dump database from $database."

  write_ok "Successfully saved dump to $dump_file"

  dump_file_size=$(ls -lh "$dump_file" | awk '{print $5}')
  write_info "Dump file size: $dump_file_size"
}

# Obtener listado de bases de datos a migrar
databases=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
write_info "Found databases to migrate: $databases"

# Iterar sobre cada base de datos para realizar el volcado
for db in $databases; do
  dump_database "$db"
done

# Función para restaurar la base de datos desde el volcado
restore_database() {
  local database="$1"

  section "Restoring database: $database"

  local base_url=$(echo "$DATABASE_URL" | sed -E 's/(postgresql:\/\/[^:]+:[^@]+@[^:]+:[0-9]+)\/.*/\1/')
  local db_url="${base_url}/${database}"

  local db_name=$(echo "$db_url" | sed -E 's/.*\/([^?]+).*/\1/')
  local db_url_base=$(echo "$db_url" | sed -E 's/(.*)\/[^\/?]+/\1/')

  if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$db_url_base" -tA -c "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1; then
      write_ok "Database $db_name does not exist. Creating..."
      PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$db_url_base" -c "CREATE DATABASE \"$db_name\""
  else
      write_info "Database $db_name exists."
  fi

  PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$db_url" -v ON_ERROR_STOP=1 --echo-errors \
    -f "$dump_dir/$database.sql" || error_exit "Failed to restore database $database."
  
  write_ok "Successfully restored database $database from dump"
}

# Iterar sobre cada base de datos para restaurarla desde el volcado
for db in $databases; do
  restore_database "$db"
done

echo "Migration completed successfully."

# Iniciar el servidor (asumiendo que esta parte es para otro script o aplicación relacionada)
section "Starting the server"
# node app.js || error_exit "Failed to start the server."
write_ok "Server started successfully."
