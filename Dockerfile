# Utilizar la imagen base de Ubuntu
FROM ubuntu:20.04

# Instalar dependencias necesarias
RUN apt-get update && \
    apt-get install -y gnupg wget

# Agregar la clave de PostgreSQL
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Agregar el repositorio de PostgreSQL
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Actualizar nuevamente después de agregar el repositorio
RUN apt-get update

# Instalar PostgreSQL cliente
RUN apt-get install -y postgresql-client

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /

# Copiar los archivos necesarios para la aplicación
COPY package*.json ./

# Instalación de dependencias Node.js
RUN apt-get install -y nodejs npm
RUN npm install

# Copiar todo el código de la aplicación
COPY . .

# Copiar y establecer permisos para el script init.sh
COPY init.sh /
RUN chmod +x /init.sh

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/init.sh"]
