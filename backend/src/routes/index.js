const { Router } = require('express');
const healthRoutes = require('./health.routes');
const moodRoutes = require('./mood.routes');
const verseRoutes = require('./verse.routes');
const templateRoutes = require('./template.routes');

const router = Router();

router.use('/health', healthRoutes);
router.use('/moods', moodRoutes);
router.use('/verses', verseRoutes);
router.use('/templates', templateRoutes);

module.exports = router;
