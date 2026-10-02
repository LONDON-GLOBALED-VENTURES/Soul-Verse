const crypto = require('crypto');
const { pool } = require('../db');
const { calculateStatusLevel } = require('../utils/status-level');

const formatUser = (row) => {
  if (!row) return null;
  const likesReceived = row.likes_received || 0;
  return {
    id: row.id,
    googleId: row.google_id,
    email: row.email,
    name: row.name || '',
    avatarUrl: row.avatar_url || '',
    subscription: {
      status: row.subscription_status || 'free',
      tier: row.subscription_tier || 'none',
      purchaseToken: row.subscription_purchase_token || null,
      expiresAt: row.subscription_expires_at ? new Date(row.subscription_expires_at).toISOString() : null,
    },
    prayerStats: {
      prayersShared: row.prayers_shared || 0,
      likesReceived: likesReceived,
      likesGiven: row.likes_given || 0,
      status: calculateStatusLevel(likesReceived),
    },
    createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
    lastLoginAt: row.last_login_at ? new Date(row.last_login_at).toISOString() : new Date().toISOString(),
  };
};

const findById = async (id) => {
  if (!id) return null;
  const res = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
  return formatUser(res.rows[0]);
};

const findByGoogleId = async (googleId) => {
  if (!googleId) return null;
  const res = await pool.query('SELECT * FROM users WHERE google_id = $1', [googleId]);
  return formatUser(res.rows[0]);
};

const findByEmail = async (email) => {
  if (!email) return null;
  const normalized = email.trim().toLowerCase();
  const res = await pool.query('SELECT * FROM users WHERE LOWER(email) = $1', [normalized]);
  return formatUser(res.rows[0]);
};

const findOrCreateFromGoogle = async ({ googleId, email, name, avatarUrl }) => {
  const normalized = (email || '').trim().toLowerCase();
  const existing = await pool.query(
    'SELECT * FROM users WHERE google_id = $1 OR LOWER(email) = $2',
    [googleId, normalized]
  );

  const now = new Date();
  if (existing.rows.length > 0) {
    const updated = await pool.query(
      `UPDATE users
       SET google_id = $1,
           name = CASE WHEN $2 <> '' THEN $2 ELSE name END,
           avatar_url = CASE WHEN $3 <> '' THEN $3 ELSE avatar_url END,
           last_login_at = $4
       WHERE id = $5
       RETURNING *`,
      [googleId, name || '', avatarUrl || '', now, existing.rows[0].id]
    );
    return formatUser(updated.rows[0]);
  } else {
    const id = `usr_${crypto.randomUUID()}`;
    const inserted = await pool.query(
      `INSERT INTO users (id, google_id, email, name, avatar_url, created_at, last_login_at)
       VALUES ($1, $2, $3, $4, $5, $6, $6)
       RETURNING *`,
      [id, googleId, normalized, name || '', avatarUrl || '', now]
    );
    return formatUser(inserted.rows[0]);
  }
};

const adjustPrayerStats = async (userId, { prayersSharedDelta = 0, likesReceivedDelta = 0, likesGivenDelta = 0 } = {}) => {
  const res = await pool.query(
    `UPDATE users
     SET prayers_shared = GREATEST(0, prayers_shared + $1),
         likes_received = GREATEST(0, likes_received + $2),
         likes_given = GREATEST(0, likes_given + $3)
     WHERE id = $4
     RETURNING *`,
    [prayersSharedDelta, likesReceivedDelta, likesGivenDelta, userId]
  );
  return formatUser(res.rows[0]);
};

const updateSubscription = async (id, subscriptionUpdate = {}) => {
  const { status, tier, purchaseToken, expiresAt } = subscriptionUpdate;
  const res = await pool.query(
    `UPDATE users
     SET subscription_status = COALESCE($1, subscription_status),
         subscription_tier = COALESCE($2, subscription_tier),
         subscription_purchase_token = COALESCE($3, subscription_purchase_token),
         subscription_expires_at = COALESCE($4, subscription_expires_at)
     WHERE id = $5
     RETURNING *`,
    [status, tier, purchaseToken, expiresAt, id]
  );
  return formatUser(res.rows[0]);
};

module.exports = {
  findById,
  findByGoogleId,
  findByEmail,
  findOrCreateFromGoogle,
  adjustPrayerStats,
  updateSubscription,
  formatUser,
};
