# Ejecutar migraciones de base de datos si existe el archivo /app/migrate.sh
echo "Running database migrations..."
if [ -f /app/migrate.sh ]; then
    /app/migrate.sh
else
    echo "Migration script not found!"
fi

# Iniciar la aplicación Node.js (app.js) si existe el archivo /app/server/app.js
echo "Starting the application..."
if [ -f /app/server/app.js ]; then
    node /app/server/app.js
else
    echo "Application entry point not found!"
fi

# Imprimir un mensaje indicando la finalización de la inicialización
echo "Initialization complete."
