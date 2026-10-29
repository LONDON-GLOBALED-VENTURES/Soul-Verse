const userService = require('./user.service');
const prayerService = require('./prayer.service');

const isDbActive = () => Boolean(process.env.DATABASE_URL && process.env.NODE_ENV !== 'test');

/**
 * Permanently deletes a user's account and everything they created: their
 * profile, their prayers and the likes they gave. False if there was no such user.
 */
const deleteAccount = async (userId) => {
  // Postgres clears prayers and likes in the same transaction as the user;
  // with the JSON files it's done here first.
  if (!isDbActive()) await prayerService.removeUserData(userId);
  return userService.deleteUser(userId);
};

module.exports = { deleteAccount };
