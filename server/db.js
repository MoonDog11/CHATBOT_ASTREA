require('dotenv').config();
const { Pool } = require('pg');

// Configuración del Pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false // Habilita SSL solo si se usa DATABASE_URL
});

// Función para verificar la conexión y consultar la versión del servidor
const checkConnection = async () => {
  let client;
  try {
    client = await pool.connect();
    console.log('Conexión exitosa a la base de datos');
    
    // Consultar la versión del servidor PostgreSQL
    const { rows } = await client.query('SELECT version()');
    console.log('Versión del servidor PostgreSQL:', rows[0].version);

    // Consultar el nombre de la base de datos
    const { rows: dbNameRows } = await client.query('SELECT current_database();');
    console.log('Base de datos conectada:', dbNameRows[0].current_database);

  } catch (err) {
    console.error('Error al conectar a la base de datos:', err.message);
  } finally {
    // Liberar el cliente
    if (client) client.release();
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

// Exportar el pool para su uso en otras partes de la aplicación
module.exports = pool;
