#!/bin/bash

# Asegurar que migrate.sh tenga permisos de ejecución
chmod +x /app/migrate.sh

# Verificar la existencia del archivo migrate.sh
if [ -f /app/migrate.sh ]; then
    echo "migrate.sh encontrado."
else
    echo "migrate.sh no encontrado."
    exit 1
fi

# Ejecutar el script de migración
/app/migrate.sh

# Iniciar el servidor Node.js
node /app/app.js



