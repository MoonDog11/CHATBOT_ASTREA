#!/bin/bash

# Asegurarse de que migrate.sh tenga permisos de ejecución
chmod +x /app/migrate.sh

# Ejecutar el script de migración y luego el servidor
/app/migrate.sh
node /app/app.js
