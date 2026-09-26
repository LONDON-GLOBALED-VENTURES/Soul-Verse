const templates = require('../data/templates.json');
const moodService = require('./mood.service');

const list = ({ mood } = {}) => {
  if (!mood) return templates;
  moodService.assertExists(mood);
  return templates.filter((template) => template.moods.includes(mood));
};

const getForDay = (dayIndex) => templates[dayIndex % templates.length];

module.exports = { list, getForDay };
