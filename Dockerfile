FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

COPY list_files.sh /app/
RUN chmod +x /app/list_files.sh
RUN /app/list_files.sh

COPY init.sh /app/
RUN chmod +x /app/init.sh

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl --fail http://localhost:8080/ || exit 1

ENTRYPOINT ["/app/init.sh"]
