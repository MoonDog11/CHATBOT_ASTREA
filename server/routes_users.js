// servidor/rutas/usuarios.js
const express = require('express');
const router = express.Router();
const { registrarUsuario, autenticarUsuario,UsuarioAbogado } = require('./controllers/users_controllers');

// Ruta para registrar un nuevo usuario
router.post('/registro', registrarUsuario);

// Ruta para autenticar un usuario
router.post('/login', autenticarUsuario);

router.post('/submit_registration', UsuarioAbogado);

module.exports = router;
