const prayerService = require('../services/prayer.service');

const listPrayers = async (req, res, next) => {
  try {
    const { sort, category, type, page, limit, mine } = req.query;
    const currentUserId = req.user ? req.user.id : null;
    const result = await prayerService.listPrayers({
      sort,
      category,
      type,
      mine: mine === 'true' || mine === '1',
      page,
      limit,
      currentUserId,
    });
    res.json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

const createPrayer = async (req, res, next) => {
  try {
    const authorId = req.user.id;
    const { title, content, category, isAnonymous, type } = req.body;
    const prayer = await prayerService.createPrayer({
      authorId,
      title,
      content,
      category,
      isAnonymous,
      type,
    });
    res.status(201).json({
      success: true,
      data: prayer,
    });
  } catch (err) {
    next(err);
  }
};

const toggleLike = async (req, res, next) => {
  try {
    const prayerId = req.params.id;
    const userId = req.user.id;
    const result = await prayerService.toggleLike({ prayerId, userId });
    res.json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

const deletePrayer = async (req, res, next) => {
  try {
    const prayerId = req.params.id;
    const userId = req.user.id;
    const result = await prayerService.deletePrayer({ prayerId, userId });
    res.json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  listPrayers,
  createPrayer,
  toggleLike,
  deletePrayer,
};
