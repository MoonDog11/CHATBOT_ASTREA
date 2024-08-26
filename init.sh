#!/bin/bash

# Imprimir un mensaje indicando el inicio de la inicialización
echo "Starting initialization..."

# Ejecutar migraciones de base de datos si existe el archivo /app/server/migrate.sh
echo "Running database migrations..."
if [ -f /server/migrate.sh ]; then
    /server/migrate.sh
else
    echo "Migration script not found!"
fi

# Cambiar al directorio /app/server para iniciar la aplicación Node.js
cd /app/server || exit

# Iniciar la aplicación Node.js (app.js) desde el directorio /app/server
echo "Starting the application..."
if [ -f /app/server/app.js ]; then
    node app.js
else
    echo "Application entry point not found!"
fi

# Imprimir un mensaje indicando la finalización de la inicialización
echo "Initialization complete."
