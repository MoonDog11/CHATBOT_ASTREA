// db.js
require('dotenv').config();
const { Pool } = require('pg');

// Configuración del Pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false // Habilita SSL solo si se usa DATABASE_URL
});

// Exporta el pool para que pueda ser usado en otros archivos
module.exports = { pool };
