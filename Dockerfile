FROM node:18

# Add the PostgreSQL Apt Repository for PostgreSQL packages
RUN apt-get update && \
    apt-get install -y gnupg wget && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar los archivos necesarios para la aplicación
COPY package*.json ./
RUN npm install

# Copiar el código de la aplicación y archivos HTML
COPY . .

# Asegurar que se cree la estructura de directorios correcta
RUN mkdir -p /app/client

# Copiar y establecer permisos para scripts init.sh
COPY init.sh /app/
RUN chmod +x /app/init.sh

# Exponer el puerto en el que la aplicación escuchará
EXPOSE 8080

# Configurar HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl --fail http://localhost:8080/ || exit 1

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/app/init.sh"]
