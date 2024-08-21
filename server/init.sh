#!/bin/bash

# Asegurar que migrate.sh tenga permisos de ejecución
chmod +x /app/migrate.sh

# Ejecutar el script de migración
/app/migrate.sh

# Iniciar el servidor Node.js
node /app/app.js

