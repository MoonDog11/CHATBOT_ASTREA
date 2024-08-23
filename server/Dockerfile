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

# Copiar los archivos package.json y package-lock.json
COPY package*.json ./

# Instalar las dependencias de Node.js
RUN npm install

# Copiar el resto del código de la aplicación
COPY . .

# Asegurarse de que los directorios necesarios existan
RUN mkdir -p /app/client

# Mover archivos a /app/client si es necesario
RUN mv /app/*.js /app/*.sh /app/*.json /app/*.yml /app/*.awk /app/*.png /app/client/ || true

# Mover directorios a /app/client si existen
RUN [ -d /app/bot_sessions ] && mv /app/bot_sessions /app/client/ || true
RUN [ -d /app/controllers ] && mv /app/controllers /app/client/ || true
RUN [ -d /app/models ] && mv /app/models /app/client/ || true
RUN [ -d /app/node_modules ] && mv /app/node_modules /app/client/ || true

# Mover archivos restantes a /app/client
RUN [ -f /app/package-lock.json ] && mv /app/package-lock.json /app/client/ || true
RUN [ -f /app/package.json ] && mv /app/package.json /app/client/ || true
RUN [ -f /app/routes_users.js ] && mv /app/routes_users.js /app/client/ || true
RUN [ -f /app/flow.json ] && mv /app/flow.json /app/client/ || true
RUN [ -f /app/eslint.config.mjs ] && mv /app/eslint.config.mjs /app/client/ || true
RUN [ -f /app/db.js ] && mv /app/db.js /app/client/ || true
RUN [ -f /app/comment_timescaledb.awk ] && mv /app/comment_timescaledb.awk /app/client/ || true
RUN [ -f /app/init.sh ] && mv /app/init.sh /app/client/ || true
RUN [ -f /app/migrate.sh ] && mv /app/migrate.sh /app/client/ || true

# Asignar permisos a los scripts si existen
RUN [ -f /app/client/init.sh ] && chmod +x /app/client/init.sh || true
RUN [ -f /app/client/migrate.sh ] && chmod +x /app/client/migrate.sh || true

# Exponer el puerto en el que tu aplicación escuchará
EXPOSE 8080

# Verificar la estructura de directorios y archivos (opcional, para depuración)
RUN ls -l /app/client

# Ejecutar el script init.sh al iniciar el contenedor
CMD ["/app/client/init.sh"]
