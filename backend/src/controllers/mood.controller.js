const moodService = require('../services/mood.service');
const { getAssetBaseUrl, withImageUrl } = require('../utils/asset-url');

const getMoods = (req, res) => {
  const baseUrl = getAssetBaseUrl(req);
  res.json(moodService.getAll().map((mood) => withImageUrl(mood, baseUrl)));
};

module.exports = { getMoods };
