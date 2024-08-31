#!/bin/bash

set -o pipefail

section() {
  echo "==== $1 ===="
}

error_exit() {
  echo "Error: $1"
  exit 1
}

# Configuración para la base de datos de origen
export PGHOST_SOURCE=10.250.18.6
export PGPORT_SOURCE=5432
export PGUSER_SOURCE=postgres
export PGPASSWORD_SOURCE=RoJuKhWPvLtbSQILdwueQPcKMGUuXMkE
export PGDATABASE_SOURCE=nordeste_abogados_users_db

# Configuración para la base de datos de destino (Railway)
export PGHOST_DEST=viaduct.proxy.rlwy.net
export PGPORT_DEST=56284
export PGUSER_DEST=postgres
export PGPASSWORD_DEST=RoJuKhWPvLtbSQILdwueQPcKMGUuXMkE
export PGDATABASE_DEST=railway

section "Starting migration"

# Define el directorio para el volcado
dump_dir="plugin_dump"
mkdir -p $dump_dir

dump_database() {
  local database=$1
  local dump_file="$dump_dir/$database.sql"

  section "Dumping database: $database"

  echo "Dumping database from $PGDATABASE_SOURCE"

  PGPASSWORD=$PGPASSWORD_SOURCE pg_dump -h $PGHOST_SOURCE -p $PGPORT_SOURCE -U $PGUSER_SOURCE -d "$database" \
      --format=plain \
      --quote-all-identifiers \
      --no-tablespaces \
      --no-owner \
      --no-privileges \
      --file=$dump_file || error_exit "Failed to dump database from $database."

  echo "Successfully saved dump to $dump_file"
}

# Realiza el volcado
databases=$(PGPASSWORD=$PGPASSWORD_SOURCE psql -h $PGHOST_SOURCE -p $PGPORT_SOURCE -U $PGUSER_SOURCE -d "$PGDATABASE_SOURCE" -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
for db in $databases; do
  dump_database "$db"
done

section "Uploading dumps to Railway"

# Subir dumps a la base de datos de destino en Railway
upload_dump() {
  local dump_file=$1
  local database=$2

  section "Uploading dump for database: $database"

  PGPASSWORD=$PGPASSWORD_DEST psql -h $PGHOST_DEST -p $PGPORT_DEST -U $PGUSER_DEST -d "$database" -f "$dump_file" || error_exit "Failed to upload dump to $database."
  
  echo "Successfully uploaded dump for $database"
}

# Sube cada volcado a Railway
for dump_file in $dump_dir/*.sql; do
  db_name=$(basename "$dump_file" .sql)
  upload_dump "$dump_file" "$db_name"
done

echo "Migration completed successfully"
