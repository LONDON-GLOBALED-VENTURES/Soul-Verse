const { Router } = require('express');
const { getTemplates } = require('../controllers/template.controller');

const router = Router();

router.get('/', getTemplates);

module.exports = router;
