const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const HttpError = require('../utils/http-error');
const userService = require('./user.service');

const PRAYERS_FILE = path.join(__dirname, '..', 'data', 'prayers.json');

let prayersCache = null;

const ensureFile = () => {
  if (!fs.existsSync(PRAYERS_FILE)) {
    fs.mkdirSync(path.dirname(PRAYERS_FILE), { recursive: true });
    fs.writeFileSync(PRAYERS_FILE, JSON.stringify([], null, 2), 'utf8');
  }
};

const loadPrayers = () => {
  if (prayersCache !== null) return prayersCache;
  ensureFile();
  try {
    const raw = fs.readFileSync(PRAYERS_FILE, 'utf8');
    prayersCache = JSON.parse(raw);
    if (!Array.isArray(prayersCache)) prayersCache = [];
  } catch (err) {
    prayersCache = [];
  }
  return prayersCache;
};

const savePrayers = () => {
  ensureFile();
  fs.writeFileSync(PRAYERS_FILE, JSON.stringify(prayersCache || [], null, 2), 'utf8');
};

const formatPrayer = (prayer, currentUserId = null) => {
  const author = userService.findById(prayer.authorId);
  const authorStatus = author?.prayerStats?.status || {
    level: 1,
    title: 'Seeker',
    emoji: '🌱',
  };

  const isLikedByMe = Boolean(currentUserId && prayer.likedBy?.includes(currentUserId));
  const isMine = Boolean(currentUserId && prayer.authorId === currentUserId);

  return {
    id: prayer.id,
    authorId: prayer.authorId,
    authorName: prayer.isAnonymous ? 'Anonymous Believer' : (author?.name || prayer.authorName || 'Believer'),
    authorAvatar: prayer.isAnonymous ? '' : (author?.avatarUrl || prayer.authorAvatar || ''),
    authorStatusLevel: authorStatus.title,
    authorStatusEmoji: authorStatus.emoji,
    isAnonymous: Boolean(prayer.isAnonymous),
    title: prayer.title,
    content: prayer.content,
    category: prayer.category || 'General',
    likesCount: prayer.likesCount || 0,
    isLikedByMe,
    isMine,
    createdAt: prayer.createdAt,
    updatedAt: prayer.updatedAt || prayer.createdAt,
  };
};

const listPrayers = ({ sort = 'recent', category = 'All', currentUserId = null, page = 1, limit = 50 } = {}) => {
  const prayers = loadPrayers();

  let filtered = [...prayers];

  if (category && category.trim().toLowerCase() !== 'all') {
    const target = category.trim().toLowerCase();
    filtered = filtered.filter((p) => (p.category || 'General').toLowerCase() === target);
  }

  if (sort === 'popular' || sort === 'top') {
    filtered.sort((a, b) => {
      if ((b.likesCount || 0) !== (a.likesCount || 0)) {
        return (b.likesCount || 0) - (a.likesCount || 0);
      }
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });
  } else {
    // default: recent
    filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  const safePage = Math.max(1, parseInt(page, 10) || 1);
  const safeLimit = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
  const offset = (safePage - 1) * safeLimit;
  const paginated = filtered.slice(offset, offset + safeLimit);

  return {
    items: paginated.map((p) => formatPrayer(p, currentUserId)),
    total: filtered.length,
    page: safePage,
    limit: safeLimit,
  };
};

const createPrayer = ({ authorId, title, content, category = 'General', isAnonymous = false }) => {
  if (!authorId) throw new HttpError(401, 'Authentication required to share a prayer');

  const trimmedTitle = (title || '').trim();
  const trimmedContent = (content || '').trim();

  if (!trimmedTitle || trimmedTitle.length < 3 || trimmedTitle.length > 100) {
    throw new HttpError(400, 'Title must be between 3 and 100 characters');
  }

  if (!trimmedContent || trimmedContent.length < 10 || trimmedContent.length > 2000) {
    throw new HttpError(400, 'Content must be between 10 and 2000 characters');
  }

  const author = userService.findById(authorId);
  if (!author) throw new HttpError(404, 'Author account not found');

  const now = new Date().toISOString();
  const newPrayer = {
    id: `pry_${crypto.randomUUID()}`,
    authorId,
    authorName: author.name || 'Believer',
    authorAvatar: author.avatarUrl || '',
    isAnonymous: Boolean(isAnonymous),
    title: trimmedTitle,
    content: trimmedContent,
    category: (category || 'General').trim(),
    likesCount: 0,
    likedBy: [],
    createdAt: now,
    updatedAt: now,
  };

  const prayers = loadPrayers();
  prayers.unshift(newPrayer);
  savePrayers();

  userService.adjustPrayerStats(authorId, { prayersSharedDelta: 1 });

  return formatPrayer(newPrayer, authorId);
};

const toggleLike = ({ prayerId, userId }) => {
  if (!userId) throw new HttpError(401, 'Authentication required to pray for this request');

  const prayers = loadPrayers();
  const prayer = prayers.find((p) => p.id === prayerId);
  if (!prayer) throw new HttpError(404, 'Prayer request not found');

  if (!Array.isArray(prayer.likedBy)) prayer.likedBy = [];

  const existingIndex = prayer.likedBy.indexOf(userId);
  let isLiked = false;

  if (existingIndex >= 0) {
    prayer.likedBy.splice(existingIndex, 1);
    prayer.likesCount = Math.max(0, (prayer.likesCount || 1) - 1);
    isLiked = false;

    userService.adjustPrayerStats(prayer.authorId, { likesReceivedDelta: -1 });
    userService.adjustPrayerStats(userId, { likesGivenDelta: -1 });
  } else {
    prayer.likedBy.push(userId);
    prayer.likesCount = (prayer.likesCount || 0) + 1;
    isLiked = true;

    userService.adjustPrayerStats(prayer.authorId, { likesReceivedDelta: 1 });
    userService.adjustPrayerStats(userId, { likesGivenDelta: 1 });
  }

  prayer.updatedAt = new Date().toISOString();
  savePrayers();

  const author = userService.findById(prayer.authorId);

  return {
    prayerId: prayer.id,
    isLiked,
    likesCount: prayer.likesCount,
    authorStatus: author?.prayerStats?.status,
  };
};

const deletePrayer = ({ prayerId, userId }) => {
  if (!userId) throw new HttpError(401, 'Authentication required');

  const prayers = loadPrayers();
  const index = prayers.findIndex((p) => p.id === prayerId);
  if (index === -1) throw new HttpError(404, 'Prayer request not found');

  const prayer = prayers[index];
  if (prayer.authorId !== userId) {
    throw new HttpError(403, 'You can only delete your own prayer requests');
  }

  const lostLikes = prayer.likesCount || 0;
  prayers.splice(index, 1);
  savePrayers();

  userService.adjustPrayerStats(userId, {
    prayersSharedDelta: -1,
    likesReceivedDelta: -lostLikes,
  });

  return { success: true };
};

const _resetForTests = (initial = []) => {
  prayersCache = [...initial];
  savePrayers();
};

module.exports = {
  listPrayers,
  createPrayer,
  toggleLike,
  deletePrayer,
  formatPrayer,
  _resetForTests,
};
