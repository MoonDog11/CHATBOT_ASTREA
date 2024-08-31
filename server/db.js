// db.js
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

const testQuery = async () => {
  try {
    const res = await pool.query('SELECT NOW()');
    console.log('Hora actual en la base de datos:', res.rows[0].now);
  } catch (err) {
    console.error('Error en la consulta de prueba:', err);
  }
};

testQuery();

module.exports = { pool };
