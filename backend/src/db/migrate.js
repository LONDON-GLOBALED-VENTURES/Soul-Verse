const { pool } = require('./index');

// Idempotent: safe to run on a fresh database and on one created by an older version.
async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Users Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(128) PRIMARY KEY,
        google_id VARCHAR(255) UNIQUE,
        email VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255) DEFAULT '',
        avatar_url TEXT DEFAULT '',
        subscription_status VARCHAR(50) DEFAULT 'free',
        subscription_tier VARCHAR(50) DEFAULT 'none',
        subscription_purchase_token TEXT,
        subscription_expires_at TIMESTAMPTZ,
        prayers_shared INTEGER DEFAULT 0,
        likes_received INTEGER DEFAULT 0,
        likes_given INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        last_login_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // 2. Prayers Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS prayers (
        id VARCHAR(128) PRIMARY KEY,
        author_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
        author_name VARCHAR(255) DEFAULT 'Believer',
        author_avatar TEXT DEFAULT '',
        is_anonymous BOOLEAN DEFAULT FALSE,
        title VARCHAR(150) NOT NULL,
        content TEXT NOT NULL,
        category VARCHAR(100) DEFAULT 'General',
        type VARCHAR(20) NOT NULL DEFAULT 'request',
        likes_count INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // 2b. Databases created before `type` existed: CREATE TABLE IF NOT EXISTS skips them.
    await client.query(`
      ALTER TABLE prayers ADD COLUMN IF NOT EXISTS type VARCHAR(20) NOT NULL DEFAULT 'request';
    `);

    // 3. Prayer Likes Table (Unique constraint prevents duplicate likes)
    await client.query(`
      CREATE TABLE IF NOT EXISTS prayer_likes (
        prayer_id VARCHAR(128) REFERENCES prayers(id) ON DELETE CASCADE,
        user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        PRIMARY KEY (prayer_id, user_id)
      );
    `);

    // 3b. Moderation: hidden prayers, reports and blocks (all removed with their user or prayer).
    await client.query(`
      ALTER TABLE prayers ADD COLUMN IF NOT EXISTS hidden_at TIMESTAMPTZ;

      CREATE TABLE IF NOT EXISTS prayer_reports (
        prayer_id VARCHAR(128) REFERENCES prayers(id) ON DELETE CASCADE,
        reporter_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
        reason VARCHAR(20) NOT NULL,
        details TEXT NOT NULL DEFAULT '',
        created_at TIMESTAMPTZ DEFAULT NOW(),
        PRIMARY KEY (prayer_id, reporter_id)
      );

      CREATE TABLE IF NOT EXISTS user_blocks (
        blocker_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
        blocked_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
        label VARCHAR(255) NOT NULL DEFAULT '',
        created_at TIMESTAMPTZ DEFAULT NOW(),
        PRIMARY KEY (blocker_id, blocked_id)
      );
    `);

    // 4. Performance Indexes
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_prayers_created_at ON prayers(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_prayers_likes_count ON prayers(likes_count DESC);
      CREATE INDEX IF NOT EXISTS idx_prayers_category ON prayers(category);
      CREATE INDEX IF NOT EXISTS idx_prayers_type ON prayers(type);
      CREATE INDEX IF NOT EXISTS idx_prayer_likes_user ON prayer_likes(user_id);
      CREATE INDEX IF NOT EXISTS idx_prayer_reports_created_at ON prayer_reports(created_at DESC);
    `);

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

if (require.main === module) {
  console.log('Running database migrations...');
  migrate()
    .then(() => console.log('✅ All tables and indexes are up to date.'))
    .catch((err) => {
      console.error('❌ Migration failed:', err);
      process.exitCode = 1;
    })
    .finally(() => pool.end());
}

module.exports = migrate;
