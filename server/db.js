// db.js
require('dotenv').config();
const { Pool } = require('pg');

// Configuración del Pool
const pool = new Pool({
  user: process.env.DB_USER || undefined,
  host: process.env.DB_HOST || undefined,
  database: process.env.DB_DATABASE || undefined,
  password: process.env.DB_PASSWORD || undefined,
  port: process.env.DB_PORT || undefined,
  connectionString: process.env.DATABASE_URL || undefined, // Prioriza DATABASE_URL si está presente
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false // Habilita SSL solo si se usa DATABASE_URL
});

// Función para verificar la conexión y consultar la versión del servidor
const checkConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('Conexión exitosa a la base de datos');
    console.log('Usuario conectado:', client.user); // Añade el usuario conectado
    console.log('Versión del servidor PostgreSQL:', client.serverVersion); // Añade la versión del servidor
    client.release();

    const { rows } = await pool.query('SELECT version()');
    console.log('Versión del servidor PostgreSQL:', rows[0].version);

  } catch (err) {
    console.error('Error al conectar a la base de datos:', err.message);
  } finally {
    await pool.end();
  }
};

// Verificar si la variable DATABASE_URL está configurada
const urlDatabase = process.env.DATABASE_URL;

if (urlDatabase) {
  console.log(`DATABASE_URL configurada correctamente: ${urlDatabase}`);
} else {
  console.log('DATABASE_URL no está configurada correctamente o está vacía.');
}

// Ejecutar la verificación de conexión
checkConnection();
