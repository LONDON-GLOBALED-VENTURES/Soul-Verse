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

app.use('/api', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
