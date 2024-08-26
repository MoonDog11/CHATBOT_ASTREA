#!/bin/bash

# Imprimir un mensaje indicando el inicio de la inicialización
echo "Starting initialization..."

# Ejecutar migraciones de base de datos si existe el archivo /server/migrate.sh
echo "Running database migrations..."
if [ -f /server/migrate.sh ]; then
    /server/migrate.sh
else
    echo "Migration script not found!"
fi

# Cambiar al directorio /server para iniciar la aplicación Node.js
cd /server || exit

# Iniciar la aplicación Node.js (app.js) desde el directorio /server
echo "Starting the application..."
if [ -f /server/app.js ]; then
    node app.js &
else
    echo "Application entry point not found!"
    exit 1
fi

# Esperar a que la aplicación se inicie correctamente
echo "Waiting for the application to start..."
while ! nc -z localhost 8080; do
  sleep 0.1
done

echo "Application started successfully."

# Imprimir un mensaje indicando la finalización de la inicialización
echo "Initialization complete."

# Mantener el contenedor en ejecución
tail -f /dev/null
