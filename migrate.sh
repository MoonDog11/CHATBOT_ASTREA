#!/bin/bash

set -o pipefail


section() {
  echo "==== $1 ===="
}

error_exit() {
  echo "Error: $1"
  exit 1
}

section "Starting migration"

# Define the dump directory
dump_dir="plugin_dump"
mkdir -p $dump_dir

dump_database() {
  local database=$1
  local dump_file="$dump_dir/$database.sql"

  section "Dumping database: $database"

  echo "Dumping database from $DATABASE_URL"

  PGPASSWORD=$PGPASSWORD pg_dump -h $PGHOST -p $PGPORT -U $PGUSER -d "$database" \
      --format=plain \
      --quote-all-identifiers \
      --no-tablespaces \
      --no-owner \
      --no-privileges \
      --file=$dump_file || error_exit "Failed to dump database from $database."

  echo "Successfully saved dump to $dump_file"
}

# Perform the dump
databases=$(PGPASSWORD=$PGPASSWORD psql -h $PGHOST -p $PGPORT -U $PGUSER -d "$PGDATABASE" -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
for db in $databases; do
  dump_database "$db"
done

echo "Migration completed successfully"
