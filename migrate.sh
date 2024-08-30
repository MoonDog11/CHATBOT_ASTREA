#!/bin/bash

set -o pipefail

# Espera 10 segundos antes de iniciar
sleep 10

# Exporta la ruta de psql dinámicamente
PSQL_PATH=$(which psql)
if [ -z "$PSQL_PATH" ]; then
  echo "psql not found. Please ensure PostgreSQL is installed and in your PATH."
  exit 1
fi

export PATH=$PATH:$(dirname $PSQL_PATH)

export TERM=ansi
_GREEN=$(tput setaf 2)
_BLUE=$(tput setaf 4)
_MAGENTA=$(tput setaf 5)
_CYAN=$(tput setaf 6)
_RED=$(tput setaf 1)
_YELLOW=$(tput setaf 3)
_RESET=$(tput sgr0)
_BOLD=$(tput bold)

# Función para imprimir mensajes de error y salir
error_exit() {
    printf "[ ${_RED}ERROR${_RESET} ] ${_RED}$1${_RESET}\n" >&2
    exit 1
}

section() {
  printf "${_RESET}\n"
  echo "${_BOLD}${_BLUE}==== $1 ====${_RESET}"
}

write_ok() {
  echo "[$_GREEN OK $_RESET] $1"
}

write_info() {
  echo "[$_BLUE INFO $_RESET] $1"
}

write_warn() {
  echo "[$_YELLOW WARN $_RESET] $1"
}

trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

printf "${_BOLD}${_MAGENTA}"
echo "+-------------------------------------+"
echo "|                                     |"
echo "|  Railway Postgres Migration Script  |"
echo "|                                     |"
echo "+-------------------------------------+"
printf "${_RESET}\n"

echo "For more information, see https://docs.railway.app/database/migration"
echo "If you run into any issues, please reach out to us on Discord: https://discord.gg/railway"
printf "${_RESET}\n"

section "Validating environment variables"

# Validar que la variable de entorno PLUGIN_URL existe
if [ -z "$PLUGIN_URL" ]; then
    error_exit "PLUGIN_URL environment variable is not set."
fi

write_ok "PLUGIN_URL correctly set"

# Validar que la variable de entorno NEW_URL existe
if [ -z "$NEW_URL" ]; then
    error_exit "NEW_URL environment variable is not set."
fi

write_ok "NEW_URL correctly set"

section "Checking if NEW_URL is empty"

# Consulta para verificar si hay tablas en la nueva base de datos
query="SELECT count(*)
FROM information_schema.tables t
WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
  AND NOT EXISTS (
    SELECT 1
    FROM pg_depend d
    JOIN pg_extension e ON d.refobjid = e.oid
    JOIN pg_class c ON d.objid = c.oid
    WHERE c.relname = t.table_name
      AND c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = t.table_schema)
  );"
table_count=$(PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $NEW_DB_HOST -p $NEW_DB_PORT -U $NEW_DB_USER -d $NEW_DB_NAME -t -A -c "$query")

if [[ $table_count -eq 0 ]]; then
  write_ok "The new database is empty. Proceeding with restore."
else
  echo "table count: $table_count"
  if [ -z "$OVERWRITE_DATABASE" ]; then
    error_exit "The new database is not empty. Aborting migration.\nSet the OVERWRITE_DATABASE environment variable to overwrite the new database."
  fi
  write_warn "The new database is not empty. Found OVERWRITE_DATABASE environment variable. Proceeding with restore."
fi

dump_dir="plugin_dump"
mkdir -p $dump_dir

