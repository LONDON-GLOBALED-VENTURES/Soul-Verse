require('dotenv').config({ quiet: true });

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT) || 3000,
  corsOrigin: process.env.CORS_ORIGIN || '*',
  assetBaseUrl: process.env.ASSET_BASE_URL?.replace(/\/+$/, '') || '',
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
  jwtSecret: process.env.JWT_SECRET || 'soulverse-dev-jwt-secret-key-32chars!!',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'soulverse-dev-refresh-secret-key-32chars!!',
};
