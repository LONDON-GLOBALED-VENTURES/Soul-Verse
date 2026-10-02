const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const { calculateStatusLevel } = require('../utils/status-level');

const USERS_FILE = path.join(__dirname, '..', 'data', 'users.json');

let usersCache = null;

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

const findById = (id) => {
  const users = loadUsers();
  const user = users.find((u) => u.id === id) || null;
  if (user) ensurePrayerStats(user);
  return user;
};

const findByGoogleId = (googleId) => {
  const users = loadUsers();
  const user = users.find((u) => u.googleId === googleId) || null;
  if (user) ensurePrayerStats(user);
  return user;
};

const findByEmail = (email) => {
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

const findOrCreateFromGoogle = ({ googleId, email, name, avatarUrl }) => {
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

const updateSubscription = (id, subscriptionUpdate) => {
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

const adjustPrayerStats = (userId, { prayersSharedDelta = 0, likesReceivedDelta = 0, likesGivenDelta = 0 } = {}) => {
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
  sanitize,
  _resetForTests,
};

