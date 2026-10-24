const { Pool } = require('pg');
require('dotenv').config({ quiet: true });

const connectionString = process.env.DATABASE_URL;

// Hosted Postgres (Neon) needs SSL; a local development database usually has none.
const isLocal = /@(localhost|127\.0\.0\.1)[:/]/.test(connectionString || '');

const pool = new Pool({
  connectionString,
  ssl: isLocal ? false : { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 30000,
});

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
