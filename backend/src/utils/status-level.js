/**
 * Spiritual status level tiers based on total 'Amens' (likes) received.
 */
const STATUS_TIERS = [
  { level: 1, title: 'Seeker', emoji: '🌱', minLikes: 0 },
  { level: 2, title: 'Believer', emoji: '🕊️', minLikes: 5 },
  { level: 3, title: 'Faithful Servant', emoji: '✝️', minLikes: 20 },
  { level: 4, title: 'Prayer Warrior', emoji: '⚔️', minLikes: 50 },
  { level: 5, title: 'Intercessor', emoji: '🔥', minLikes: 100 },
  { level: 6, title: 'Spiritual Pillar', emoji: '👑', minLikes: 250 },
];

/**
 * Calculates user spiritual status details from their total likes received.
 *
 * @param {number} likesReceived Total number of likes/amens received across all prayers.
 * @returns {object} Status details including current level, title, emoji, next threshold, and progress.
 */
function calculateStatusLevel(likesReceived = 0) {
  const safeLikes = Math.max(0, Number(likesReceived) || 0);

  let currentTier = STATUS_TIERS[0];
  let nextTier = null;

  for (let i = 0; i < STATUS_TIERS.length; i++) {
    if (safeLikes >= STATUS_TIERS[i].minLikes) {
      currentTier = STATUS_TIERS[i];
      nextTier = STATUS_TIERS[i + 1] || null;
    } else {
      break;
    }
  }

  let progress = 1.0;
  if (nextTier) {
    const range = nextTier.minLikes - currentTier.minLikes;
    const earned = safeLikes - currentTier.minLikes;
    progress = Math.min(1.0, Math.max(0.0, Number((earned / range).toFixed(3))));
  }

  return {
    level: currentTier.level,
    title: currentTier.title,
    emoji: currentTier.emoji,
    currentLikes: safeLikes,
    nextTitle: nextTier ? nextTier.title : null,
    nextThreshold: nextTier ? nextTier.minLikes : null,
    progress,
  };
}

module.exports = {
  STATUS_TIERS,
  calculateStatusLevel,
};

