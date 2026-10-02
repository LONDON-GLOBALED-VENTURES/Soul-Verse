const { Router } = require('express');
const healthRoutes = require('./health.routes');
const moodRoutes = require('./mood.routes');
const verseRoutes = require('./verse.routes');
const templateRoutes = require('./template.routes');
const authRoutes = require('./auth.routes');
const prayerRoutes = require('./prayer.routes');

const router = Router();

router.use('/health', healthRoutes);
router.use('/moods', moodRoutes);
router.use('/verses', verseRoutes);
router.use('/templates', templateRoutes);
router.use('/auth', authRoutes);
router.use('/prayers', prayerRoutes);

module.exports = router;
