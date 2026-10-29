const { revenueCatWebhookSecret } = require('../config/env');
const HttpError = require('../utils/http-error');
const sameSecret = require('../utils/same-secret');

/**
 * RevenueCat sends the Authorization header value set on the webhook as-is.
 * Accept it with or without a "Bearer " prefix, whichever was typed there.
 * Without a secret configured, the webhook doesn't exist.
 */
const revenueCatWebhookAuth = (req, res, next) => {
  if (!revenueCatWebhookSecret) {
    return next(new HttpError(404, `Route not found: ${req.method} ${req.originalUrl}`));
  }
  const given = (req.get('authorization') || '').replace(/^Bearer\s+/i, '');
  const expected = revenueCatWebhookSecret.replace(/^Bearer\s+/i, '');
  if (!sameSecret(given, expected)) return next(new HttpError(401, 'Invalid webhook secret'));
  next();
};

module.exports = { revenueCatWebhookAuth };
