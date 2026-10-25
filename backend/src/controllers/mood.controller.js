const moodService = require('../services/mood.service');

const getMoods = (req, res) => {
  res.json(moodService.getAll());
};

module.exports = { getMoods };
