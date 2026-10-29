process.env.NODE_ENV = 'test';
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const userService = require('../src/services/user.service');
const prayerService = require('../src/services/prayer.service');
const { signAccessToken } = require('../src/utils/token');

let server;
let origin;

before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  origin = `http://127.0.0.1:${server.address().port}`;
});

after(() => new Promise((resolve) => server.close(resolve)));

beforeEach(() => {
  userService._resetForTests([]);
  prayerService._resetForTests([]);
});

const api = (path, { method = 'GET', token, body } = {}) =>
  fetch(`${origin}/api${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

const signIn = async (email, name) => {
  const user = await userService.findOrCreateFromGoogle({
    googleId: `google_${email}`,
    email,
    name,
    avatarUrl: '',
  });
  return { user, token: signAccessToken(user) };
};

const sharePrayer = async (token, title) => {
  const res = await api('/prayers', {
    method: 'POST',
    token,
    body: { title, content: 'Please pray for strength this week.', category: 'General' },
  });
  return (await res.json()).data;
};

test('deleting an account needs a signed-in user', async () => {
  const res = await api('/auth/me', { method: 'DELETE' });
  assert.equal(res.status, 401);
});

test('deleting an account removes the user, their prayers and their likes', async () => {
  const anna = await signIn('anna@example.com', 'Anna');
  const ben = await signIn('ben@example.com', 'Ben');
  const annasPrayer = await sharePrayer(anna.token, 'Anna needs prayer');
  const bensPrayer = await sharePrayer(ben.token, 'Ben needs prayer');
  // Anna prays for Ben's request and Ben for Anna's.
  await api(`/prayers/${bensPrayer.id}/like`, { method: 'POST', token: anna.token });
  await api(`/prayers/${annasPrayer.id}/like`, { method: 'POST', token: ben.token });
  assert.equal((await userService.findById(ben.user.id)).prayerStats.likesReceived, 1);

  const res = await api('/auth/me', { method: 'DELETE', token: anna.token });
  assert.equal(res.status, 204);

  assert.equal(await userService.findById(anna.user.id), null);
  const feed = (await (await api('/prayers', { token: ben.token })).json()).data;
  assert.deepEqual(
    feed.items.map((p) => p.id),
    [bensPrayer.id],
    "Anna's prayer is gone",
  );
  assert.equal(feed.items[0].likesCount, 0, "Anna's like is taken off Ben's prayer");
  assert.equal(
    (await userService.findById(ben.user.id)).prayerStats.likesReceived,
    0,
    "and off Ben's count",
  );
});

test("a deleted account's sign-in stops working", async () => {
  const anna = await signIn('anna@example.com', 'Anna');
  await api('/auth/me', { method: 'DELETE', token: anna.token });

  const res = await api('/auth/me', { token: anna.token });
  assert.equal(res.status, 401);
});

test('the account deletion page explains how to delete and who to email', async () => {
  const res = await fetch(`${origin}/delete-account`);
  assert.equal(res.status, 200);
  assert.match(res.headers.get('content-type'), /text\/html/);
  const page = await res.text();
  assert.match(page, /Delete account/);
  assert.match(page, /mailto:support@example\.com/);
  assert.doesNotMatch(page, /{{SUPPORT_EMAIL}}/);
});
