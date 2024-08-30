#!/bin/bash

set -o pipefail

# Espera 10 segundos antes de iniciar
sleep 10

# Ruta a psql
PSQL_PATH="/usr/local/Cellar/postgresql@14/14.13/bin/psql"

echo "Ruta detectada para psql: $PSQL_PATH"

if [ ! -x "$PSQL_PATH" ]; then
  echo "psql no encontrado en $PSQL_PATH. Asegúrate de que PostgreSQL esté instalado y la ruta sea correcta."
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

# Validar que la variable de entorno DATABASE_URL existe
if [ -z "$DATABASE_URL" ]; then
    error_exit "DATABASE_URL environment variable is not set."
fi

write_ok "DATABASE_URL correctly set"

section "Checking if DATABASE_URL is empty"

# Obtener la URL de conexión destino desglosada
DB_URL_HOST=$(echo $DATABASE_URL | sed -E 's|postgresql://([^:]+):[^@]+@([^:]+):([0-9]+)/([^?]+)|\2|')
DB_URL_PORT=$(echo $DATABASE_URL | sed -E 's|postgresql://([^:]+):[^@]+@([^:]+):([0-9]+)/([^?]+)|\3|')
DB_URL_USER=$(echo $DATABASE_URL | sed -E 's|postgresql://([^:]+):[^@]+@([^:]+):([0-9]+)/([^?]+)|\1|')
DB_URL_DB=$(echo $DATABASE_URL | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^/]+/(.+)|\1|')

# Consulta para verificar si hay tablas en la nueva base de datos
query="SELECT count(*) FROM information_schema.tables t WHERE table_schema NOT IN ('information_schema', 'pg_catalog') AND NOT EXISTS (SELECT 1 FROM pg_depend d JOIN pg_extension e ON d.refobjid = e.oid JOIN pg_class c ON d.objid = c.oid WHERE c.relname = t.table_name AND c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = t.table_schema));"
table_count=$(PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $DB_URL_HOST -p $DB_URL_PORT -U $DB_URL_USER -d $DB_URL_DB -t -A -c "$query")

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

  PGPASSWORD=$DB_PASSWORD $PSQL_PATH -d "$db_url" --format=plain --quote-all-identifiers --no-tablespaces --no-owner --no-privileges --disable-triggers --file=$dump_file || error_exit "Failed to dump database from $database."

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

databases=$(PGPASSWORD=$DB_PASSWORD $PSQL_PATH -h $(echo $PLUGIN_URL | sed -E 's|postgresql://([^:]+):[^@]+@([^:]+):([0-9]+)/([^?]+)|\2|') -p $(echo $PLUGIN_URL | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^:]+/(.+)|\3|') -U $(echo $PLUGIN_URL | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^:]+/(.+)|\1|') -d $(echo $PLUGIN_URL | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^:]+/(.+)|\1|') -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
write_info "Found databases to migrate: $databases"

dump_dir="plugin_dump"
mkdir -p $dump_dir

for db in $databases; do
  dump_database "$db"
done

trap - ERR
PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $DB_URL_HOST -p $DB_URL_PORT -U $DB_URL_USER -d $DB_URL_DB -c '\dx' | grep -q 'timescaledb'
timescaledb_exists=$?
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

if [ $timescaledb_exists -ne 0 ]; then
    write_warn "TimescaleDB extension not found in target database. Ignoring TimescaleDB specific commands."
    write_warn "If you are using TimescaleDB, please install the extension in the target database and run the migration again."
fi

remove_timescale_catalog_metadata() {
  local db_url=$1

  PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $(echo $db_url | sed -E 's|postgresql://([^:]+):[^@]+@([^:]+):([0-9]+)/([^?]+)|\2|') -p $(echo $db_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^:]+/(.+)|\3|') -U $(echo $db_url | sed -E 's|postgresql://([^:]+):[^@]+@[^:]+:[^:]+/(.+)|\1|') -d $(echo $db_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^:]+/(.+)|\1|') -c "
  DO \$\$
  BEGIN
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = '_timescaledb_catalog' AND c.relname = 'metadata') THEN
        DELETE FROM _timescaledb_catalog.metadata;
    END IF;
  END \$\$;
  " || error_exit "Failed to remove TimescaleDB catalog metadata."

  write_ok "Successfully removed TimescaleDB catalog metadata from $db_url"
}

remove_timescale_catalog_metadata "$DATABASE_URL"

ensure_database_exists() {
  local db_url=$1
  local db_name=$(echo $db_url | sed -E 's|postgresql://[^:]+:[^@]+@[^:]+:[^:]+/(.+)|\1|')

  PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $DB_URL_HOST -p $DB_URL_PORT -U $DB_URL_USER -d postgres -c "CREATE DATABASE $db_name;" || echo "Database $db_name already exists or could not be created."
}

restore_database() {
  local db=$1
  local dump_file="$dump_dir/$db.sql"

  section "Restoring database: $db"

  ensure_database_exists "$DATABASE_URL/$db"

  PGPASSWORD=$NEW_PASSWORD $PSQL_PATH -h $DB_URL_HOST -p $DB_URL_PORT -U $DB_URL_USER -d $db -f "$dump_file" || error_exit "Failed to restore database from $dump_file."

  write_ok "Successfully restored database $db from $dump_file"
}

for db in $databases; do
  restore_database "$db"
done
