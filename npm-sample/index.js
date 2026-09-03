const http = require('http');
const axios = require('axios');

const port = process.env.PORT || 3000;
const version = process.env.APP_VERSION || '1.0.0';
const stage = process.env.APP_STAGE || 'DEV';

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }

  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify({
    service: 'jfrog-npm-demo',
    version,
    stage,
    axiosVersion: axios.VERSION || require('axios/package.json').version,
    message: 'Hello from JFrog NPM demo'
  }));
});

server.listen(port, () => {
  console.log(`jfrog-npm-demo v${version} listening on :${port} (stage=${stage})`);
});
