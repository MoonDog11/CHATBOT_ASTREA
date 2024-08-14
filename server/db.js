const { Pool } = require('pg');
require('dotenv').config();

// Configurar la conexión a la base de datos
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Agregar un console.log para verificar la conexión
pool.connect((err, client, release) => {
  if (err) {
    return console.error('Error al conectar a la base de datos:', err.message);
  }
  console.log('Conexión exitosa a la base de datos');
  release();
});

module.exports = pool;
