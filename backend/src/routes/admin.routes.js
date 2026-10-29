const { Router } = require('express');
const { adminMiddleware } = require('../middlewares/admin.middleware');
const moderationController = require('../controllers/moderation.controller');

const router = Router();

router.use(adminMiddleware);
router.get('/reports', moderationController.listReports);
router.post('/prayers/:id/hide', moderationController.hidePrayer);
router.post('/prayers/:id/restore', moderationController.restorePrayer);

module.exports = router;
