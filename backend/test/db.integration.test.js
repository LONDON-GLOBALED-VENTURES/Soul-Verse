// Runs only against a throwaway Postgres: it DROPS ALL TABLES in that database.
//   TEST_DATABASE_URL=postgresql://user@localhost:5432/soulverse_test npm test
process.env.NODE_ENV = 'test';
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const testUrl = process.env.TEST_DATABASE_URL;
// Never against a hosted database: these tests wipe it.
const isLocal = /@(localhost|127\.0\.0\.1)[:/]/.test(testUrl || '');
const skip = !testUrl
  ? 'set TEST_DATABASE_URL to run database tests'
  : !isLocal && 'TEST_DATABASE_URL must point to localhost (these tests drop all tables)';

let pool;
let migrate;
let dbPrayer;
let dbUser;

const resetSchema = () => pool.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');

const columnsOf = async (table) =>
  (
    await pool.query(
      'SELECT column_name FROM information_schema.columns WHERE table_name = $1',
      [table],
    )
  ).rows.map((r) => r.column_name);

before(() => {
  if (skip) return;
  process.env.DATABASE_URL = testUrl;
  ({ pool } = require('../src/db'));
  migrate = require('../src/db/migrate');
  dbPrayer = require('../src/services/db-prayer.service');
  dbUser = require('../src/services/db-user.service');
});

after(async () => {
  if (pool) await pool.end();
});

test('migration creates the prayers.type column on a fresh database', { skip }, async () => {
  await resetSchema();
  await migrate();
  await migrate(); // idempotent

  assert.ok((await columnsOf('prayers')).includes('type'));
});

test('migration adds type to a database created before it existed', { skip }, async () => {
  await resetSchema();
  // The prayers table as the previous migration created it, without `type`.
  await pool.query(`
    CREATE TABLE users (id VARCHAR(128) PRIMARY KEY, email VARCHAR(255) UNIQUE NOT NULL);
    CREATE TABLE prayers (
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
    INSERT INTO users (id, email) VALUES ('u_old', 'old@example.com');
    INSERT INTO prayers (id, author_id, title, content) VALUES ('p_old', 'u_old', 'Old', 'Existing prayer');
  `);

  await migrate();

  const { rows } = await pool.query("SELECT type FROM prayers WHERE id = 'p_old'");
  assert.equal(rows[0].type, 'request');
});

test('creating a prayer stores and returns its type', { skip }, async () => {
  await resetSchema();
  await migrate();
  const user = await dbUser.findOrCreateFromGoogle({
    googleId: 'g1',
    email: 'tester@example.com',
    name: 'Tester',
    avatarUrl: '',
  });

  const praise = await dbPrayer.createPrayer({
    authorId: user.id,
    title: 'Answered prayer',
    content: 'Thank you Lord for answering our prayers.',
    type: 'praise',
  });
  assert.equal(praise.type, 'praise');

  const feed = await dbPrayer.listPrayers({ type: 'praise', currentUserId: user.id });
  assert.deepEqual(feed.items.map((p) => [p.id, p.type]), [[praise.id, 'praise']]);

  const requests = await dbPrayer.listPrayers({ type: 'request' });
  assert.equal(requests.total, 0);
});

test('deleting a user removes their prayers and likes and fixes the counts', { skip }, async () => {
  await resetSchema();
  await migrate();
  const newUser = (name) =>
    dbUser.findOrCreateFromGoogle({
      googleId: `g_${name}`,
      email: `${name}@example.com`,
      name,
      avatarUrl: '',
    });
  const anna = await newUser('anna');
  const ben = await newUser('ben');
  const prayer = (authorId, title) =>
    dbPrayer.createPrayer({ authorId, title, content: 'Please pray for strength this week.' });
  const annasPrayer = await prayer(anna.id, 'Anna needs prayer');
  const bensPrayer = await prayer(ben.id, 'Ben needs prayer');
  await dbPrayer.toggleLike({ prayerId: bensPrayer.id, userId: anna.id });
  await dbPrayer.toggleLike({ prayerId: annasPrayer.id, userId: ben.id });

  assert.equal(await dbUser.deleteUser(anna.id), true);

  assert.equal(await dbUser.findById(anna.id), null);
  const feed = await dbPrayer.listPrayers({ currentUserId: ben.id });
  assert.deepEqual(feed.items.map((p) => [p.id, p.likesCount]), [[bensPrayer.id, 0]]);
  assert.equal((await dbUser.findById(ben.id)).prayerStats.likesReceived, 0);
  const { rows } = await pool.query('SELECT COUNT(*)::int AS n FROM prayer_likes');
  assert.equal(rows[0].n, 0);

  assert.equal(await dbUser.deleteUser(anna.id), false, 'already gone');
});

