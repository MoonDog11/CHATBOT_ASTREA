#!/bin/bash

# Imprimir un mensaje indicando el inicio de la inicialización
echo "Starting initialization..."

# Ejecutar migraciones de base de datos si existe el archivo /migrate.sh
echo "Running database migrations..."
if [ -f /migrate.sh ]; then
    chmod +x /migrate.sh  # Asegurar que migrate.sh tenga permisos de ejecución
    /migrate.sh
else
    echo "Migration script not found!"
fi

# Cambiar al directorio /app/server para iniciar la aplicación Node.js
cd /server || exit

# Iniciar la aplicación Node.js (app.js) desde el directorio /app/server
echo "Starting the application..."
if [ -f app.js ]; then
    node app.js
else
    echo "Application entry point not found!"
fi

# Imprimir un mensaje indicando la finalización de la inicialización
echo "Initialization complete."
