const { Pool } = require('pg');
require('dotenv').config();

// Configuración del Pool de PostgreSQL
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

// Función para crear un nuevo usuario
const crearUsuario = async ({ nombre_completo, correo_electronico, nombre_usuario, contrasena }) => {
    const query = `
        INSERT INTO public."usuarios" (nombre_completo, correo_electronico, nombre_usuario, contrasena)
        VALUES ($1, $2, $3, $4)
        RETURNING *;
    `;
    const values = [nombre_completo, correo_electronico, nombre_usuario, contrasena];
    
    try {
        console.log('Ejecutando consulta para crear usuario:', query, values); // Log de la consulta
        const result = await pool.query(query, values);
        console.log('Usuario insertado correctamente:', result.rows[0]);
        return result.rows[0];
    } catch (error) {
        console.error('Error al insertar usuario:', error);
        throw error;
    }
};

// Función para buscar un usuario por nombre de usuario
const buscarUsuarioPorNombreUsuario = async (nombre_usuario) => {
    const query = `
        SELECT * FROM public.usuarios
        WHERE LOWER(nombre_usuario) = LOWER($1);
    `;
    const values = [nombre_usuario];
    
    try {
        console.log('Ejecutando consulta SQL:');
        console.log('Consulta:', query);
        console.log('Valores:', values);

        const result = await pool.query(query, values);

        console.log('Resultado de la consulta:', result.rows);

        return result.rows[0];
    } catch (error) {
        console.error('Error al buscar usuario por nombre de usuario:');
        console.error('Consulta SQL:', query);
        console.error('Valores:', values);
        console.error('Detalles del error:', error.message);
        console.error('Stack del error:', error.stack);
        throw error;
    }
};

// Función para buscar un usuario por correo electrónico
const buscarUsuarioPorCorreo = async (correo_electronico) => {
    const query = `
        SELECT * FROM public."usuarios"
        WHERE correo_electronico = $1;
    `;
    const values = [correo_electronico];
    try {
        const result = await pool.query(query, values);
        return result.rows[0];
    } catch (error) {
        console.error('Error al buscar usuario por correo:', error);
        throw error;
    }
};

// Función para crear un nuevo Abogado (lawyer)
const nuevoAbogado = async (userData) => {
    const { nombre, email, telefono, cv_path, consent } = userData;
    
    const query = `
      INSERT INTO public."job_applications" (nombre, email, telefono, cv_path, consent)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    
    const values = [nombre, email, telefono, cv_path, consent];
    
    try {
        const result = await pool.query(query, values);
        return result.rows[0];
    } catch (error) {
        console.error('Error al crear nuevo abogado:', error);
        throw error;
    }
};

module.exports = {
    crearUsuario,
    buscarUsuarioPorCorreo,
    buscarUsuarioPorNombreUsuario,
    nuevoAbogado,
};
