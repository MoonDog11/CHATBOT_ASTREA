const { Pool } = require('pg');
require('dotenv').config();

// Configurar la conexión a la base de datos
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  connectionString: process.env.URL_DATABASE // Usar 'connectionString' en lugar de 'url'
});

// Agregar un console.log para verificar la conexión
pool.connect((err, client, release) => {
  if (err) {
    console.error('Error al conectar a la base de datos:', err.message);
    return;
  }
  console.log('Conexión exitosa a la base de datos');
  console.log('Usuario conectado:', client.user); // Añade el usuario conectado
  console.log('Versión del servidor PostgreSQL:', client.serverVersion); // Añade la versión del servidor
  release();
});

module.exports = pool;
