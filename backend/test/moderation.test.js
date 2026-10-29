process.env.NODE_ENV = 'test';
process.env.ADMIN_API_KEY = 'test-admin-key';
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

const api = async (path, { method = 'GET', token, body, headers = {} } = {}) => {
  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  // Some responses (e.g. account deletion's 204) have no body.
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
};

const signIn = async (name) => {
  const user = await userService.findOrCreateFromGoogle({
    googleId: `google_${name}`,
    email: `${name}@example.com`,
    name,
    avatarUrl: '',
  });
  return { user, token: signAccessToken(user) };
};

const share = async (token, title, extra = {}) =>
  (
    await api('/prayers', {
      method: 'POST',
      token,
      body: { title, content: 'Please pray for strength this week.', ...extra },
    })
  ).body.data;

const feedTitles = async (token) =>
  (await api('/prayers', { token })).body.data.items.map((p) => p.title);

const report = (token, prayerId, reason = 'spam', details) =>
  api(`/prayers/${prayerId}/report`, { method: 'POST', token, body: { reason, details } });

test('reporting needs a sign-in, a valid reason and someone else\'s prayer', async () => {
  const anna = await signIn('anna');
  const ben = await signIn('ben');
  const prayer = await share(anna.token, 'Anna needs prayer');

  assert.equal((await report(null, prayer.id)).status, 401);
  assert.equal((await report(ben.token, prayer.id, 'boring')).status, 400);
  assert.equal((await report(ben.token, prayer.id, 'other', 'x'.repeat(501))).status, 400);
  assert.equal((await report(anna.token, prayer.id)).status, 400, 'not your own');
  assert.equal((await report(ben.token, 'pry_missing')).status, 404);

  const ok = await report(ben.token, prayer.id, 'offensive', 'Unkind words');
  assert.equal(ok.status, 200);
  assert.deepEqual(ok.body.data, { hidden: false });
});

test('a prayer reported by 3 different people is hidden, except from its author', async () => {
  const author = await signIn('author');
  const readers = await Promise.all(['r1', 'r2', 'r3', 'r4'].map(signIn));
  const prayer = await share(author.token, 'Reported prayer');

  await report(readers[0].token, prayer.id);
  // Reporting twice still counts once.
  await report(readers[0].token, prayer.id);
  assert.deepEqual((await report(readers[1].token, prayer.id)).body.data, { hidden: false });
  assert.deepEqual((await report(readers[2].token, prayer.id)).body.data, { hidden: true });

  assert.deepEqual(await feedTitles(readers[3].token), []);
  assert.deepEqual(await feedTitles(null), [], 'guests too');
  assert.deepEqual(await feedTitles(author.token), ['Reported prayer']);
});

test('blocking hides that person\'s prayers until unblocked', async () => {
  const anna = await signIn('anna');
  const ben = await signIn('ben');
  const annasPrayer = await share(anna.token, 'Anna needs prayer');
  await share(ben.token, 'Ben needs prayer');

  assert.equal(
    (await api(`/prayers/${annasPrayer.id}/block-author`, { method: 'POST' })).status,
    401,
  );
  const blocked = await api(`/prayers/${annasPrayer.id}/block-author`, {
    method: 'POST',
    token: ben.token,
  });
  assert.equal(blocked.status, 200);
  assert.deepEqual(await feedTitles(ben.token), ['Ben needs prayer']);
  // Only Ben's feed changes.
  assert.equal((await feedTitles(anna.token)).length, 2);

  const blocks = (await api('/users/me/blocks', { token: ben.token })).body.data.items;
  assert.equal(blocks.length, 1);
  assert.equal(blocks[0].name, 'anna');

  const unblocked = await api(`/users/me/blocks/${blocks[0].userId}`, {
    method: 'DELETE',
    token: ben.token,
  });
  assert.equal(unblocked.status, 200);
  assert.equal((await feedTitles(ben.token)).length, 2);
  assert.deepEqual((await api('/users/me/blocks', { token: ben.token })).body.data.items, []);
});

