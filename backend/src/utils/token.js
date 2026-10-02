const jwt = require('jsonwebtoken');
const { jwtSecret, jwtRefreshSecret } = require('../config/env');

const signAccessToken = (user) => {
  return jwt.sign(
    { sub: user.id, email: user.email },
    jwtSecret,
    { expiresIn: '1h' },
  );
};

const signRefreshToken = (user) => {
  return jwt.sign(
    { sub: user.id },
    jwtRefreshSecret,
    { expiresIn: '30d' },
  );
};

const verifyAccessToken = (token) => {
  return jwt.verify(token, jwtSecret);
};

const verifyRefreshToken = (token) => {
  return jwt.verify(token, jwtRefreshSecret);
};

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};

