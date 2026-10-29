const HttpError = require('../utils/http-error');
const prayerService = require('./prayer.service');
const userService = require('./user.service');

const REPORT_REASONS = ['spam', 'offensive', 'harassment', 'other'];
const MAX_DETAILS_LENGTH = 500;

// A prayer reported by this many different people is hidden until a moderator reviews it.
const REPORTS_TO_HIDE = 3;

const prayerAuthorOrThrow = async (prayerId) => {
  const author = await prayerService.getPrayerAuthor(prayerId);
  if (!author) throw new HttpError(404, 'Prayer request not found');
  return author;
};

/** Reports a prayer (once per user). Returns whether the prayer is now hidden. */
const reportPrayer = async ({ prayerId, userId, reason, details }) => {
  const normalizedReason = String(reason || '').toLowerCase();
  if (!REPORT_REASONS.includes(normalizedReason)) {
    throw new HttpError(400, `Reason must be one of: ${REPORT_REASONS.join(', ')}`);
  }
  const trimmedDetails = String(details || '').trim();
  if (trimmedDetails.length > MAX_DETAILS_LENGTH) {
    throw new HttpError(400, `Details must be at most ${MAX_DETAILS_LENGTH} characters`);
  }

  const author = await prayerAuthorOrThrow(prayerId);
  if (author.authorId === userId) throw new HttpError(400, 'You can\'t report your own prayer');

  const reportCount = await prayerService.addReport({
    prayerId,
    userId,
    reason: normalizedReason,
    details: trimmedDetails,
  });
  const hidden = reportCount >= REPORTS_TO_HIDE;
  if (hidden) await prayerService.setHidden(prayerId, true);
  return { hidden };
};

/**
 * Blocks the author of a prayer, so their prayers no longer show. The block
 * list shows them under the name they used there: "Anonymous Believer" for an
 * anonymous prayer, so blocking never reveals who wrote it.
 */
const blockPrayerAuthor = async ({ prayerId, userId }) => {
  const author = await prayerAuthorOrThrow(prayerId);
  if (author.authorId === userId) throw new HttpError(400, 'You can\'t block yourself');

  const label = author.isAnonymous ? 'Anonymous Believer' : author.name;
  await userService.addBlock(userId, author.authorId, label);
  return { blocked: true };
};

const listBlocks = (userId) => userService.listBlocks(userId);

const unblock = (userId, blockedId) => userService.removeBlock(userId, blockedId);

const listReports = () => prayerService.listReported();

const setPrayerHidden = async (prayerId, hidden) => {
  const found = await prayerService.setHidden(prayerId, hidden);
  if (!found) throw new HttpError(404, 'Prayer request not found');
  return { hidden };
};

module.exports = {
  REPORT_REASONS,
  REPORTS_TO_HIDE,
  reportPrayer,
  blockPrayerAuthor,
  listBlocks,
  unblock,
  listReports,
  setPrayerHidden,
};
