const { verifyAccessToken } = require('../utils/token');
const userService = require('../services/user.service');
const HttpError = require('../utils/http-error');

const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new HttpError(401, 'Missing or invalid Authorization header'));
  }

  const token = authHeader.slice(7).trim();
  try {
    const decoded = verifyAccessToken(token);
    const user = await userService.findById(decoded.sub);
    if (!user) {
      return next(new HttpError(401, 'User no longer exists'));
    }
    req.user = user;
    next();
  } catch (err) {
    if (err instanceof HttpError) return next(err);
    next(new HttpError(401, 'Invalid or expired access token'));
  }
};

const optionalAuthMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.slice(7).trim();
  try {
    const decoded = verifyAccessToken(token);
    const user = await userService.findById(decoded.sub);
    if (user) {
      req.user = user;
    }
  } catch (_) {
    // Optional auth silently ignores invalid tokens and proceeds as guest
  }
  next();
};

module.exports = {
  authMiddleware,
  optionalAuthMiddleware,
};

