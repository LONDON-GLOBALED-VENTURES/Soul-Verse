const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const { calculateStatusLevel } = require('../utils/status-level');
const dbUser = require('./db-user.service');

const USERS_FILE = path.join(__dirname, '..', 'data', 'users.json');

let usersCache = null;

const isDbActive = () => Boolean(process.env.DATABASE_URL && process.env.NODE_ENV !== 'test');

const ensureFile = () => {
  if (!fs.existsSync(USERS_FILE)) {
    fs.mkdirSync(path.dirname(USERS_FILE), { recursive: true });
    fs.writeFileSync(USERS_FILE, JSON.stringify([], null, 2), 'utf8');
  }
};

const ensurePrayerStats = (user) => {
  if (!user) return;
  if (!user.prayerStats) {
    user.prayerStats = {
      prayersShared: 0,
      likesReceived: 0,
      likesGiven: 0,
    };
  }
  user.prayerStats.status = calculateStatusLevel(user.prayerStats.likesReceived || 0);
};

const loadUsers = () => {
  if (usersCache !== null) return usersCache;
  ensureFile();
  try {
    const raw = fs.readFileSync(USERS_FILE, 'utf8');
    usersCache = JSON.parse(raw);
    if (!Array.isArray(usersCache)) usersCache = [];
  } catch (err) {
    usersCache = [];
  }
  return usersCache;
};

const saveUsers = () => {
  ensureFile();
  fs.writeFileSync(USERS_FILE, JSON.stringify(usersCache || [], null, 2), 'utf8');
};

const findById = async (id) => {
  if (isDbActive()) return dbUser.findById(id);

  const users = loadUsers();
  const user = users.find((u) => u.id === id) || null;
  if (user) ensurePrayerStats(user);
  return user;
};

const findByGoogleId = async (googleId) => {
  if (isDbActive()) return dbUser.findByGoogleId(googleId);

  const users = loadUsers();
  const user = users.find((u) => u.googleId === googleId) || null;
  if (user) ensurePrayerStats(user);
  return user;
};

const findByEmail = async (email) => {
  if (isDbActive()) return dbUser.findByEmail(email);

  const users = loadUsers();
  const normalized = email.trim().toLowerCase();
  const user = users.find((u) => u.email.toLowerCase() === normalized) || null;
  if (user) ensurePrayerStats(user);
  return user;
};

const sanitize = (user) => {
  if (!user) return null;
  ensurePrayerStats(user);
  const { ...safe } = user;
  return safe;
};

const findOrCreateFromGoogle = async ({ googleId, email, name, avatarUrl }) => {
  if (isDbActive()) {
    return dbUser.findOrCreateFromGoogle({ googleId, email, name, avatarUrl });
  }

  const users = loadUsers();
  const now = new Date().toISOString();
  const normalizedEmail = email.trim().toLowerCase();

  let user = users.find((u) => u.googleId === googleId || u.email.toLowerCase() === normalizedEmail);

  if (user) {
    user.googleId = googleId;
    if (name) user.name = name;
    if (avatarUrl) user.avatarUrl = avatarUrl;
    user.lastLoginAt = now;
    ensurePrayerStats(user);
  } else {
    user = {
      id: `usr_${crypto.randomUUID()}`,
      googleId,
      email: normalizedEmail,
      name: name || '',
      avatarUrl: avatarUrl || '',
      subscription: {
        status: 'free',
        tier: 'none',
        purchaseToken: null,
        expiresAt: null,
      },
      prayerStats: {
        prayersShared: 0,
        likesReceived: 0,
        likesGiven: 0,
      },
      createdAt: now,
      lastLoginAt: now,
    };
    ensurePrayerStats(user);
    users.push(user);
  }

  saveUsers();
  return sanitize(user);
};

