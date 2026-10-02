const dbUser = require('../services/db-user.service');
const dbPrayer = require('../services/db-prayer.service');
const { pool } = require('./index');

async function testNeon() {
  console.log('--- Testing Live Neon PostgreSQL Integration ---');
  try {
    // 1. Create or Find User
    console.log('1. Creating test user in Neon...');
    const user = await dbUser.findOrCreateFromGoogle({
      googleId: 'neon_test_google_123',
      email: 'neon_tester@soulverse.app',
      name: 'Neon Tester',
      avatarUrl: 'https://example.com/avatar.jpg',
    });
    console.log('User created:', user.id, user.name, user.prayerStats.status.title);

    // 2. Create Prayer Request
    console.log('2. Creating prayer request in Neon...');
    const prayer = await dbPrayer.createPrayer({
      authorId: user.id,
      title: 'Testing Neon Database Connection',
      content: 'Lord bless this production database deployment and keep it fast and secure.',
      category: 'Gratitude & Praise',
      isAnonymous: false,
    });
    console.log('Prayer created:', prayer.id, prayer.title);

    // 3. List Prayers
    console.log('3. Querying prayer feed...');
    const feed = await dbPrayer.listPrayers({ currentUserId: user.id });
    console.log(`Feed contains ${feed.items.length} prayers. First: "${feed.items[0]?.title}"`);

    // 4. Toggle Like / Amen
    console.log('4. Praying / Liking request (Amen)...');
    const likeResult = await dbPrayer.toggleLike({ prayerId: prayer.id, userId: user.id });
    console.log('Like result:', likeResult);

    // 5. Clean up test prayer
    console.log('5. Deleting test prayer...');
    const delResult = await dbPrayer.deletePrayer({ prayerId: prayer.id, userId: user.id });
    console.log('Delete result:', delResult);

    console.log('🎉 ALL NEON POSTGRESQL INTEGRATION TESTS PASSED!');
  } catch (err) {
    console.error('Test failed:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

testNeon();
