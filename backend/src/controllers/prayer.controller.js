const prayerService = require('../services/prayer.service');

const listPrayers = (req, res, next) => {
  try {
    const { sort, category, page, limit } = req.query;
    const currentUserId = req.user ? req.user.id : null;
    const result = prayerService.listPrayers({
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

const createPrayer = (req, res, next) => {
  try {
    const authorId = req.user.id;
    const { title, content, category, isAnonymous } = req.body;
    const prayer = prayerService.createPrayer({
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

const toggleLike = (req, res, next) => {
  try {
    const prayerId = req.params.id;
    const userId = req.user.id;
    const result = prayerService.toggleLike({ prayerId, userId });
    res.json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

const deletePrayer = (req, res, next) => {
  try {
    const prayerId = req.params.id;
    const userId = req.user.id;
    const result = prayerService.deletePrayer({ prayerId, userId });
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
