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
  saveUsers();
  return true;
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
  sanitize,
  _resetForTests,
};
