#!/bin/bash

# Imprimir mensaje de inicio
echo "Listando archivos y directorios en el contenedor..."

# Listar archivos en el directorio raíz
echo "Archivos en /:"
ls -l /

# Listar archivos en el directorio de trabajo de la aplicación
echo "Archivos en /app:"
ls -l /app

# Listar archivos en el directorio de trabajo de la aplicación cliente, si existe
if [ -d /app/client ]; then
    echo "Archivos en /app/client:"
    ls -l /app/client
else
    echo "Directorio /app/client no encontrado."
fi

# Listar archivos en el directorio de scripts, si existe
if [ -d /app/scripts ]; then
    echo "Archivos en /app/scripts:"
    ls -l /app/scripts
else
    echo "Directorio /app/scripts no encontrado."
fi

# Listar archivos en el directorio de migraciones, si existe
if [ -d /app/migrations ]; then
    echo "Archivos en /app/migrations:"
    ls -l /app/migrations
else
    echo "Directorio /app/migrations no encontrado."
