#!/bin/bash

set -o pipefail

section() {
  echo "==== $1 ===="
}

error_exit() {
  echo "Error: $1"
  exit 1
}

# Exportar variables de configuración
export DB_USER=postgres
export DB_PASSWORD=Jphv19840625*
export DB_HOST=localhost
export DB_PORT=5432
export DB_DATABASE=nordeste_abogados_users_db
export PLUGIN_URL=postgresql://postgres:Jphv19840625*@localhost:5432/nordeste_abogados_users_db

# Variables de configuración para Railway
export RAILWAY_URL=postgresql://postgres:RoJuKhWPvLtbSQILdwueQPcKMGUuXMkE@viaduct.proxy.rlwy.net:56284/railway

# Define el directorio para el volcado
dump_dir="plugin_dump"
mkdir -p $dump_dir

# Función para verificar la conexión a la base de datos
check_db_connection() {
  section "Checking database connection"

  PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "\q" &> /dev/null
  if [ $? -eq 0 ]; then
    echo "Successfully connected to the database $DB_DATABASE at $DB_HOST:$DB_PORT"
  else
    error_exit "Failed to connect to the database $DB_DATABASE at $DB_HOST:$DB_PORT"
  fi
}

# Función para volcar la base de datos
dump_database() {
  local database=$1
  local dump_file="$dump_dir/${database}_dump.sql"

  section "Dumping database: $database"

  echo "Dumping database from $PLUGIN_URL"

  PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$database" \
      --format=plain \
      --quote-all-identifiers \
      --no-tablespaces \
      --no-owner \
      --no-privileges \
      --file=$dump_file || error_exit "Failed to dump database from $database."

  echo "Successfully saved dump to $dump_file"
}

# Función para subir el volcado a Railway
upload_dump() {
  local dump_file=$1
  local database=$2

  section "Uploading dump for database: $database"

  PGPASSWORD=RoJuKhWPvLtbSQILdwueQPcKMGUuXMkE psql -h viaduct.proxy.rlwy.net -p 56284 -U postgres -d "$database" -f "$dump_file" || error_exit "Failed to upload dump to $database."
  
  echo "Successfully uploaded dump for $database"
}

# Inicializar el servidor
initialize_server() {
  section "Starting server"

  # Aquí se incluirían las instrucciones para iniciar el servidor.
  # Asegúrate de que cualquier comando o script que inicie el servidor se ejecuta aquí.
  
  # Ejemplo:
  # npm start
}

section "Starting migration"

# Verificar la conexión a la base de datos
check_db_connection

# Realizar el volcado
databases=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$DB_DATABASE" -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
for db in $databases; do
  dump_database "$db"
done

section "Uploading dumps to Railway"

# Subir cada volcado a Railway
for dump_file in $dump_dir/*_dump.sql; do
  db_name=$(basename "$dump_file" _dump.sql)
  upload_dump "$dump_file" "$db_name"
done

# Inicializar el servidor después de la migración
initialize_server

echo "Migration and server initialization completed successfully"
