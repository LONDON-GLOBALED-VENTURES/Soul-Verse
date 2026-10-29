const { Router } = require('express');
const { revenueCatWebhookAuth } = require('../middlewares/revenuecat.middleware');
const billingController = require('../controllers/billing.controller');

const router = Router();

router.post('/revenuecat-webhook', revenueCatWebhookAuth, billingController.revenueCatWebhook);

module.exports = router;