test('reports, hiding and blocks shape each person\'s feed', { skip }, async () => {
  await resetSchema();
  await migrate();
  await migrate(); // still idempotent with the moderation tables
  const newUser = (name) =>
    dbUser.findOrCreateFromGoogle({ googleId: `g_${name}`, email: `${name}@example.com`, name, avatarUrl: '' });
  const anna = await newUser('anna');
  const ben = await newUser('ben');
  const carl = await newUser('carl');
  const annasPrayer = await dbPrayer.createPrayer({
    authorId: anna.id,
    title: 'Anna needs prayer',
    content: 'Please pray for strength this week.',
    isAnonymous: true,
  });
  const titles = async (userId) =>
    (await dbPrayer.listPrayers({ currentUserId: userId })).items.map((p) => p.title);

  // Other people never see the author's id; the author does.
  assert.equal((await dbPrayer.listPrayers({ currentUserId: ben.id })).items[0].authorId, '');
  assert.equal((await dbPrayer.listPrayers({ currentUserId: anna.id })).items[0].authorId, anna.id);

  assert.deepEqual(await dbPrayer.getPrayerAuthor(annasPrayer.id), {
    authorId: anna.id,
    isAnonymous: true,
    name: 'anna',
  });
  assert.equal(await dbPrayer.getPrayerAuthor('pry_missing'), null);

  // One report per person.
  assert.equal(await dbPrayer.addReport({ prayerId: annasPrayer.id, userId: ben.id, reason: 'spam', details: 'Ads' }), 1);
  assert.equal(await dbPrayer.addReport({ prayerId: annasPrayer.id, userId: ben.id, reason: 'spam', details: '' }), 1);
  const reported = await dbPrayer.listReported();
  assert.equal(reported.length, 1);
  assert.equal(reported[0].prayer.authorName, 'anna');
  assert.deepEqual(reported[0].reports.map((r) => [r.reason, r.details]), [['spam', 'Ads']]);

  assert.equal(await dbPrayer.setHidden(annasPrayer.id, true), true);
  assert.deepEqual(await titles(ben.id), []);
  assert.deepEqual(await titles(null), []);
  assert.deepEqual(await titles(anna.id), ['Anna needs prayer']);
  assert.equal((await dbPrayer.listPrayers({})).total, 0, 'the total matches too');

  assert.equal(await dbPrayer.setHidden(annasPrayer.id, false), true);
  assert.deepEqual(await dbPrayer.listReported(), [], 'restoring clears its reports');
  assert.equal(await dbPrayer.setHidden('pry_missing', true), false);

  await dbUser.addBlock(carl.id, anna.id, 'Anonymous Believer');
  await dbUser.addBlock(carl.id, anna.id, 'Anonymous Believer'); // no duplicate
  assert.deepEqual(await titles(carl.id), []);
  assert.deepEqual(await titles(ben.id), ['Anna needs prayer']);
  const blocks = await dbUser.listBlocks(carl.id);
  assert.deepEqual(blocks.map((b) => [b.userId, b.name]), [[anna.id, 'Anonymous Believer']]);

  await dbUser.removeBlock(carl.id, anna.id);
  assert.deepEqual(await titles(carl.id), ['Anna needs prayer']);

  // Deleting accounts removes their reports and blocks.
  await dbPrayer.addReport({ prayerId: annasPrayer.id, userId: ben.id, reason: 'other', details: '' });
  await dbUser.addBlock(carl.id, anna.id, 'Anonymous Believer');
  await dbUser.deleteUser(ben.id);
  assert.deepEqual(await dbPrayer.listReported(), []);
  await dbUser.deleteUser(anna.id);
  assert.deepEqual(await dbUser.listBlocks(carl.id), []);
});
