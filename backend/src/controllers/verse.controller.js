const verseService = require('../services/verse.service');
const templateService = require('../services/template.service');
const { getAssetBaseUrl, withImageUrl } = require('../utils/asset-url');

const getVerses = (req, res) => {
  res.json(verseService.list({ mood: req.query.mood }));
};

const getDailyVerse = (req, res) => {
  const now = new Date();
  const template = templateService.getForDay(verseService.dayIndex(now));
  res.json({
    date: now.toISOString().slice(0, 10),
    verse: verseService.getDaily(now),
    template: withImageUrl(template, getAssetBaseUrl(req)),
  });
};

module.exports = { getVerses, getDailyVerse };
