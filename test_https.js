// filepath: /Users/nathanbrown-bennett/mymask/test_https.js
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('server.key'),
  cert: fs.readFileSync('server.crt'),
  minVersion: 'TLSv1.2',
  ALPNProtocols: ['http/1.1']   // Enforce advertisement of HTTP/1.1
};

https.createServer(options, (req, res) => {
  res.writeHead(200);
  res.end("Hello from test HTTPS server!");
}).listen(5173, () => {
  console.log("Test HTTPS server running at https://10.186.95.105:5173/");
});