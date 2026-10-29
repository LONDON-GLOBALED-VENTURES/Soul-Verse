const billingService = require('../services/billing.service');

const revenueCatWebhook = async (req, res) => {
  const applied = await billingService.handleRevenueCatEvent(req.body?.event);
  res.json({ success: true, data: { applied } });
};

module.exports = { revenueCatWebhook };
