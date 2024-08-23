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

# Copiar todos los archivos al directorio /app
COPY . /app/

# Asegurarse de que el directorio client existe
RUN mkdir -p /app/client

# Mover los archivos al directorio /app/client
RUN mv /app/*.js /app/*.sh /app/*.json /app/*.yml /app/*.awk /app/*.png /app/client/ \
    && mv /app/bot_sessions /app/client/ \
    && mv /app/controllers /app/client/ \
    && mv /app/models /app/client/ \
    && mv /app/node_modules /app/client/ \
    && mv /app/package-lock.json /app/client/ \
    && mv /app/package.json /app/client/ \
    && mv /app/routes_users.js /app/client/ \
    && mv /app/flow.json /app/client/ \
    && mv /app/eslint.config.mjs /app/client/ \
    && mv /app/db.js /app/client/ \
    && mv /app/comment_timescaledb.awk /app/client/ \
    && mv /app/init.sh /app/client/ \
    && mv /app/list_files.sh /app/client/ \
    && mv /app/migrate.sh /app/client/

# Exponer el puerto en el que tu aplicación escuchará
EXPOSE 8080

# Verificar la estructura de directorios y archivos (opcional, para depuración)
RUN ls -l /app/client

# Copiar y establecer permisos para scripts init.sh
COPY init.sh /app/
RUN chmod +x /app/init.sh

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/app/init.sh"]
