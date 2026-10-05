const templates = require('../data/templates.json');
const moodService = require('./mood.service');

const list = ({ mood } = {}) => {
  if (!mood) return templates;
  moodService.assertExists(mood);
  return templates.filter((template) => template.moods.includes(mood));
};

const getForDay = (dayIndex) => {
  const freeTemplates = templates.filter((t) => !t.isPremium);
  const pool = freeTemplates.length > 0 ? freeTemplates : templates;
  return pool[dayIndex % pool.length];
};

module.exports = { list, getForDay };
