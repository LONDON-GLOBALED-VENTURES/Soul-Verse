process.env.NODE_ENV = 'test';
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const verseService = require('../src/services/verse.service');

// Tests use their own verses so they don't depend on (or break with) the real data file.
const sampleVerses = ['a', 'b', 'c'].map((id) => ({
  id: `v-${id}`,
  text: `Verse ${id}`,
  reference: `Ref ${id}`,
  translation: 'KJV',
  moods: ['thankful'],
  reflection: `Reflection ${id}`,
}));

let server;
let baseUrl;

before(async () => {
  verseService._setVersesForTests(sampleVerses);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}/api`;
});

after(() => new Promise((resolve) => server.close(resolve)));

const get = async (path) => {
  const res = await fetch(`${baseUrl}${path}`);
  return { status: res.status, body: await res.json() };
};

test('health check responds ok', async () => {
  const { status, body } = await get('/health');
  assert.equal(status, 200);
  assert.equal(body.status, 'ok');
});

test('daily verse for a given date is stable and has an image URL', async () => {
  const first = await get('/verses/daily?date=2026-10-01');
  const again = await get('/verses/daily?date=2026-10-01');

  assert.equal(first.status, 200);
  assert.equal(first.body.date, '2026-10-01');
  assert.deepEqual(first.body, again.body);
  assert.match(first.body.template.imageUrl, /^http:\/\/.+\/static\/images\/.+\.png$/);
  assert.equal(first.body.template.imagePath, undefined);
});

test('consecutive dates get different verses', async () => {
  const a = await get('/verses/daily?date=2026-10-01');
  const b = await get('/verses/daily?date=2026-10-02');
  assert.notEqual(a.body.verse.id, b.body.verse.id);
});

test('daily verse without a date defaults to today (UTC)', async () => {
  const { status, body } = await get('/verses/daily');
  assert.equal(status, 200);
  assert.equal(body.date, new Date().toISOString().slice(0, 10));
});

test('invalid dates are rejected with 400', async () => {
  for (const date of ['2026-02-30', '2026-13-01', '01-10-2026', 'tomorrow']) {
    const { status, body } = await get(`/verses/daily?date=${date}`);
    assert.equal(status, 400, `expected 400 for ${date}`);
    assert.match(body.message, /Invalid date/);
  }
});

test('range returns consecutive days matching the single-day endpoint', async () => {
  const { status, body } = await get('/verses/daily/range?start=2026-12-30&days=4');

  assert.equal(status, 200);
  assert.deepEqual(
    body.map((entry) => entry.date),
    ['2026-12-30', '2026-12-31', '2027-01-01', '2027-01-02'],
  );
  const single = await get('/verses/daily?date=2027-01-01');
  assert.deepEqual(body[2], single.body);
});

test('range validates start and days', async () => {
  assert.equal((await get('/verses/daily/range?start=bad&days=3')).status, 400);
  for (const days of ['0', '32', '1.5', 'x', '']) {
    const { status } = await get(`/verses/daily/range?start=2026-10-01&days=${days}`);
    assert.equal(status, 400, `expected 400 for days=${days}`);
  }
});

test('the API is served only under /api; root keeps info and health', async () => {
  const root = baseUrl.replace(/\/api$/, '');

  assert.equal((await fetch(`${root}/verses/daily`)).status, 404);
  assert.equal((await fetch(`${root}/prayers`)).status, 404);
  assert.equal((await fetch(`${baseUrl}/verses/daily`)).status, 200);

  const health = await fetch(`${root}/health`);
  assert.equal(health.status, 200);
  assert.equal((await health.json()).status, 'ok');

  const info = await (await fetch(`${root}/`)).json();
  assert.equal(info.endpoints.prayers, '/api/prayers');
});

test('with no verses, the daily verse is a clear 404 and the range is empty', async () => {
  verseService._setVersesForTests([]);
  try {
    const daily = await get('/verses/daily?date=2026-10-01');
    assert.equal(daily.status, 404);
    assert.equal(daily.body.message, 'No verses available yet');

    const range = await get('/verses/daily/range?start=2026-10-01&days=7');
    assert.equal(range.status, 200);
    assert.deepEqual(range.body, []);

    const mood = await get('/verses?mood=thankful');
    assert.deepEqual(mood.body, []);
  } finally {
    verseService._setVersesForTests(sampleVerses);
  }
});

test('with no verses, invalid dates are still rejected with 400', async () => {
  verseService._setVersesForTests([]);
  try {
    assert.equal((await get('/verses/daily?date=2026-02-30')).status, 400);
    assert.equal((await get('/verses/daily/range?start=2026-10-01&days=0')).status, 400);
  } finally {
    verseService._setVersesForTests(sampleVerses);
  }
});

test('emotions come with an emoji and colour, and each has a free background', async () => {
  const moods = (await get('/moods')).body;
  const templates = (await get('/templates')).body;

  assert.equal(moods.length, 11);
  for (const mood of moods) {
    assert.ok(mood.emoji, `${mood.id} has an emoji`);
    assert.match(mood.color, /^#[0-9A-F]{6}$/i, `${mood.id} has a colour`);
    const free = templates.filter((t) => !t.isPremium && t.moods.includes(mood.id));
    // Without one, the mood's page has nothing to draw verses on.
    assert.ok(free.length > 0, `${mood.id} has a free background`);
  }
});

test('image URLs use https when the request came through an https proxy', async () => {
  // Cloud Run ends HTTPS at its proxy and forwards plain HTTP with this header.
  const res = await fetch(`${baseUrl}/templates`, {
    headers: { 'X-Forwarded-Proto': 'https' },
  });
  const [template] = await res.json();
  assert.match(template.imageUrl, /^https:\/\//);
});

test('templates only reference emotions that exist', async () => {
  const ids = new Set((await get('/moods')).body.map((m) => m.id));
  for (const template of (await get('/templates')).body) {
    for (const mood of template.moods) assert.ok(ids.has(mood), `${template.id}: ${mood}`);
  }
});

test('unknown routes return a JSON 404', async () => {
  const { status, body } = await get('/nope');
  assert.equal(status, 404);
  assert.match(body.message, /Route not found/);
});
