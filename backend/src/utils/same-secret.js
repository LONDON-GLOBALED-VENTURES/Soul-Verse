const crypto = require('crypto');

/** Compares two secrets in constant time, so timing doesn't reveal how much matched. */
const sameSecret = (given, expected) => {
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
};

module.exports = sameSecret;