test('blocking an anonymous author never reveals who they are', async () => {
  const anna = await signIn('anna');
  const ben = await signIn('ben');
  const secret = await share(anna.token, 'Anonymous request', { isAnonymous: true });
  const named = await share(anna.token, 'Named request');

  // Other people's prayers never carry the author's id.
  const feed = (await api('/prayers', { token: ben.token })).body.data.items;
  assert.ok(feed.every((p) => p.authorId === ''));
  const own = (await api('/prayers', { token: anna.token })).body.data.items;
  assert.ok(own.every((p) => p.authorId === anna.user.id));

  await api(`/prayers/${secret.id}/block-author`, { method: 'POST', token: ben.token });
  const blocks = (await api('/users/me/blocks', { token: ben.token })).body.data.items;
  assert.equal(blocks[0].name, 'Anonymous Believer');
  // The block covers all of that person's prayers.
  assert.deepEqual(await feedTitles(ben.token), []);
  assert.ok(named);
});

test('you can\'t block yourself', async () => {
  const anna = await signIn('anna');
  const prayer = await share(anna.token, 'Anna needs prayer');
  const res = await api(`/prayers/${prayer.id}/block-author`, { method: 'POST', token: anna.token });
  assert.equal(res.status, 400);
});

test('moderators review reports and can hide or restore prayers with the admin key', async () => {
  const anna = await signIn('anna');
  const ben = await signIn('ben');
  const prayer = await share(anna.token, 'Anna needs prayer');
  await report(ben.token, prayer.id, 'harassment', 'Targets someone');

  assert.equal((await api('/admin/reports')).status, 401);
  assert.equal((await api('/admin/reports', { headers: { 'X-Admin-Key': 'wrong' } })).status, 401);

  const admin = { 'X-Admin-Key': 'test-admin-key' };
  const reports = (await api('/admin/reports', { headers: admin })).body.data.items;
  assert.equal(reports.length, 1);
  assert.equal(reports[0].prayer.title, 'Anna needs prayer');
  assert.equal(reports[0].prayer.authorName, 'anna');
  assert.deepEqual(
    reports[0].reports.map((r) => [r.reason, r.details]),
    [['harassment', 'Targets someone']],
  );

  await api(`/admin/prayers/${prayer.id}/hide`, { method: 'POST', headers: admin });
  assert.deepEqual(await feedTitles(ben.token), []);

  await api(`/admin/prayers/${prayer.id}/restore`, { method: 'POST', headers: admin });
  assert.deepEqual(await feedTitles(ben.token), ['Anna needs prayer']);
  // Restoring clears its reports.
  assert.deepEqual((await api('/admin/reports', { headers: admin })).body.data.items, []);

  const missing = await api('/admin/prayers/pry_missing/hide', { method: 'POST', headers: admin });
  assert.equal(missing.status, 404);
});

test('deleting an account removes its reports and blocks', async () => {
  const anna = await signIn('anna');
  const ben = await signIn('ben');
  const carl = await signIn('carl');
  const annasPrayer = await share(anna.token, 'Anna needs prayer');
  const carlsPrayer = await share(carl.token, 'Carl needs prayer');
  await report(ben.token, annasPrayer.id);
  await api(`/prayers/${carlsPrayer.id}/block-author`, { method: 'POST', token: anna.token });
  await api(`/prayers/${annasPrayer.id}/block-author`, { method: 'POST', token: carl.token });

  await api('/auth/me', { method: 'DELETE', token: ben.token });
  await api('/auth/me', { method: 'DELETE', token: anna.token });

  const admin = { 'X-Admin-Key': 'test-admin-key' };
  assert.deepEqual((await api('/admin/reports', { headers: admin })).body.data.items, []);
  assert.deepEqual((await api('/users/me/blocks', { token: carl.token })).body.data.items, []);
});
