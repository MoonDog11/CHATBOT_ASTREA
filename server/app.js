const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const path = require('path');
const multer = require('multer');
require('dotenv').config();
const upload = multer({ dest: 'uploads/' });

const usuariosRutas = require('./routes/routes_users');
const { UsuarioAbogado } = require('./controllers/users_controllers');

const app = express();
const PORT = process.env.PORT || 3001;

// Configuración de multer para almacenar archivos en disco
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, 'uploads/')) // Asegúrate de que este directorio exista
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname)
  }
});



// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Servir archivos estáticos
app.use(express.static(path.join(__dirname, 'assets')));
app.use(express.static(path.join(__dirname, '../client')));

// Rutas
app.use('/api', usuariosRutas);
app.post('/submit_registration', upload.single('cv'), UsuarioAbogado);

// Ruta para la página de inicio
app.get('/', (req, res) => {
  const landingFilePath = path.join(__dirname, '../client/landing.html');
  res.sendFile(landingFilePath);
});

// Manejo de errores
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Algo salió mal!');
});

// Iniciar el servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});