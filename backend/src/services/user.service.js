const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const USERS_FILE = path.join(__dirname, '..', 'data', 'users.json');

let usersCache = null;

const ensureFile = () => {
  if (!fs.existsSync(USERS_FILE)) {
    fs.mkdirSync(path.dirname(USERS_FILE), { recursive: true });
    fs.writeFileSync(USERS_FILE, JSON.stringify([], null, 2), 'utf8');
  }
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
  return users.find((u) => u.id === id) || null;
};

const findByGoogleId = (googleId) => {
  const users = loadUsers();
  return users.find((u) => u.googleId === googleId) || null;
};

const findByEmail = (email) => {
  const users = loadUsers();
  const normalized = email.trim().toLowerCase();
  return users.find((u) => u.email.toLowerCase() === normalized) || null;
};

const sanitize = (user) => {
  if (!user) return null;
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
      createdAt: now,
      lastLoginAt: now,
    };
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
  sanitize,
  _resetForTests,
};

