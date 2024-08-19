const { Pool } = require('pg');
require('dotenv').config();

// Configurar la conexión a la base de datos usando DATABASE_URL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false // Añadido para permitir conexiones seguras
  }
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

const urlDatabase = process.env.DATABASE_URL; // Usa DATABASE_URL aquí

// Verificar si la variable está configurada y tiene un valor
if (urlDatabase) {
  console.log(`DATABASE_URL configurada correctamente: ${urlDatabase}`);
} else {
  console.log('DATABASE_URL no está configurada correctamente o está vacía.');
}

module.exports = pool;
