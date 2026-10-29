process.env.NODE_ENV = 'test';
process.env.REVENUECAT_WEBHOOK_SECRET = 'test-webhook-secret';
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const userService = require('../src/services/user.service');

let server;
let baseUrl;

before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}/api`;
});

after(() => new Promise((resolve) => server.close(resolve)));

beforeEach(() => userService._resetForTests([]));

const EXPIRES_MS = Date.parse('2026-12-01T10:00:00.000Z');

const send = async (event, authorization = 'test-webhook-secret') => {
  const res = await fetch(`${baseUrl}/billing/revenuecat-webhook`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(authorization ? { Authorization: authorization } : {}),
    },
    body: JSON.stringify({ api_version: '1.0', event }),
  });
  return { status: res.status, body: await res.json() };
};

const createUser = (name) =>
  userService.findOrCreateFromGoogle({
    googleId: `google_${name}`,
    email: `${name}@example.com`,
    name,
    avatarUrl: '',
  });

const subscriptionOf = async (user) => (await userService.findById(user.id)).subscription;

const event = (type, user, extra = {}) => ({
  type,
  app_user_id: user.id,
  product_id: 'soulverse_premium_monthly',
  entitlement_ids: ['premium'],
  expiration_at_ms: EXPIRES_MS,
  ...extra,
});

test('the webhook needs the configured secret', async () => {
  const anna = await createUser('anna');
  assert.equal((await send(event('INITIAL_PURCHASE', anna), null)).status, 401);
  assert.equal((await send(event('INITIAL_PURCHASE', anna), 'wrong-secret')).status, 401);
  assert.equal((await subscriptionOf(anna)).status, 'free');

  const withBearer = await send(event('INITIAL_PURCHASE', anna), 'Bearer test-webhook-secret');
  assert.equal(withBearer.status, 200);
  assert.equal((await subscriptionOf(anna)).status, 'active');
});

test('a purchase, renewal and uncancellation make the subscription active until expiry', async () => {
  for (const type of ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'SUBSCRIPTION_EXTENDED']) {
    userService._resetForTests([]);
    const anna = await createUser('anna');
    const res = await send(event(type, anna));
    assert.equal(res.status, 200, type);
    assert.deepEqual(res.body.data, { applied: true }, type);
    assert.deepEqual(
      await subscriptionOf(anna),
      { status: 'active', tier: 'premium', purchaseToken: null, expiresAt: '2026-12-01T10:00:00.000Z' },
      type,
    );
  }
});

test('cancelling keeps Premium until expiry, and expiring returns to free', async () => {
  const anna = await createUser('anna');
  await send(event('INITIAL_PURCHASE', anna));

  await send(event('CANCELLATION', anna));
  const cancelled = await subscriptionOf(anna);
  assert.equal(cancelled.status, 'cancelled');
  assert.equal(cancelled.tier, 'premium');
  assert.equal(cancelled.expiresAt, '2026-12-01T10:00:00.000Z');

  await send(event('EXPIRATION', anna));
  const expired = await subscriptionOf(anna);
  assert.equal(expired.status, 'free');
  assert.equal(expired.tier, 'none');
});

test('the user is found through the original id or an alias', async () => {
  const anna = await createUser('anna');
  const res = await send(
    event('INITIAL_PURCHASE', anna, {
      app_user_id: '$RCAnonymousID:abc123',
      aliases: ['$RCAnonymousID:abc123', anna.id],
    }),
  );
  assert.deepEqual(res.body.data, { applied: true });
  assert.equal((await subscriptionOf(anna)).status, 'active');
});

test('a transfer moves Premium to the other account', async () => {
  const anna = await createUser('anna');
  const ben = await createUser('ben');
  await send(event('INITIAL_PURCHASE', anna));

  const res = await send({ type: 'TRANSFER', transferred_from: [anna.id], transferred_to: [ben.id] });
  assert.deepEqual(res.body.data, { applied: true });
  assert.equal((await subscriptionOf(anna)).status, 'free');
  assert.equal((await subscriptionOf(ben)).status, 'active');
});

test('unknown users and other events are acknowledged without changes', async () => {
  const anna = await createUser('anna');

  const unknown = await send(event('INITIAL_PURCHASE', { id: 'usr_deleted' }));
  assert.equal(unknown.status, 200, 'a 200 stops RevenueCat retrying');
  assert.deepEqual(unknown.body.data, { applied: false });

  for (const type of ['TEST', 'BILLING_ISSUE', 'PRODUCT_CHANGE']) {
    const res = await send(event(type, anna));
    assert.equal(res.status, 200, type);
    assert.deepEqual(res.body.data, { applied: false }, type);
  }
  assert.equal((await subscriptionOf(anna)).status, 'free');

  const noEvent = await send(undefined);
  assert.equal(noEvent.status, 200);
  assert.deepEqual(noEvent.body.data, { applied: false });
});
