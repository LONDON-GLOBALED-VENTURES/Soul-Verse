const moderationService = require('../services/moderation.service');

const reportPrayer = async (req, res) => {
  const { reason, details } = req.body || {};
  const result = await moderationService.reportPrayer({
    prayerId: req.params.id,
    userId: req.user.id,
    reason,
    details,
  });
  res.json({ success: true, data: result });
};

const blockPrayerAuthor = async (req, res) => {
  const result = await moderationService.blockPrayerAuthor({
    prayerId: req.params.id,
    userId: req.user.id,
  });
  res.json({ success: true, data: result });
};

const listBlocks = async (req, res) => {
  const items = await moderationService.listBlocks(req.user.id);
  res.json({ success: true, data: { items } });
};

const unblock = async (req, res) => {
  await moderationService.unblock(req.user.id, req.params.userId);
  res.json({ success: true, data: { blocked: false } });
};

const listReports = async (req, res) => {
  const items = await moderationService.listReports();
  res.json({ success: true, data: { items } });
};

const hidePrayer = async (req, res) => {
  res.json({ success: true, data: await moderationService.setPrayerHidden(req.params.id, true) });
};

const restorePrayer = async (req, res) => {
  res.json({ success: true, data: await moderationService.setPrayerHidden(req.params.id, false) });
};

module.exports = {
  reportPrayer,
  blockPrayerAuthor,
  listBlocks,
  unblock,
  listReports,
  hidePrayer,
  restorePrayer,
};
