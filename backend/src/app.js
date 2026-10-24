const path = require('path');
const express = require('express');
const cors = require('cors');
const { corsOrigin } = require('./config/env');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middlewares/error.middleware');

const app = express();

app.use(cors({ origin: corsOrigin }));
app.use(express.json());

// Dev-only asset hosting; production serves images from a CDN via ASSET_BASE_URL.
app.use('/static', express.static(path.join(__dirname, '..', 'public'), { maxAge: '7d' }));

// Root welcome & status info
app.get('/', (req, res) => {
  res.json({
    name: 'SoulVerse Backend API',
    status: 'online',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      dailyVerse: '/api/verses/daily',
      prayers: '/api/prayers',
      auth: '/api/auth',
    },
  });
});

// Root /health alias for hosting health checks.
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// The API lives only under /api (clients' API_BASE_URL ends with /api).
app.use('/api', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;

