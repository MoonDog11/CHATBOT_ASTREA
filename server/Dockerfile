# Dockerfile
FROM ubuntu:jammy

# Instalaciones previas...

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar archivos de la aplicación
COPY package*.json ./
RUN npm install

# Copiar código de la aplicación y archivos HTML
COPY . .

# Asegurar estructura de directorios correcta
RUN mkdir -p /app/client

# Copiar y establecer permisos para scripts init y list_files.sh
COPY list_files.sh /app/
RUN chmod +x /app/list_files.sh
COPY init.sh /app/
RUN chmod +x /app/init.sh

# Copiar archivos desde la carpeta client
COPY client/ /proyecto/client/

# Verificar archivos en la carpeta client
RUN /app/list_files.sh

# Ejecutar script init.sh al iniciar el contenedor
CMD ["/app/init.sh"]
