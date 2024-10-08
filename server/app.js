const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const path = require('path');
const multer = require('multer');
const FormData = require('form-data');
const fs = require('fs'); // Añadido para verificar archivos
const bcrypt = require('bcryptjs'); // Asegúrate de que `bcrypt` esté instalado
const { Pool } = require('pg'); // Paquete para PostgreSQL
const flows = require('./flow.json');
const usuariosRutas = require('./routes_users');
const { UsuarioAbogado } = require('./controllers/users_controllers');

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
pool.query('SELECT current_database();')
    .then(res => console.log('Base de datos conectada:', res.rows[0].current_database))
    .catch(err => console.error('Error al verificar la base de datos:', err));
const app = express();
const PORT = process.env.PORT || 3001;

// Configuración de multer para almacenar archivos en disco
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, 'uploads')); // Ajusta el destino aquí
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage });

// Configuración de middlewares
app.use(
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", 'https://chatbot-react-astrea-production.up.railway.app/'],
      styleSrc: ["'self'", "'unsafe-inline'", 'https://cdnjs.cloudflare.com'],
      imgSrc: ["'self'", 'data:', 'https://example.com'],
      frameSrc: ["https://chatbot-react-astrea-production.up.railway.app/"],
    },
  })
);
app.use(cors());
app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Ruta del directorio 'client', que está un nivel arriba del directorio 'server'
const clientPath = path.join(__dirname, '..', 'client');

console.log('Ruta absoluta del directorio client:', clientPath);

// Configurar Express para servir archivos estáticos desde el directorio '/client'
app.use(express.static(clientPath));

app.get('/', (req, res) => {
  // Ruta del archivo 'landing.html' dentro del directorio '/client'
  const landingFilePath = path.join(clientPath, 'landing.html');
  console.log('Ruta absoluta del archivo landing.html:', landingFilePath);

  fs.access(landingFilePath, fs.constants.F_OK, (err) => {
    if (err) {
      console.error('Error al encontrar el archivo:', err);
      res.status(404).send('Archivo no encontrado');
    } else {
      res.sendFile(landingFilePath, (err) => {
        if (err) {
          console.error('Error al enviar el archivo:', err);
          res.status(500).send('Error al enviar el archivo');
        }
      });
    }
  });
});

// Ruta para manejar la solicitud del formulario de contacto
app.post('/sendContactForm', async (req, res) => {
  const form = new FormData();
  form.append('name', req.body.name);
  form.append('email', req.body.email);
  form.append('message', req.body.message);

  try {
    const response = await fetch('https://formspree.io/f/xvgpogpl', {
      method: 'POST',
      body: form,
      headers: {
        ...form.getHeaders(),
        'Accept': 'application/json',
      }
    });
    const result = await response.json();
    res.json(result);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Hubo un error al enviar el mensaje' });
  }
});

// Ruta para registrar un nuevo usuario
app.post('/register', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Por favor, proporciona un nombre de usuario y una contraseña.' });
  }

  try {
    // Cifra la contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Inserta el nuevo usuario en la base de datos
    const query = 'INSERT INTO public."usuarios" (nombre_usuario, contrasena) VALUES ($1, $2) RETURNING id';
    const values = [username, hashedPassword];
    const result = await pool.query(query, values);

    res.status(201).json({ message: 'Usuario registrado exitosamente.', userId: result.rows[0].id });
  } catch (error) {
    console.error('Error al registrar el usuario:', error);
    res.status(500).json({ error: 'Hubo un error al registrar el usuario.' });
  }
});

// Rutas API
app.use('/api', usuariosRutas);

// Endpoint para manejar el registro de abogados
app.post('/submit_registration', upload.single('cv'), UsuarioAbogado);

// Endpoint para obtener datos del bot
app.get('/bot/data', (req, res) => {
  res.json(flows);
});

// Inicia el servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});
