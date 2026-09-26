const moods = require('../data/moods.json');
const HttpError = require('../utils/http-error');

const getAll = () => moods;

const assertExists = (moodId) => {
  if (!moods.some((mood) => mood.id === moodId)) {
    throw new HttpError(404, `Mood not found: ${moodId}`);
  }
};

module.exports = { getAll, assertExists };
