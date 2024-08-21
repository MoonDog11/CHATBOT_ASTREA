# Dockerfile
FROM ubuntu:jammy

# Instalar PostgreSQL cliente y otras dependencias
RUN apt-get update && \
    apt-get install -y gnupg wget && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-16 bash ncurses-bin curl && \
    rm -rf /var/lib/apt/lists/*

# Instalar Node.js (versión LTS 18.x)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar los archivos necesarios
COPY package*.json ./
RUN npm install

# Asegurarse de que se cree la estructura correcta del directorio
RUN mkdir -p /app/client

# Copiar el contenido de la carpeta client desde la ubicación externa
COPY ../client/ /app/client/

# Verificar los archivos copiados en el directorio client
RUN ls -la /app/client

# Copiar y establecer permisos para scripts init y migrate.sh
COPY list_files.sh /app/
RUN chmod +x /app/list_files.sh
COPY init.sh /app/
RUN chmod +x /app/init.sh

# Ejecutar lógica de init.sh al iniciar el contenedor
CMD ["/app/init.sh"]
