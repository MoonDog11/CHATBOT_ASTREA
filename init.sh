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
