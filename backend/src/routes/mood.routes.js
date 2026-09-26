const { Router } = require('express');
const { getMoods } = require('../controllers/mood.controller');

const router = Router();

router.get('/', getMoods);

module.exports = router;
