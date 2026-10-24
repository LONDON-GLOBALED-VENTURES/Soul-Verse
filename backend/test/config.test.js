const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const os = require('node:os');
const path = require('node:path');

const SRC = path.join(__dirname, '..', 'src');
const STRONG_A = 'a'.repeat(40);
const STRONG_B = 'b'.repeat(40);

/**
 * Loads config (and optionally runs a snippet) in a fresh process with exactly [env].
 * Runs from the temp dir so the developer's own backend/.env can't leak in.
 */
const run = (env, snippet = '') => {
  const script = `
    const config = require(${JSON.stringify(path.join(SRC, 'config', 'env.js'))});
    ${snippet}
    console.log(JSON.stringify({ nodeEnv: config.nodeEnv, mock: config.allowMockGoogleAuth }));
  `;
  const result = spawnSync(process.execPath, ['-e', script], {
    cwd: os.tmpdir(),
    env: { PATH: process.env.PATH, SystemRoot: process.env.SystemRoot, ...env },
    encoding: 'utf8',
  });
  const out = result.stdout.trim().split('\n').pop();
  return {
    ok: result.status === 0,
    error: result.stderr,
    config: result.status === 0 ? JSON.parse(out) : null,
  };
};

test('a server started without NODE_ENV is treated as production', () => {
  const { ok, config } = run({ JWT_SECRET: STRONG_A, JWT_REFRESH_SECRET: STRONG_B });
  assert.ok(ok);
  assert.equal(config.nodeEnv, 'production');
  assert.equal(config.mock, false);
});

test('production refuses to start without real JWT secrets', () => {
  const cases = {
    missing: {},
    tooShort: { JWT_SECRET: 'short', JWT_REFRESH_SECRET: STRONG_B },
    placeholder: {
      JWT_SECRET: 'your-random-32-character-secret-key',
      JWT_REFRESH_SECRET: STRONG_B,
    },
    identical: { JWT_SECRET: STRONG_A, JWT_REFRESH_SECRET: STRONG_A },
  };
  for (const [name, env] of Object.entries(cases)) {
    const { ok, error } = run({ NODE_ENV: 'production', ...env });
    assert.equal(ok, false, `${name} should fail`);
    assert.match(error, /JWT_(REFRESH_)?SECRET/, name);
  }
});

test('development starts without secrets, using dev-only ones', () => {
  const { ok, config } = run({ NODE_ENV: 'development' });
  assert.ok(ok);
  assert.equal(config.mock, false, 'mock sign-in is opt-in in development');
});

test('mock sign-in: always in tests, opt-in in development, never in production', () => {
  assert.equal(run({ NODE_ENV: 'test' }).config.mock, true);
  assert.equal(
    run({ NODE_ENV: 'development', ALLOW_MOCK_GOOGLE_AUTH: 'true' }).config.mock,
    true,
  );
  assert.equal(
    run({
      NODE_ENV: 'production',
      ALLOW_MOCK_GOOGLE_AUTH: 'true',
      JWT_SECRET: STRONG_A,
      JWT_REFRESH_SECRET: STRONG_B,
    }).config.mock,
    false,
  );
});

test('production rejects a mock Google token instead of signing it in', () => {
  const snippet = `
    const { verifyGoogleToken } = require(${JSON.stringify(path.join(SRC, 'services', 'google-auth.service.js'))});
    verifyGoogleToken('mock-google-token:victim@gmail.com:Victim:123')
      .then(() => { console.error('SIGNED IN'); process.exit(3); })
      .catch((e) => { console.error('REJECTED ' + e.status); process.exit(4); });
  `;
  const result = spawnSync(
    process.execPath,
    ['-e', `const config = require(${JSON.stringify(path.join(SRC, 'config', 'env.js'))}); ${snippet}`],
    {
      cwd: os.tmpdir(),
      env: {
        PATH: process.env.PATH,
        SystemRoot: process.env.SystemRoot,
        NODE_ENV: 'production',
        JWT_SECRET: STRONG_A,
        JWT_REFRESH_SECRET: STRONG_B,
      },
      encoding: 'utf8',
    },
  );
  assert.equal(result.status, 4, result.stderr);
  assert.match(result.stderr, /REJECTED/);
});
