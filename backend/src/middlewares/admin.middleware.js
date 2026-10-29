const crypto = require('crypto');
const { adminApiKey } = require('../config/env');
const HttpError = require('../utils/http-error');

const sameSecret = (given, expected) => {
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
};

/**
 * Moderator-only routes: the request must send the ADMIN_API_KEY in the
 * X-Admin-Key header. Without a key configured, these routes don't exist.
 */
const adminMiddleware = (req, res, next) => {
  if (!adminApiKey) return next(new HttpError(404, `Route not found: ${req.method} ${req.originalUrl}`));
  const given = req.get('x-admin-key') || '';
  if (!sameSecret(given, adminApiKey)) return next(new HttpError(401, 'Invalid admin key'));
  next();
};

module.exports = { adminMiddleware };
