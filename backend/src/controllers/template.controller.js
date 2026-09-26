const templateService = require('../services/template.service');
const { getAssetBaseUrl, withImageUrl } = require('../utils/asset-url');

const getTemplates = (req, res) => {
  const baseUrl = getAssetBaseUrl(req);
  res.json(
    templateService.list({ mood: req.query.mood }).map((t) => withImageUrl(t, baseUrl)),
  );
};

module.exports = { getTemplates };
