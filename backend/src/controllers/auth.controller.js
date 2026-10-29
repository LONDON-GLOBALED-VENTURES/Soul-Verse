const googleAuthService = require('../services/google-auth.service');
const userService = require('../services/user.service');
const accountService = require('../services/account.service');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/token');
const HttpError = require('../utils/http-error');

const googleAuth = async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) {
    throw new HttpError(400, 'idToken is required');
  }

  const profile = await googleAuthService.verifyGoogleToken(idToken);
  const user = await userService.findOrCreateFromGoogle(profile);

  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);

  res.json({
    user,
    accessToken,
    refreshToken,
  });
};

const refresh = async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    throw new HttpError(400, 'refreshToken is required');
  }

  try {
    const decoded = verifyRefreshToken(refreshToken);
    const user = await userService.findById(decoded.sub);
    if (!user) {
      throw new HttpError(401, 'User no longer exists');
    }

    const accessToken = signAccessToken(user);
    res.json({ accessToken });
  } catch (err) {
    if (err instanceof HttpError) throw err;
    throw new HttpError(401, 'Invalid or expired refresh token');
  }
};

const getMe = async (req, res) => {
  res.json({ user: req.user });
};

const deleteMe = async (req, res) => {
  await accountService.deleteAccount(req.user.id);
  res.status(204).end();
};

module.exports = {
  googleAuth,
  refresh,
  getMe,
  deleteMe,
};

