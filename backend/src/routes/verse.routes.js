const { Router } = require('express');
const { getVerses, getDailyVerse } = require('../controllers/verse.controller');

const router = Router();

router.get('/', getVerses);
router.get('/daily', getDailyVerse);

module.exports = router;
