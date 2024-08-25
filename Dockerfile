# Utiliza la imagen base de Node.js versión 18
FROM node:18

# Instala herramientas necesarias y añade el repositorio de PostgreSQL
RUN apt-get update && \
    apt-get install -y gnupg wget && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia los archivos necesarios para la aplicación (package.json y package-lock.json)
COPY package*.json ./

# Instala las dependencias de Node.js
RUN npm install

# Copia todo el código de la aplicación al directorio /app/server en el contenedor
COPY server ./server

# Asegura que se cree la estructura de directorios correcta, en este caso /client
RUN mkdir -p /client

# Copia y establece permisos para el script init.sh
COPY init.sh /
RUN chmod +x /init.sh

# Expone el puerto en el que la aplicación escuchará (puerto 8080)
EXPOSE 8080

# Configura el HEALTHCHECK para verificar la salud de la aplicación
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl --fail http://localhost:8080/ || exit 1

# Ejecuta el script init.sh al iniciar el contenedor
CMD ["/init.sh"]
