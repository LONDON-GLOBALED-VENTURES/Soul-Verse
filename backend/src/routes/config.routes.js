const { Router } = require('express');
const { billingEnabled } = require('../config/env');

const router = Router();

// Settings the app reads at start-up.
router.get('/', (req, res) => {
  res.json({ billingEnabled });
});

module.exports = router;
