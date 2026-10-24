process.env.NODE_ENV = 'test';
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');

let server;
let baseUrl;

before(async () => {
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

test('unknown routes return a JSON 404', async () => {
  const { status, body } = await get('/nope');
  assert.equal(status, 404);
  assert.match(body.message, /Route not found/);
});
