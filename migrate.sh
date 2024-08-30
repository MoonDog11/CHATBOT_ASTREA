#!/bin/bash

set -o pipefail

export TERM=ansi
_GREEN=$(tput setaf 2)
_BLUE=$(tput setaf 4)
_MAGENTA=$(tput setaf 5)
_CYAN=$(tput setaf 6)
_RED=$(tput setaf 1)
_YELLOW=$(tput setaf 3)
_RESET=$(tput sgr0)
_BOLD=$(tput bold)

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

for var in DATABASE_URL; do
    if [ -z "${!var}" ]; then
        error_exit "$var environment variable is not set."
    fi
done

write_ok "All required environment variables are set"

section "Checking if the new database is empty"

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

table_count=$(PGPASSWORD=$PGPASSWORD psql "$DATABASE_URL" -t -A -c "$query")

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

  echo "Dumping database from $DATABASE_URL"

  PGPASSWORD=$PGPASSWORD pg_dump "$DATABASE_URL" \
      --format=plain \
      --quote-all-identifiers \
      --no-tablespaces \
      --no-owner \
      --no-privileges \
      --disable-tables \
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

databases=$(PGPASSWORD=$PGPASSWORD psql "$DATABASE_URL" -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
write_info "Found databases to migrate: $databases"

for db in $databases; do
  dump_database "$db"
done

trap - ERR # Temporary disable error trap to avoid exiting on error
PGPASSWORD=$PGPASSWORD psql "$DATABASE_URL" -c '\dx' | grep -q 'timescaledb'
timescaledb_exists=$?
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

if [ $timescaledb_exists -ne 0 ]; then
    write_warn "TimescaleDB extension not found in target database. Ignoring TimescaleDB specific commands."
    write_warn "If you are using TimescaleDB, please install the extension in the target database and run the migration again."
fi

remove_timescale_catalog_metadata() {
  local db_url=$1

  PGPASSWORD=$PGPASSWORD psql "$db_url" -c "
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

  local db_name=$(echo $db_url | sed -E 's/.*\/([^\/?]+).*/\1/')
  local psql_url=$(echo $db_url | sed -E 's/(.*)\/[^\/?]+/\1/')

  if ! PGPASSWORD=$PGPASSWORD psql "$psql_url" -tA -c "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1; then
      write_ok "Database $db_name does not exist. Creating..."
      PGPASSWORD=$PGPASSWORD psql "$psql_url" -c "CREATE DATABASE \"$db_name\""
  else
      write_info "Database $db_name exists."
  fi
}

restore_database() {
  section "Restoring database: $db"

  if [ $timescaledb_exists -ne 0 ]; then
    remove_timescale_commands "$db"
  fi

  ensure_database_exists "$DATABASE_URL"
  remove_timescale_catalog_metadata "$DATABASE_URL"

  PGPASSWORD=$PGPASSWORD psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --echo-errors \
    -f "$dump_dir/$db.sql" > /dev/null || error_exit "Failed to restore database to DATABASE_URL."

  write_ok "Successfully restored $db to DATABASE_URL"
}

for db in $databases; do
  restore_database "$db"
done

printf "${_RESET}\n"
printf "${_RESET}\n"
echo "${_BOLD}${_GREEN}Migration completed successfully${_RESET}"
printf "${_RESET}\n"
echo "Next steps..."
echo "1. Update your application's DATABASE_URL environment variable to point to the new database."
echo '  - You can use variable references to do this. For example `${{ Postgres.DATABASE_URL }}`'
echo "2. Verify that your application is working as expected."
echo "3. Remove the legacy plugin and this service from your Railway project."

printf "${_RESET}\n"
