const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

const version = process.env.APP_VERSION || '1.0.0';
const stage = process.env.APP_STAGE || 'DEV';

app.get('/', (_req, res) => {
  res.json({
    service: 'apptrust-hello-service',
    version,
    stage,
    message: 'Hello from JFrog AppTrust sample!'
  });
});

app.get('/healthz', (_req, res) => {
  res.status(200).json({ status: 'ok' });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`apptrust-hello-service v${version} listening on :${port} (stage=${stage})`);
  });
}

module.exports = app;
