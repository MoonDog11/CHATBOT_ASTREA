# Copiar el script init.sh al contenedor
COPY init.sh /app/
# Dar permisos de ejecución
RUN chmod +x /app/init.sh
# Establecer el punto de entrada
ENTRYPOINT ["/app/init.sh"]
