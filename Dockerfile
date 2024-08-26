# Utilizar la imagen base de Node.js versión 18
FROM node:18

# Instalar dependencias para PostgreSQL
RUN apt-get update && \
    apt-get install -y gnupg wget && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar los archivos necesarios para la aplicación
COPY package*.json ./

# Instalar dependencias Node.js
RUN npm install

# Copiar todo el código de la aplicación (incluyendo server/)
COPY . .

# Asegurar que se cree la estructura de directorios correcta
RUN mkdir -p /app/client

# Copiar y establecer permisos para el script init.sh
COPY init.sh /
RUN chmod +x /init.sh

# Exponer el puerto en el que la aplicación escuchará (si es necesario)
# EXPOSE 8080

# Configurar HEALTHCHECK (opcional)
# HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
#   CMD curl --fail http://localhost:8080/ || exit 1

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/init.sh"]
