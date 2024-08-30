#!/bin/bash

set -o pipefail

# Color definitions
export TERM=ansi
_GREEN=$(tput setaf 2)
_BLUE=$(tput setaf 4)
_MAGENTA=$(tput setaf 5)
_CYAN=$(tput setaf 6)
_RED=$(tput setaf 1)
_YELLOW=$(tput setaf 3)
_RESET=$(tput sgr0)
_BOLD=$(tput bold)

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

error_exit() {
  printf "[ ${_RED}ERROR${_RESET} ] ${_RED}$1${_RESET}\n" >&2
  exit 1
}

trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# Initialize
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

# Validate that required environment variables are set
for var in DATABASE_URL PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER PLUGIN_URL; do
    if [ -z "${!var}" ]; then
        error_exit "$var environment variable is not set."
    fi
done

write_ok "All required environment variables are set"

section "Checking if the new database is empty"

# Query to check if there are any tables in the new database
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
table_count=$(PGPASSWORD=$PGPASSWORD psql -h $PGHOST -p $PGPORT -U $PGUSER -d "$PGDATABASE" -t -A -c "$query")

if [[ $table_count -eq 0 ]]; then
  write_ok "The new database is empty. Proceeding with restore."
else
  echo "table count: $table_count"
  if [ -z "$OVERWRITE_DATABASE" ]; then
    error_exit "The new database is not empty. Aborting migration.\nSet the OVERWRITE_DATABASE environment variable to overwrite the new database."
  fi
  write_warn "The new database is not empty. Found OVERWRITE_DATABASE environment variable. Proceeding with restore."
fi

# Define the dump directory
dump_dir="plugin_dump"
mkdir -p $dump_dir

dump_database() {
  local database=$1
  local dump_file="$dump_dir/$database.sql"

  section "Dumping database: $database"

  local base_url=$(echo $PLUGIN_URL | sed -E 's/(postgresql:\/\/[^:]+:[^@]+@[^:]+:[0-9]+)\/.*/\1/')
  local db_url="${base_url}/${database}"

  echo "Dumping database from $db_url"

  PGPASSWORD=$PGPASSWORD pg_dump -h $PGHOST -p $PGPORT -U $PGUSER -d "$db_url" \
      --format=plain \
      --quote-all-identifiers \
      --no-tablespaces \
      --no-owner \
      --no-privileges \
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

# Get list of databases, excluding system databases
databases=$(PGPASSWORD=$PGPASSWORD psql -h $PGHOST -p $PGPORT -U $PGUSER -d "$PGDATABASE" -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
write_info "Found databases to migrate: $databases"

for db in $databases; do
  dump_database "$db"
done

trap - ERR # Temporary disable error trap to avoid exiting on error
PGPASSWORD=$PGPASSWORD psql -h $PGHOST -p $PGPORT -U $PGUSER -d "$PGDATABASE" -c '\dx' | grep -q 'timescaledb'
timescaledb_exists=$?
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

if [ $timescaledb_exists -ne 0 ]; then
    write_warn "TimescaleDB extension not found in target database. Ignoring TimescaleDB specific commands."
    write_warn "If you are using TimescaleDB, please install the extension in the target database and run the migration again."
fi

remove_timescale_catalog_metadata() {
  local db_url=$1

  PGPASSWORD=$PGPASSWORD psql -h $(echo $db_url | sed -E 's/postgresql:\/\/[^:]+:[^@]+@[^:]+:[0-9]+\/(.*)/\1/') -d $(echo $db_url | sed -E 's/.*\/([^\/?]+).*/\1/') -c "
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

ensure_database_exists() {
  local db_url=$1

  # Extract database name from DATABASE_URL
  local db_name=$(echo $db_url | sed -E 's/.*\/([^\/?]+).*/\1/')

  # Extract other components from DATABASE_URL for psql command
  local psql_url=$(echo $db_url | sed -E 's/(.*)\/[^\/?]+/\1/')

  # Check if database exists
  if ! PGPASSWORD=$PGPASSWORD psql -h $PGHOST -p $PGPORT -U $PGUSER -d "$psql_url" -tA -c "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1; then
      write_ok "Database $db_name does not exist. Creating..."
      PGPASSWORD=$PGPASSWORD psql -h $PGHOST -p $PGPORT -U $PGUSER -d "$psql_url" -c "CREATE DATABASE \"$db_name\""
  else
      write_info "Database $db_name exists."
  fi
}

restore_database() {
  section "Restoring database: $db"

  if [ $timescaledb_exists -ne 0 ]; then
    remove_timescale_commands "$db"
  fi

  local base_url=$(echo $DATABASE_URL | sed -E 's/(postgresql:\/\/[^:]+:[^@]+@[^:]+:[0-9]+)\/.*/\1/')
  local db_url="${base_url}/${db}"

  ensure_database_exists "$db_url"
  remove_timescale_catalog_metadata "$db_url"

  PGPASSWORD=$PGPASSWORD psql -h $PGHOST -p $PGPORT -U $PGUSER -d "$db_url" < "$dump_dir/$db.sql" || error_exit "Failed to restore database $db."

  write_ok "Successfully restored database $db"
}

for db in $databases; do
  restore_database "$db"
done

section "Starting application"

# Start the application
exec npm start
