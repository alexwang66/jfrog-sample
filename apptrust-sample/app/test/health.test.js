const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const app = require('../server');

function request(server, path) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      { host: '127.0.0.1', port: server.address().port, path, method: 'GET' },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => resolve({ status: res.statusCode, body }));
      }
    );
    req.on('error', reject);
    req.end();
  });
}

test('GET /healthz returns 200 ok', async () => {
  const server = app.listen(0);
  try {
    const res = await request(server, '/healthz');
    assert.strictEqual(res.status, 200);
    assert.match(res.body, /"status":"ok"/);
  } finally {
    server.close();
  }
});

test('GET / returns service payload', async () => {
  const server = app.listen(0);
  try {
    const res = await request(server, '/');
    assert.strictEqual(res.status, 200);
    const payload = JSON.parse(res.body);
    assert.strictEqual(payload.service, 'apptrust-hello-service');
    assert.ok(payload.version);
  } finally {
    server.close();
  }
});
