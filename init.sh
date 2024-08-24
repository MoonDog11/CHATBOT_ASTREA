#!/bin/bash

# Print a message indicating the start of the initialization
echo "Starting initialization..."

# Run database migrations
echo "Running database migrations..."
if [ -f /app/migrate.sh ]; then
    /app/migrate.sh
else
    echo "Migration script not found!"
fi

# Start the application
echo "Starting the application..."
if [ -f /app/app.js ]; then
    node /app/app.js
else
    echo "Application entry point not found!"
fi

# Print a message indicating the end of initialization
echo "Initialization complete."
#!/bin/bash

# Imprimir mensaje de inicio
echo "Iniciando el contenedor..."

# Ejecutar script de migración si es necesario
if [ -f /app/migrate.sh ]; then
    echo "Ejecutando script de migración..."
    /app/migrate.sh
fi

# Iniciar la aplicación
echo "Iniciando la aplicación..."
node /app/app.js
