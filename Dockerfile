# Utilizar la imagen base de Node.js versión 18
FROM node:18

# Instalar dependencias para PostgreSQL
FROM ubuntu:jammy

# Add the PostgreSQL Apt Repository for PostgreSQL packages
RUN apt-get update && \
    apt-get install -y gnupg wget && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install postgresql-client-16
RUN apt-get update && \
    apt-get install -y postgresql-client-16 bash ncurses-bin && \
    rm -rf /var/lib/apt/lists/*

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /

# Copiar los archivos necesarios para la aplicación
COPY package*.json ./

# Impresión de archivos en la raíz antes de npm install
RUN echo "Archivos en la raíz antes de npm install:"
RUN ls -l /

# Instalar dependencias Node.js
RUN npm install

# Copiar todo el código de la aplicación
COPY . .

# Impresión de archivos en la raíz después de npm install y antes de mkdir /client
RUN echo "Archivos en la raíz después de npm install y antes de mkdir /client:"
RUN ls -l /

# Asegurar que se cree la estructura de directorios correcta
RUN mkdir -p /client

# Impresión de archivos en la raíz después de mkdir /client y antes de COPY ./client
RUN echo "Archivos en la raíz después de mkdir /client y antes de COPY ./client:"
RUN ls -l /

# Copiar y establecer permisos para el script init.sh
COPY init.sh /
RUN chmod +x /init.sh

# Impresión de archivos en la raíz después de COPY init.sh
RUN echo "Archivos en la raíz después de COPY init.sh:"
RUN ls -l /

# Exponer el puerto en el que la aplicación escuchará (si es necesario)
# EXPOSE 8080

# Configurar HEALTHCHECK (opcional)
# HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
#   CMD curl --fail http://localhost:8080/ || exit 1

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/init.sh"] 