const updateSubscription = async (id, subscriptionUpdate) => {
  if (isDbActive()) return dbUser.updateSubscription(id, subscriptionUpdate);

  const users = loadUsers();
  const user = users.find((u) => u.id === id);
  if (!user) return null;

  user.subscription = {
    ...user.subscription,
    ...subscriptionUpdate,
  };
  saveUsers();
  return sanitize(user);
};

const adjustPrayerStats = async (userId, { prayersSharedDelta = 0, likesReceivedDelta = 0, likesGivenDelta = 0 } = {}) => {
  if (isDbActive()) {
    return dbUser.adjustPrayerStats(userId, { prayersSharedDelta, likesReceivedDelta, likesGivenDelta });
  }

  const users = loadUsers();
  const user = users.find((u) => u.id === userId);
  if (!user) return null;

  ensurePrayerStats(user);
  user.prayerStats.prayersShared = Math.max(0, (user.prayerStats.prayersShared || 0) + prayersSharedDelta);
  user.prayerStats.likesReceived = Math.max(0, (user.prayerStats.likesReceived || 0) + likesReceivedDelta);
  user.prayerStats.likesGiven = Math.max(0, (user.prayerStats.likesGiven || 0) + likesGivenDelta);
  user.prayerStats.status = calculateStatusLevel(user.prayerStats.likesReceived);

  saveUsers();
  return sanitize(user);
};

/**
 * Removes the user. In Postgres this also removes their prayers and likes; with
 * the JSON files, account.service clears those first. False if there was no such user.
 */
const deleteUser = async (id) => {
  if (isDbActive()) return dbUser.deleteUser(id);

  const users = loadUsers();
  const index = users.findIndex((u) => u.id === id);
  if (index === -1) return false;
  users.splice(index, 1);
  // Nobody needs to block an account that no longer exists.
  for (const user of users) {
    if (user.blocks) user.blocks = user.blocks.filter((b) => b.userId !== id);
  }
  saveUsers();
  return true;
};

/** Blocks [blockedId] for [blockerId]; [label] is the name they appeared under. */
const addBlock = async (blockerId, blockedId, label) => {
  if (isDbActive()) return dbUser.addBlock(blockerId, blockedId, label);

  const blocker = loadUsers().find((u) => u.id === blockerId);
  if (!blocker) return;
  blocker.blocks = blocker.blocks || [];
  if (blocker.blocks.some((b) => b.userId === blockedId)) return;
  blocker.blocks.push({ userId: blockedId, label, createdAt: new Date().toISOString() });
  saveUsers();
};

const removeBlock = async (blockerId, blockedId) => {
  if (isDbActive()) return dbUser.removeBlock(blockerId, blockedId);

  const blocker = loadUsers().find((u) => u.id === blockerId);
  if (!blocker?.blocks) return;
  blocker.blocks = blocker.blocks.filter((b) => b.userId !== blockedId);
  saveUsers();
};

/** The people [blockerId] has blocked, most recent first. */
const listBlocks = async (blockerId) => {
  if (isDbActive()) return dbUser.listBlocks(blockerId);

  const blocker = loadUsers().find((u) => u.id === blockerId);
  return [...(blocker?.blocks || [])]
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .map((b) => ({ userId: b.userId, name: b.label, blockedAt: b.createdAt }));
};

/** Ids of everyone [blockerId] has blocked (JSON mode; Postgres filters in SQL). */
const getBlockedIds = (blockerId) => {
  const blocker = loadUsers().find((u) => u.id === blockerId);
  return new Set((blocker?.blocks || []).map((b) => b.userId));
};

const _resetForTests = (initial = []) => {
  usersCache = [...initial];
  saveUsers();
};

module.exports = {
  findById,
  findByGoogleId,
  findByEmail,
  findOrCreateFromGoogle,
  updateSubscription,
  adjustPrayerStats,
  deleteUser,
  addBlock,
  removeBlock,
  listBlocks,
  getBlockedIds,
  sanitize,
  _resetForTests,
};
