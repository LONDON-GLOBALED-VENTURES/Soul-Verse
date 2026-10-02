const { pool } = require('./index');

async function migrate() {
  console.log('Connecting to Neon PostgreSQL to run migrations...');

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
        likes_count INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
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

    // 4. Performance Indexes
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_prayers_created_at ON prayers(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_prayers_likes_count ON prayers(likes_count DESC);
      CREATE INDEX IF NOT EXISTS idx_prayers_category ON prayers(category);
      CREATE INDEX IF NOT EXISTS idx_prayer_likes_user ON prayer_likes(user_id);
    `);

    await client.query('COMMIT');
    console.log('✅ All tables and indexes created successfully on Neon PostgreSQL!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  migrate();
}

module.exports = migrate;
