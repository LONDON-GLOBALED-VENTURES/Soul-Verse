require('dotenv').config({ quiet: true });

// Unset means production: a server deployed without NODE_ENV must get the safe behaviour.
const nodeEnv = process.env.NODE_ENV || 'production';
const isProduction = nodeEnv !== 'development' && nodeEnv !== 'test';

const PLACEHOLDER_SECRETS = new Set([
  'your-random-32-character-secret-key',
  'your-random-32-character-refresh-secret-key',
]);

const DEV_SECRETS = {
  JWT_SECRET: 'soulverse-dev-only-access-secret-not-for-production',
  JWT_REFRESH_SECRET: 'soulverse-dev-only-refresh-secret-not-for-production',
};

const readSecret = (name) => {
  const value = process.env[name];
  if (isProduction) {
    if (!value || value.length < 32 || PLACEHOLDER_SECRETS.has(value)) {
      throw new Error(
        `${name} must be set to a random value of at least 32 characters in production.`,
      );
    }
    return value;
  }
  if (!value && nodeEnv === 'development') {
    console.warn(`⚠️  ${name} is not set; using an insecure development-only secret.`);
  }
  return value || DEV_SECRETS[name];
};

const jwtSecret = readSecret('JWT_SECRET');
const jwtRefreshSecret = readSecret('JWT_REFRESH_SECRET');
if (isProduction && jwtSecret === jwtRefreshSecret) {
  throw new Error('JWT_SECRET and JWT_REFRESH_SECRET must be different.');
}

module.exports = {
  nodeEnv,
  isProduction,
  port: Number(process.env.PORT) || 3000,
  corsOrigin: process.env.CORS_ORIGIN || '*',
  assetBaseUrl: process.env.ASSET_BASE_URL?.replace(/\/+$/, '') || '',
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
  // Shown on the public account-deletion page.
  supportEmail: process.env.SUPPORT_EMAIL || 'support@example.com',
  jwtSecret,
  jwtRefreshSecret,
  // Fake "mock-google-token:" sign-ins: always in tests, in development only on request.
  allowMockGoogleAuth:
    nodeEnv === 'test' ||
    (nodeEnv === 'development' && process.env.ALLOW_MOCK_GOOGLE_AUTH === 'true'),
};
