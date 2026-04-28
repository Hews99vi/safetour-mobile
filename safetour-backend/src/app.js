const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const apiRateLimiter = require('./middleware/rateLimiter');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth');
const alertsRoutes = require('./routes/alerts');
const sosRoutes = require('./routes/sos');
const chatRoutes = require('./routes/chat');
const locationsRoutes = require('./routes/locations');

const app = express();

app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'safetour-backend' });
});

app.use('/api', apiRateLimiter);
app.use('/api/auth', authRoutes);
app.use('/api/alerts', alertsRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/locations', locationsRoutes);

app.use(errorHandler);

module.exports = app;
