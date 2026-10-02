const { Router } = require('express');
const { googleAuth, refresh, getMe } = require('../controllers/auth.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');

const router = Router();

router.post('/google', googleAuth);
router.post('/refresh', refresh);
router.get('/me', authMiddleware, getMe);

module.exports = router;

