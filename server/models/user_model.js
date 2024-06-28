// servidor/modelos/usuario.js
const pool = require('../db');
const fs = require('fs');
const path = require('path');
// Función para crear un nuevo usuarioconst crearUsuario = async ({ nombre_completo, correo_electronico, nombre_usuario, contrasena }) => {

const crearUsuario = async ({ nombre_completo, correo_electronico, nombre_usuario, contrasena }) => {
    const query = `
        INSERT INTO usuarios (nombre_completo, correo_electronico, nombre_usuario, contrasena)
        VALUES ($1, $2, $3, $4)
        RETURNING *;
    `;
    const values = [nombre_completo, correo_electronico, nombre_usuario, contrasena];
    
    try {
        // Ejecutar la consulta SQL
        const result = await pool.query(query, values);
        
        // Log de depuración para verificar si la inserción fue exitosa
        console.log('Usuario insertado correctamente:', result.rows[0]);

        // Devolver el resultado de la consulta
        return result.rows[0];
    } catch (error) {
        // Manejar cualquier error que ocurra durante la inserción
        console.error('Error al insertar usuario:', error);
        throw error;
    }
};

// Función para buscar un usuario por correo electrónico
const buscarUsuarioPorCorreo = async (correo_electronico) => {
    const query = `
        SELECT * FROM usuarios
        WHERE correo_electronico = $1;
    `;
    const values = [correo_electronico];
    const result = await pool.query(query, values);
    return result.rows[0];
};

// Función para buscar un usuario por nombre de usuario
const buscarUsuarioPorNombreUsuario = async (nombre_usuario) => {
    const query = `
        SELECT * FROM usuarios
        WHERE nombre_usuario = $1;
    `;
    const values = [nombre_usuario];
    const result = await pool.query(query, values);
    return result.rows[0];
};
// Function to create a new Abogado (lawyer)
const nuevoAbogado = async (userData) => {
    const { nombre, email, telefono, cv_path, consent } = userData;
    
    const query = `
      INSERT INTO job_applications (nombre, email, telefono, cv_path, consent)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    
    const values = [nombre, email, telefono, cv_path, consent];
    
    const result = await pool.query(query, values);
    return result.rows[0];
  };

module.exports = {
    crearUsuario,
    buscarUsuarioPorCorreo,
    buscarUsuarioPorNombreUsuario,
    nuevoAbogado,
};