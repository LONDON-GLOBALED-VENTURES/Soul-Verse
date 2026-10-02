const prayerService = require('../services/prayer.service');

const listPrayers = async (req, res, next) => {
  try {
    const { sort, category, page, limit } = req.query;
    const currentUserId = req.user ? req.user.id : null;
    const result = await prayerService.listPrayers({
      sort,
      category,
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
    const { title, content, category, isAnonymous } = req.body;
    const prayer = await prayerService.createPrayer({
      authorId,
      title,
      content,
      category,
      isAnonymous,
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
