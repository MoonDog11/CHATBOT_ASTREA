const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { crearUsuario, buscarUsuarioPorCorreo, buscarUsuarioPorNombreUsuario,nuevoAbogado} = require('../models/user_model'); // Asegúrate de importar las funciones adecuadas desde tu modelo


const JWT_SECRET = process.env.JWT_SECRET; // Define tu clave secreta para JWT


const SALT_ROUNDS = 10; // Número de rondas de sal para bcrypt

async function registrarUsuario(req, res) {
    console.log('Solicitud de registro recibida:', req.body);

    // Extraer los datos del cuerpo de la solicitud
    const { fullname, email, username, password, confirm_password } = req.body;

    // Verificar si las contraseñas coinciden
    if (password !== confirm_password) {
        return res.status(400).json({ message: 'Las contraseñas no coinciden' });
    }

    try {
        // Verificar si el correo electrónico o nombre de usuario ya existen en la base de datos
        const usuarioExistenteCorreo = await buscarUsuarioPorCorreo(email);
        const usuarioExistenteNombre = await buscarUsuarioPorNombreUsuario(username);

        if (usuarioExistenteCorreo || usuarioExistenteNombre) {
            return res.status(400).json({ message: 'El correo electrónico o nombre de usuario ya existe' });
        }

        console.log('Contraseña a hashear:', password);

        // Hashear la contraseña antes de almacenarla
        const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

        // Crear nuevo usuario en la base de datos
        const nuevoUsuario = await crearUsuario({ nombre_completo: fullname, correo_electronico: email, nombre_usuario: username, contrasena: hashedPassword });

        console.log('Nuevo usuario creado:', nuevoUsuario);

        // Redirigir al usuario al landing o responder con éxito
        res.redirect('/landing.html');
    } catch (error) {
        console.error('Error al crear usuario:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
}

// Controlador para autenticar un usuario
async function autenticarUsuario(req, res) {
    const { nombre_usuario, contrasena } = req.body;

    try {
        // Buscar usuario por nombre de usuario
        const usuario = await buscarUsuarioPorNombreUsuario(nombre_usuario);
        if (!usuario) {
            return res.status(401).json({ message: 'Usuario o contraseña incorrectos' });
        }

        // Comparar la contraseña
        const isMatch = await bcrypt.compare(contrasena, usuario.contrasena);
        if (!isMatch) {
            return res.status(401).json({ message: 'Usuario o contraseña incorrectos' });
        }

        // Crear el token JWT
        const token = jwt.sign({ id: usuario.id, nombre_usuario: usuario.nombre_usuario }, JWT_SECRET, { expiresIn: '1h' });

        // Redirigir al usuario al home con el token JWT
        console.log('Autenticación exitosa. Token generado:', token); // Mensaje de depuración
        res.redirect(`/home.html?token=${token}`);
    } catch (error) {
        console.error('Error al autenticar usuario:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
}

const UsuarioAbogado = async (req, res) => {
    try {
        console.log('Body:', req.body);
        console.log('File:', req.file);
        console.log('Headers:', req.headers);
    
        const { nombre, email, telefono, consent } = req.body;
    
        console.log('Nombre:', nombre);
        console.log('Email:', email);
        console.log('Teléfono:', telefono);
        console.log('Consent:', consent);
  
      // Validación de campos
      if (!nombre || !email || !telefono || !consent) {
        return res.status(400).json({ error: 'Todos los campos son obligatorios' });
      }
  
      if (!req.file) {
        return res.status(400).json({ error: 'El archivo CV es obligatorio' });
      }
  
      const cvPath = req.file.path;
  
      // Llamada a la función nuevoAbogado con todos los campos
      const result = await nuevoAbogado({
        nombre,
        email,
        telefono,
        cv_path: cvPath,
        consent: consent === 'on' || consent === 'true',
      });
  
      res.status(201).json({ message: 'Abogado registrado exitosamente', data: result });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  

module.exports = {
    registrarUsuario,
    autenticarUsuario,
    UsuarioAbogado,
};
