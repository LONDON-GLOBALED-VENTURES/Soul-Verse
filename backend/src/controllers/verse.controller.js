const verseService = require('../services/verse.service');
const { getAssetBaseUrl, withImageUrl } = require('../utils/asset-url');

const withTemplateUrl = (entry, baseUrl) => ({
  ...entry,
  template: withImageUrl(entry.template, baseUrl),
});

const getVerses = (req, res) => {
  res.json(verseService.list({ mood: req.query.mood }));
};

// ?date=YYYY-MM-DD (the client's local date); defaults to today in UTC.
const getDailyVerse = (req, res) => {
  const entry = verseService.getDaily(req.query.date);
  res.json(withTemplateUrl(entry, getAssetBaseUrl(req)));
};

// ?start=YYYY-MM-DD&days=N
const getDailyRange = (req, res) => {
  const baseUrl = getAssetBaseUrl(req);
  const entries = verseService.getDailyRange(req.query.start, req.query.days);
  res.json(entries.map((entry) => withTemplateUrl(entry, baseUrl)));
};

module.exports = { getVerses, getDailyVerse, getDailyRange };
