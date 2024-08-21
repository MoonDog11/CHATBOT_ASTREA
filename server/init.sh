#!/bin/bash

# Asegurar que migrate.sh tenga permisos de ejecución
chmod +x /app/migrate.sh

# Ejecutar el script de migración
/app/migrate.sh

# Copiar landing.html si está presente en /app/client
if [ -f "/app/client/landing.html" ]; then
    cp /app/client/landing.html /app/
fi

# Iniciar el servidor Node.js
node /app/app.js

