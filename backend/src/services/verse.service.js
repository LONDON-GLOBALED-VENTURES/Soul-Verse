const verses = require('../data/verses.json');
const moodService = require('./mood.service');

const DAY_MS = 24 * 60 * 60 * 1000;

const list = ({ mood } = {}) => {
  if (!mood) return verses;
  moodService.assertExists(mood);
  return verses.filter((verse) => verse.moods.includes(mood));
};

const dayIndex = (date) => Math.floor(date.getTime() / DAY_MS);

const getDaily = (date = new Date()) => verses[dayIndex(date) % verses.length];

module.exports = { list, getDaily, dayIndex };
