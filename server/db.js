const { Pool } = require('pg');
const fs = require('fs');
const { exec } = require('child_process');
require('dotenv').config();

// Configurar la conexión a la base de datos de origen
const sourcePool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Configurar la conexión a la base de datos de destino
const destinationPool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Verificar la conexión
const verifyConnection = async (pool) => {
  try {
    const client = await pool.connect();
    console.log('Conexión exitosa a la base de datos');
    const res = await client.query('SELECT version()');
    console.log('Versión del servidor PostgreSQL:', res.rows[0].version);
    client.release();
  } catch (err) {
    console.error('Error al conectar a la base de datos:', err.message);
    process.exit(1);
  }
};

// Verificar si la variable DATABASE_URL está configurada
const checkDatabaseUrl = () => {
  const urlDatabase = process.env.DATABASE_URL;
  if (urlDatabase) {
    console.log(`DATABASE_URL configurada correctamente: ${urlDatabase}`);
  } else {
    console.log('DATABASE_URL no está configurada correctamente o está vacía.');
  }
};

// Volcar la base de datos
const dumpDatabase = async (databaseName, dumpFile) => {
  return new Promise((resolve, reject) => {
    const dumpCommand = `pg_dump -d postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT}/${databaseName} --format=plain --quote-all-identifiers --no-tablespaces --no-owner --no-privileges --disable-triggers --file=${dumpFile}`;
    exec(dumpCommand, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error al volcar la base de datos: ${stderr}`);
        reject(error);
      } else {
        console.log(`Volcado de la base de datos completado en ${dumpFile}`);
        resolve();
      }
    });
  });
};

// Restaurar la base de datos
const restoreDatabase = async (databaseName, dumpFile) => {
  return new Promise((resolve, reject) => {
    const restoreCommand = `psql ${process.env.DATABASE_URL} -f ${dumpFile}`;
    exec(restoreCommand, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error al restaurar la base de datos: ${stderr}`);
        reject(error);
      } else {
        console.log(`Restauración de la base de datos completada desde ${dumpFile}`);
        resolve();
      }
    });
  });
};

// Función principal
const main = async () => {
  // Verificar conexiones
  await verifyConnection(sourcePool);
  await verifyConnection(destinationPool);

  // Verificar la configuración de DATABASE_URL
  checkDatabaseUrl();

  // Volcar y restaurar la base de datos
  const dumpFile = 'database_dump.sql';
  await dumpDatabase(process.env.DB_DATABASE, dumpFile);
  await restoreDatabase(process.env.DB_DATABASE, dumpFile);

  console.log('Migración completada con éxito.');
  fs.unlinkSync(dumpFile); // Limpiar el archivo de volcado
  process.exit(0);
};

// Ejecutar la función principal
main().catch((err) => {
  console.error('Error en la migración:', err.message);
  process.exit(1);
});
