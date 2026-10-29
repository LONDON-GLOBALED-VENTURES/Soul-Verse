const { Router } = require('express');
const { authMiddleware } = require('../middlewares/auth.middleware');
const moderationController = require('../controllers/moderation.controller');

const router = Router();

router.get('/me/blocks', authMiddleware, moderationController.listBlocks);
router.delete('/me/blocks/:userId', authMiddleware, moderationController.unblock);

module.exports = router;
