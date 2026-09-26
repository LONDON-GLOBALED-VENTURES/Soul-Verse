const { assetBaseUrl } = require('../config/env');

// Without ASSET_BASE_URL (dev), derive it from the request host so emulators/devices get a reachable URL.
const getAssetBaseUrl = (req) =>
  assetBaseUrl || `${req.protocol}://${req.get('host')}/static`;

const withImageUrl = ({ imagePath, ...item }, baseUrl) => ({
  ...item,
  imageUrl: `${baseUrl}/${imagePath}`,
});

module.exports = { getAssetBaseUrl, withImageUrl };
