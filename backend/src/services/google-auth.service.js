const { OAuth2Client } = require('google-auth-library');
const { googleClientId, nodeEnv } = require('../config/env');
const HttpError = require('../utils/http-error');

const client = new OAuth2Client(googleClientId || undefined);

/**
 * Verifies a Google ID token and returns verified profile details.
 *
 * In tests or development, tokens starting with "mock-google-token:"
 * are decoded locally to allow automated testing without hitting Google servers.
 */
const verifyGoogleToken = async (idToken) => {
  if (!idToken) {
    throw new HttpError(400, 'idToken is required');
  }

  // Test / dev bypass for local and automated testing
  if (idToken.startsWith('mock-google-token:') && (nodeEnv === 'test' || nodeEnv === 'development')) {
    const parts = idToken.split(':');
    const email = parts[1] || 'testuser@gmail.com';
    const name = parts[2] || 'Test User';
    const googleId = parts[3] || `google_${Buffer.from(email).toString('hex')}`;
    return {
      googleId,
      email,
      emailVerified: true,
      name,
      avatarUrl: `https://lh3.googleusercontent.com/a/mock-${googleId}`,
    };
  }

  if (!googleClientId) {
    throw new HttpError(500, 'GOOGLE_CLIENT_ID is not configured on the server');
  }

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: googleClientId,
    });
    const payload = ticket.getPayload();

    if (!payload) {
      throw new HttpError(401, 'Invalid Google ID token');
    }

    if (!payload.email_verified) {
      throw new HttpError(403, 'Google account email is not verified');
    }

    return {
      googleId: payload.sub,
      email: payload.email.toLowerCase(),
      emailVerified: true,
      name: payload.name || '',
      avatarUrl: payload.picture || '',
    };
  } catch (error) {
    if (error instanceof HttpError) throw error;
    throw new HttpError(401, `Google token verification failed: ${error.message}`);
  }
};

module.exports = {
  verifyGoogleToken,
};

