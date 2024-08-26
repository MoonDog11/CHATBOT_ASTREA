# Utilizar la imagen base de Node.js versión 18
FROM node:18

# Instalar dependencias para PostgreSQL
RUN apt-get update && \
    apt-get install -y gnupg wget && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update
RUN apt-get install -y postgresql-client-16

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /

# Copiar los archivos necesarios para la aplicación
COPY package*.json ./

# Instalación de dependencias Node.js
RUN npm install

# Copiar todo el código de la aplicación
COPY . .

# Copiar y establecer permisos para el script init.sh
COPY init.sh /
RUN chmod +x /init.sh

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/init.sh"]