dump_database() {
  local database=$1
  local dump_file="$dump_dir/$database.sql"

  section "Dumping database: $database"

  local db_url="$PLUGIN_URL/$database"

  echo "Dumping database from $db_url"

  PGPASSWORD=$DB_PASSWORD $PSQL_PATH -d "$db_url" \
      --format=plain \
      --quote-all-identifiers \
      --no-tablespaces \
      --no-owner \
      --no-privileges \
      --disable-triggers \
      --file=$dump_file || error_exit "Failed to dump database from $database."

  write_ok "Successfully saved dump to $dump_file"

  dump_file_size=$(ls -lh "$dump_file" | awk '{print $5}')
  write_info "Dump file size: $dump_file_size"
}

remove_timescale_commands() {
  local database=$1
  local dump_file="$dump_dir/$database.sql"

  ./comment_timescaledb.awk "$dump_file" > "${dump_file}.new"
  mv "${dump_file}.new" "$dump_file"

  write_ok "Successfully removed TimescaleDB specific commands from $dump_file"
}

# Obtener lista de bases de datos, excluyendo bases de datos del sistema
databases=$($PSQL_PATH -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
write_info "Found databases to migrate: $databases"

dump_dir="plugin_dump"
mkdir -p $dump_dir

for db in $databases; do
  dump_database "$db"
done

trap - ERR # Desactivar temporalmente el manejo de errores para evitar salir en caso de error
PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $NEW_DB_HOST -p $NEW_DB_PORT -U $NEW_DB_USER -d $NEW_DB_NAME -c '\dx' | grep -q 'timescaledb'
timescaledb_exists=$?
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

if [ $timescaledb_exists -ne 0 ]; then
    write_warn "TimescaleDB extension not found in target database. Ignoring TimescaleDB specific commands."
    write_warn "If you are using TimescaleDB, please install the extension in the target database and run the migration again."
fi

# Eliminar la fila _timescaledb_catalog.metadata que contiene el exported_uuid para evitar conflictos
remove_timescale_catalog_metadata() {
  local db_url=$1

  PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $(echo $db_url | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^:]+/(.+)|localhost|') -p $(echo $db_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^:]+/(.+)|5432|') -U $(echo $db_url | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^:]+/(.+)|\1|') -d $(echo $db_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^:]+/(.+)|\1|') -c "
    DO \$\$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                  WHERE n.nspname = '_timescaledb_catalog' AND c.relname = 'metadata') THEN
          DELETE FROM _timescaledb_catalog.metadata WHERE key = 'exported_uuid';
      END IF;
    END
    \$\$
  "
}

# Crear la base de datos en la cadena de conexión proporcionada si no existe
ensure_database_exists() {
  local db_url=$1

  # Extraer el nombre de la base de datos de NEW_URL
  local db_name=$(echo $db_url | sed -E 's/.*\/([^\/?]+).*/\1/')

  # Extraer otros componentes de NEW_URL para el comando psql
  local psql_url=$(echo $db_url | sed -E 's/(.*)\/[^\/?]+/\1/')

  # Verificar si la base de datos existe
  if ! PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $(echo $psql_url | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^/]+|localhost|') -p $(echo $psql_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^/]+|5432|') -U $(echo $psql_url | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^/]+|localhost|') -d $(echo $psql_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^/]+/(.+)|\1|') -c "SELECT 1 FROM pg_database WHERE datname = '$db_name';" | grep -q 1; then
    write_info "Database $db_name does not exist. Creating it."
    PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $(echo $psql_url | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^/]+|localhost|') -p $(echo $psql_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^/]+|5432|') -U $(echo $psql_url | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^/]+|localhost|') -d $(echo $psql_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^/]+/(.+)|\1|') -c "CREATE DATABASE $db_name;"
  fi
}

# Ejecutar el script de migración
section "Starting migration"
for db in $databases; do
  remove_timescale_commands "$db"
  ensure_database_exists "$NEW_URL"
  PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $(echo $NEW_URL | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^/]+|localhost|') -p $(echo $NEW_URL | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^/]+|5432|') -U $(echo $NEW_URL | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^/]+|localhost|') -d $(echo $NEW_URL | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^/]+/(.+)|\1|') -f "$dump_dir/$db.sql"
done
