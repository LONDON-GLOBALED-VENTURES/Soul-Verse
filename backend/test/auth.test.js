process.env.NODE_ENV = 'test';
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

beforeEach(() => {
  userService._resetForTests([]);
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

test('google login rejects missing idToken', async () => {
  const { status, body } = await post('/auth/google', {});
  assert.equal(status, 400);
  assert.match(body.message, /idToken is required/);
});

test('google login creates a new user and returns tokens with free subscription', async () => {
  const mockToken = 'mock-google-token:john@gmail.com:John Doe:google_12345';
  const { status, body } = await post('/auth/google', { idToken: mockToken });

  assert.equal(status, 200);
  assert.ok(body.accessToken);
  assert.ok(body.refreshToken);
  assert.equal(body.user.email, 'john@gmail.com');
  assert.equal(body.user.name, 'John Doe');
  assert.equal(body.user.googleId, 'google_12345');
  assert.deepEqual(body.user.subscription, {
    status: 'free',
    tier: 'none',
    purchaseToken: null,
    expiresAt: null,
  });
});

test('google login updates existing user without creating duplicates', async () => {
  const mockToken = 'mock-google-token:john@gmail.com:John Doe:google_12345';
  const res1 = await post('/auth/google', { idToken: mockToken });
  assert.equal(res1.status, 200);
  const userId = res1.body.user.id;

  // Log in again with updated name
  const updatedToken = 'mock-google-token:john@gmail.com:John Updated:google_12345';
  const res2 = await post('/auth/google', { idToken: updatedToken });
  assert.equal(res2.status, 200);
  assert.equal(res2.body.user.id, userId);
  assert.equal(res2.body.user.name, 'John Updated');
});

test('getMe requires authentication', async () => {
  const { status, body } = await get('/auth/me');
  assert.equal(status, 401);
  assert.match(body.message, /Authorization header/);
});

test('getMe returns user profile with valid Bearer token', async () => {
  const mockToken = 'mock-google-token:alice@gmail.com:Alice:google_alice';
  const loginRes = await post('/auth/google', { idToken: mockToken });
  assert.equal(loginRes.status, 200);

  const { status, body } = await get('/auth/me', {
    Authorization: `Bearer ${loginRes.body.accessToken}`,
  });

  assert.equal(status, 200);
  assert.equal(body.user.email, 'alice@gmail.com');
  assert.equal(body.user.name, 'Alice');
  assert.equal(body.user.subscription.status, 'free');
});

test('refresh rotates access token', async () => {
  const mockToken = 'mock-google-token:bob@gmail.com:Bob:google_bob';
  const loginRes = await post('/auth/google', { idToken: mockToken });
  assert.equal(loginRes.status, 200);

  const { status, body } = await post('/auth/refresh', {
    refreshToken: loginRes.body.refreshToken,
  });

  assert.equal(status, 200);
  assert.ok(body.accessToken);

  // New access token works for /auth/me
  const meRes = await get('/auth/me', {
    Authorization: `Bearer ${body.accessToken}`,
  });
  assert.equal(meRes.status, 200);
  assert.equal(meRes.body.user.email, 'bob@gmail.com');
});

test('refresh rejects invalid refresh token', async () => {
  const { status, body } = await post('/auth/refresh', {
    refreshToken: 'invalid-token',
  });
  assert.equal(status, 401);
  assert.match(body.message, /Invalid or expired/);
});

