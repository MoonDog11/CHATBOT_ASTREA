# Usar la imagen base
FROM node:18

# Crear el directorio de la aplicación
WORKDIR /app

# Copiar archivos de configuración
COPY package*.json ./
RUN npm install

# Copiar todos los archivos de la aplicación
COPY . .

# Copiar el script list_files.sh y dar permisos de ejecución
COPY list_files.sh /app/
RUN chmod +x /app/list_files.sh

# Ejecutar el script para listar archivos (solo para depuración)
RUN /app/list_files.sh

# Copiar el script init.sh y dar permisos de ejecución
COPY init.sh /app/
RUN chmod +x /app/init.sh

# Configurar HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl --fail http://localhost:8080/ || exit 1
  
# Establecer el punto de entrada
ENTRYPOINT ["/app/init.sh"]
