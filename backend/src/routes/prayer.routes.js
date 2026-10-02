const { Router } = require('express');
const { authMiddleware, optionalAuthMiddleware } = require('../middlewares/auth.middleware');
const prayerController = require('../controllers/prayer.controller');

const router = Router();

router.get('/', optionalAuthMiddleware, prayerController.listPrayers);
router.post('/', authMiddleware, prayerController.createPrayer);
router.post('/:id/like', authMiddleware, prayerController.toggleLike);
router.delete('/:id', authMiddleware, prayerController.deletePrayer);

module.exports = router;
