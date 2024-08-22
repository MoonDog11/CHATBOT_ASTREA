# Usa una imagen base de Ubuntu
FROM ubuntu:jammy

# Instalaciones previas y configuraciones necesarias
RUN apt-get update && \
    apt-get install -y gnupg wget curl bash ncurses-bin && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-16 && \
    rm -rf /var/lib/apt/lists/*

# Instalar Node.js (versión LTS 18.x)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar los archivos necesarios para la aplicación desde el directorio `server`
COPY server/package*.json ./
RUN npm install

# Copiar el código de la aplicación desde el directorio `server`
COPY server/ /app/server/

# Copiar los archivos desde el directorio `client` al contenedor
# Nota: Asume que el contexto de construcción es el directorio raíz del proyecto
COPY client/ /app/client/

# Verificar que los archivos se han copiado correctamente
RUN ls -l /app
RUN ls -l /app/server
RUN ls -l /app/client

# Copiar y establecer permisos para el script init.sh
COPY server/init.sh /app/
RUN chmod +x /app/init.sh

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/app/init.sh"]
