const crypto = require('crypto');
const { pool } = require('../db');
const HttpError = require('../utils/http-error');
const { calculateStatusLevel } = require('../utils/status-level');

const formatPrayerRow = (row, currentUserId = null) => {
  const authorStatus = calculateStatusLevel(row.author_likes_received || 0);
  const isAnonymous = Boolean(row.is_anonymous);
  const isLikedByMe = Boolean(row.is_liked_by_me);
  const isMine = Boolean(currentUserId && row.author_id === currentUserId);

  return {
    id: row.id,
    authorId: row.author_id,
    authorName: isAnonymous ? 'Anonymous Believer' : (row.author_name || 'Believer'),
    authorAvatar: isAnonymous ? '' : (row.author_avatar || ''),
    authorStatusLevel: authorStatus.title,
    authorStatusEmoji: authorStatus.emoji,
    isAnonymous,
    title: row.title,
    content: row.content,
    category: row.category || 'General',
    type: row.type || 'request',
    likesCount: parseInt(row.likes_count, 10) || 0,
    isLikedByMe,
    isMine,
    createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
    updatedAt: row.updated_at ? new Date(row.updated_at).toISOString() : new Date().toISOString(),
  };
};

const listPrayers = async ({ sort = 'recent', category = 'All', type = 'all', mine = false, currentUserId = null, page = 1, limit = 50 } = {}) => {
  const safePage = Math.max(1, parseInt(page, 10) || 1);
  const safeLimit = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
  const offset = (safePage - 1) * safeLimit;

  const conditions = [];
  const params = [];

  if (category && category.trim().toLowerCase() !== 'all') {
    params.push(category.trim().toLowerCase());
    conditions.push(`LOWER(p.category) = $${params.length}`);
  }

  if (type && type.trim().toLowerCase() !== 'all') {
    params.push(type.trim().toLowerCase());
    conditions.push(`LOWER(COALESCE(p.type, 'request')) = $${params.length}`);
  }

  if (mine && currentUserId) {
    params.push(currentUserId);
    conditions.push(`p.author_id = $${params.length}`);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  let orderBy = 'ORDER BY p.created_at DESC';
  if (sort === 'popular' || sort === 'top') {
    orderBy = 'ORDER BY p.likes_count DESC, p.created_at DESC';
  } else if (sort === 'needs_prayer' || sort === 'unanswered') {
    orderBy = 'ORDER BY p.likes_count ASC, p.created_at DESC';
  } else if (sort === 'trending') {
    orderBy = 'ORDER BY ((p.likes_count + 1.0) / POWER((EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 3600.0) + 2.0, 1.5)) DESC, p.created_at DESC';
  }

  // Count total matching
  const countRes = await pool.query(
    `SELECT COUNT(*)::int AS total FROM prayers p ${whereClause}`,
    params
  );
  const total = countRes.rows[0]?.total || 0;

  // Main select with author stats and optional like status
  const currentUserIdParamIndex = params.length + 1;
  const limitParamIndex = params.length + 2;
  const offsetParamIndex = params.length + 3;

  const queryParams = [...params, currentUserId, safeLimit, offset];

  const selectSql = `
    SELECT 
      p.*,
      u.name AS author_name,
      u.avatar_url AS author_avatar,
      u.likes_received AS author_likes_received,
      CASE 
        WHEN $${currentUserIdParamIndex}::varchar IS NOT NULL AND pl.user_id IS NOT NULL THEN TRUE 
        ELSE FALSE 
      END AS is_liked_by_me
    FROM prayers p
    LEFT JOIN users u ON u.id = p.author_id
    LEFT JOIN prayer_likes pl ON pl.prayer_id = p.id AND pl.user_id = $${currentUserIdParamIndex}::varchar
    ${whereClause}
    ${orderBy}
    LIMIT $${limitParamIndex} OFFSET $${offsetParamIndex}
  `;

  const { rows } = await pool.query(selectSql, queryParams);

  return {
    items: rows.map((r) => formatPrayerRow(r, currentUserId)),
    total,
    page: safePage,
    limit: safeLimit,
  };
};

const createPrayer = async ({ authorId, title, content, category = 'General', isAnonymous = false, type = 'request' }) => {
  if (!authorId) throw new HttpError(401, 'Authentication required to share a prayer');

  const trimmedTitle = (title || '').trim();
  const trimmedContent = (content || '').trim();

  if (!trimmedTitle || trimmedTitle.length < 3 || trimmedTitle.length > 100) {
    throw new HttpError(400, 'Title must be between 3 and 100 characters');
  }

  if (!trimmedContent || trimmedContent.length < 10 || trimmedContent.length > 2000) {
    throw new HttpError(400, 'Content must be between 10 and 2000 characters');
  }

  const validTypes = ['request', 'prayer', 'praise'];
  const normalizedType = validTypes.includes(String(type).toLowerCase())
    ? String(type).toLowerCase()
    : 'request';

  // Check author exists
  const authorRes = await pool.query('SELECT * FROM users WHERE id = $1', [authorId]);
  const author = authorRes.rows[0];
  if (!author) throw new HttpError(404, 'Author account not found');

  const prayerId = `pry_${crypto.randomUUID()}`;
  const now = new Date();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(
      `INSERT INTO prayers (id, author_id, author_name, author_avatar, is_anonymous, title, content, category, type, likes_count, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 0, $10, $10)`,
      [
        prayerId,
        authorId,
        author.name || 'Believer',
        author.avatar_url || '',
        Boolean(isAnonymous),
        trimmedTitle,
        trimmedContent,
        (category || 'General').trim(),
        normalizedType,
        now,
      ]
    );

    await client.query(
      'UPDATE users SET prayers_shared = prayers_shared + 1 WHERE id = $1',
      [authorId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  return {
    id: prayerId,
    authorId,
    authorName: isAnonymous ? 'Anonymous Believer' : (author.name || 'Believer'),
    authorAvatar: isAnonymous ? '' : (author.avatar_url || ''),
    authorStatusLevel: calculateStatusLevel(author.likes_received || 0).title,
    authorStatusEmoji: calculateStatusLevel(author.likes_received || 0).emoji,
    isAnonymous: Boolean(isAnonymous),
    title: trimmedTitle,
    content: trimmedContent,
    category: (category || 'General').trim(),
    type: normalizedType,
    likesCount: 0,
    isLikedByMe: false,
    isMine: true,
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  };
};

const toggleLike = async ({ prayerId, userId }) => {
  if (!userId) throw new HttpError(401, 'Authentication required to pray for this request');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const prayerRes = await client.query('SELECT * FROM prayers WHERE id = $1 FOR UPDATE', [prayerId]);
    const prayer = prayerRes.rows[0];
    if (!prayer) throw new HttpError(404, 'Prayer request not found');

    const likeCheck = await client.query(
      'SELECT 1 FROM prayer_likes WHERE prayer_id = $1 AND user_id = $2',
      [prayerId, userId]
    );

    const isCurrentlyLiked = likeCheck.rows.length > 0;
    let isLiked = false;
    let newLikesCount = prayer.likes_count || 0;
    let authorLikesReceived = 0;

    if (isCurrentlyLiked) {
      await client.query('DELETE FROM prayer_likes WHERE prayer_id = $1 AND user_id = $2', [prayerId, userId]);
      
      const updatePrayer = await client.query(
        'UPDATE prayers SET likes_count = GREATEST(0, likes_count - 1), updated_at = NOW() WHERE id = $1 RETURNING likes_count',
        [prayerId]
      );
      newLikesCount = updatePrayer.rows[0].likes_count;

      const updateAuthor = await client.query(
        'UPDATE users SET likes_received = GREATEST(0, likes_received - 1) WHERE id = $1 RETURNING likes_received',
        [prayer.author_id]
      );
      authorLikesReceived = updateAuthor.rows[0]?.likes_received || 0;

      await client.query(
        'UPDATE users SET likes_given = GREATEST(0, likes_given - 1) WHERE id = $1',
        [userId]
      );

      isLiked = false;
    } else {
      await client.query('INSERT INTO prayer_likes (prayer_id, user_id) VALUES ($1, $2)', [prayerId, userId]);

      const updatePrayer = await client.query(
        'UPDATE prayers SET likes_count = likes_count + 1, updated_at = NOW() WHERE id = $1 RETURNING likes_count',
        [prayerId]
      );
      newLikesCount = updatePrayer.rows[0].likes_count;

      const updateAuthor = await client.query(
        'UPDATE users SET likes_received = likes_received + 1 WHERE id = $1 RETURNING likes_received',
        [prayer.author_id]
      );
      authorLikesReceived = updateAuthor.rows[0]?.likes_received || 0;

      await client.query(
        'UPDATE users SET likes_given = likes_given + 1 WHERE id = $1',
        [userId]
      );

      isLiked = true;
    }

    await client.query('COMMIT');

    const authorStatus = calculateStatusLevel(authorLikesReceived);

    return {
      prayerId,
      isLiked,
      likesCount: newLikesCount,
      authorStatus,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

const deletePrayer = async ({ prayerId, userId }) => {
  if (!userId) throw new HttpError(401, 'Authentication required');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const prayerRes = await client.query('SELECT * FROM prayers WHERE id = $1', [prayerId]);
    const prayer = prayerRes.rows[0];
    if (!prayer) throw new HttpError(404, 'Prayer request not found');

    if (prayer.author_id !== userId) {
      throw new HttpError(403, 'You can only delete your own prayer requests');
    }

    const lostLikes = prayer.likes_count || 0;

    await client.query('DELETE FROM prayers WHERE id = $1', [prayerId]);

    await client.query(
      `UPDATE users 
       SET prayers_shared = GREATEST(0, prayers_shared - 1),
           likes_received = GREATEST(0, likes_received - $1)
       WHERE id = $2`,
      [lostLikes, userId]
    );

    await client.query('COMMIT');
    return { success: true };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  listPrayers,
  createPrayer,
  toggleLike,
  deletePrayer,
};
