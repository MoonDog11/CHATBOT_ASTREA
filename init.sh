#!/bin/bash

# Asegurarse de que migrate.sh tenga permisos de ejecución
chmod +x /app/migrate.sh

# Verificar la existencia del archivo migrate.sh
if [ -f /app/migrate.sh ]; then
    echo "migrate.sh encontrado."
    # Ejecutar el script de migración
    /app/migrate.sh
else
    echo "migrate.sh no encontrado."
    exit 1
fi

# Iniciar el servidor Node.js desde el directorio server
node /app/server/app.js
