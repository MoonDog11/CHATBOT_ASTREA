require('dotenv').config();
const { Pool } = require('pg');

// Configuración del Pool
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false // Habilita SSL solo si se usa DATABASE_URL
});

module.exports = { pool };  // Asegúrate de exportar `pool`
