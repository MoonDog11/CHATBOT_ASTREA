const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const path = require('path');
const multer = require('multer');
require('dotenv').config();
const FormData = require('form-data');
const fetch = require('node-fetch');
const fs = require('fs'); // Añadido para verificar archivos
const flows = require('./flow.json');

const usuariosRutas = require('./routes_users');
const { UsuarioAbogado } = require('./controllers/users_controllers');

const app = express();
const PORT = process.env.PORT || 8080;

// Configuración de multer para almacenar archivos en disco
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, 'uploads/'));
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage });

// Middleware
app.use(
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", 'http://localhost:3002'],
      styleSrc: ["'self'", "'unsafe-inline'", 'https://cdnjs.cloudflare.com'],
      imgSrc: ["'self'", 'data:', 'https://example.com'],
      frameSrc: ["http://localhost:3002"],
    },
  })
);
app.use(cors());
app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Servir archivos estáticos desde el directorio 'client' dentro de 'server'
app.use(express.static(path.join(__dirname, 'client')));

// Ruta para la página de inicio
app.get('/', (req, res) => {
  const landingFilePath = path.join(__dirname, 'client', 'landing.html');
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


// Endpoint para manejar la solicitud del formulario de contacto
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

// Rutas
app.use('/api', usuariosRutas);
app.post('/submit_registration', upload.single('cv'), UsuarioAbogado);


app.get('/bot/data', (req, res) => {
  res.json(flows);
});

// Inicia el servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});
