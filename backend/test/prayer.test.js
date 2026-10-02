process.env.NODE_ENV = 'test';
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const userService = require('../src/services/user.service');
const prayerService = require('../src/services/prayer.service');
const { signAccessToken } = require('../src/utils/token');

let server;
let baseUrl;

before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}/api`;
});

after(() => new Promise((resolve) => server.close(resolve)));

beforeEach(() => {
  userService._resetForTests([]);
  prayerService._resetForTests([]);
});

const post = async (path, body, headers = {}) => {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
};

const get = async (path, headers = {}) => {
  const res = await fetch(`${baseUrl}${path}`, {
    headers: { 'Content-Type': 'application/json', ...headers },
  });
  return { status: res.status, body: await res.json() };
};

const del = async (path, headers = {}) => {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json', ...headers },
  });
  return { status: res.status, body: await res.json() };
};

const createTestUser = async (email = 'warrior@example.com', name = 'Faithful Believer') => {
  return await userService.findOrCreateFromGoogle({
    googleId: `google_${email}`,
    email,
    name,
    avatarUrl: 'https://example.com/avatar.png',
  });
};

test('GET /prayers returns empty list initially', async () => {
  const { status, body } = await get('/prayers');
  assert.equal(status, 200);
  assert.equal(body.success, true);
  assert.equal(body.data.items.length, 0);
  assert.equal(body.data.total, 0);
});

test('POST /prayers requires authentication', async () => {
  const { status } = await post('/prayers', {
    title: 'Test prayer',
    content: 'Please pray for my exams this week',
    category: 'Guidance',
  });
  assert.equal(status, 401);
});

test('POST /prayers validates input fields', async () => {
  const user = await createTestUser();
  const token = signAccessToken(user);
  const authHeader = { Authorization: `Bearer ${token}` };

  // Too short title
  const res1 = await post('/prayers', { title: 'Hi', content: 'Valid content here' }, authHeader);
  assert.equal(res1.status, 400);

  // Too short content
  const res2 = await post('/prayers', { title: 'Valid Title', content: 'Short' }, authHeader);
  assert.equal(res2.status, 400);
});

test('POST /prayers creates prayer and increments user prayersShared', async () => {
  const user = await createTestUser();
  const token = signAccessToken(user);
  const authHeader = { Authorization: `Bearer ${token}` };

  const { status, body } = await post(
    '/prayers',
    {
      title: 'Strength for recovery',
      content: 'Praying for swift recovery after surgery.',
      category: 'Healing',
      isAnonymous: false,
    },
    authHeader
  );

  assert.equal(status, 201);
  assert.equal(body.data.title, 'Strength for recovery');
  assert.equal(body.data.category, 'Healing');
  assert.equal(body.data.authorName, 'Faithful Believer');
  assert.equal(body.data.authorStatusLevel, 'Seeker');
  assert.equal(body.data.isMine, true);

  const updatedUser = await userService.findById(user.id);
  assert.equal(updatedUser.prayerStats.prayersShared, 1);
});

test('POST /prayers supports anonymous sharing', async () => {
  const user = await createTestUser();
  const token = signAccessToken(user);
  const authHeader = { Authorization: `Bearer ${token}` };

  const { status, body } = await post(
    '/prayers',
    {
      title: 'Private prayer request',
      content: 'Seeking guidance through a very difficult situation.',
      category: 'Guidance',
      isAnonymous: true,
    },
    authHeader
  );

  assert.equal(status, 201);
  assert.equal(body.data.isAnonymous, true);
  assert.equal(body.data.authorName, 'Anonymous Believer');
  assert.equal(body.data.authorAvatar, '');
});

test('POST /prayers/:id/like toggles like and updates author status to Believer and Prayer Warrior', async () => {
  const author = await createTestUser('author@example.com', 'Author User');
  const authorToken = signAccessToken(author);

  const { body: created } = await post(
    '/prayers',
    {
      title: 'Peace in our hearts',
      content: 'Praying for peace in our city and families.',
      category: 'Peace',
    },
    { Authorization: `Bearer ${authorToken}` }
  );

  const prayerId = created.data.id;

  // Liker 1 likes prayer
  const liker1 = await createTestUser('liker1@example.com', 'Liker One');
  const liker1Token = signAccessToken(liker1);

  const resLike = await post(`/prayers/${prayerId}/like`, {}, { Authorization: `Bearer ${liker1Token}` });
  assert.equal(resLike.status, 200);
  assert.equal(resLike.body.data.isLiked, true);
  assert.equal(resLike.body.data.likesCount, 1);

  // Author received 1 like
  let updatedAuthor = await userService.findById(author.id);
  assert.equal(updatedAuthor.prayerStats.likesReceived, 1);
  assert.equal(updatedAuthor.prayerStats.status.title, 'Seeker');

  // Liker 1 unlikes prayer
  const resUnlike = await post(`/prayers/${prayerId}/like`, {}, { Authorization: `Bearer ${liker1Token}` });
  assert.equal(resUnlike.body.data.isLiked, false);
  assert.equal(resUnlike.body.data.likesCount, 0);

  updatedAuthor = await userService.findById(author.id);
  assert.equal(updatedAuthor.prayerStats.likesReceived, 0);

  // Directly adjust author likes to 49, then add 1 like to hit 50 (Prayer Warrior)
  await userService.adjustPrayerStats(author.id, { likesReceivedDelta: 49 });
  updatedAuthor = await userService.findById(author.id);
  assert.equal(updatedAuthor.prayerStats.likesReceived, 49);
  assert.equal(updatedAuthor.prayerStats.status.title, 'Faithful Servant');

  // 50th like triggers status upgrade to Prayer Warrior!
  const resWarrior = await post(`/prayers/${prayerId}/like`, {}, { Authorization: `Bearer ${liker1Token}` });
  assert.equal(resWarrior.body.data.isLiked, true);
  assert.equal(resWarrior.body.data.authorStatus.title, 'Prayer Warrior');
  assert.equal(resWarrior.body.data.authorStatus.emoji, '⚔️');

  updatedAuthor = await userService.findById(author.id);
  assert.equal(updatedAuthor.prayerStats.status.title, 'Prayer Warrior');
  assert.equal(updatedAuthor.prayerStats.status.emoji, '⚔️');
});

test('DELETE /prayers/:id allows author to delete and blocks non-authors', async () => {
  const author = await createTestUser('author2@example.com', 'Author');
  const authorToken = signAccessToken(author);

  const stranger = await createTestUser('stranger@example.com', 'Stranger');
  const strangerToken = signAccessToken(stranger);

  const { body: created } = await post(
    '/prayers',
    {
      title: 'Family blessing',
      content: 'May God protect and bless our family.',
      category: 'Family',
    },
    { Authorization: `Bearer ${authorToken}` }
  );

  const prayerId = created.data.id;

  // Stranger tries to delete -> 403
  const resStranger = await del(`/prayers/${prayerId}`, { Authorization: `Bearer ${strangerToken}` });
  assert.equal(resStranger.status, 403);

  // Author deletes -> 200
  const resAuthor = await del(`/prayers/${prayerId}`, { Authorization: `Bearer ${authorToken}` });
  assert.equal(resAuthor.status, 200);

  // Verify it is gone
  const { body: list } = await get('/prayers');
  assert.equal(list.data.items.length, 0);
});
