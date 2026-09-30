const { Router } = require('express');
const {
  getVerses,
  getDailyVerse,
  getDailyRange,
} = require('../controllers/verse.controller');

const router = Router();

router.get('/', getVerses);
router.get('/daily', getDailyVerse);
router.get('/daily/range', getDailyRange);

module.exports = router;
