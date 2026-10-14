const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { spawn } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const viewerScript = process.argv[2];
const edge = process.argv[3];
const requestedLimit = Number(process.argv[4] || 36);
const modelsDirectory = path.join(root, 'assets', '3d');
const outputDirectory = path.join(root, 'assets', 'mascot_previews');

if (!viewerScript || !edge) {
  throw new Error('Usage: node render_mascot_previews.cjs <viewer-js> <edge> [limit]');
}

const source = fs.readFileSync(
  path.join(root, 'lib', 'models', 'character_data.dart'),
  'utf8',
);
const items = [...source.matchAll(
  /id:\s*'([^']+)'[\s\S]*?modelPath:\s*'assets\/3d\/([^']+)'/g,
)].map((match) => ({ id: match[1], model: match[2] }));

if (items.length !== 36) {
  throw new Error(`Expected 36 mascot models, found ${items.length}.`);
}

fs.mkdirSync(outputDirectory, { recursive: true });
const renderItems = items.slice(0, requestedLimit);
let completedResolve;
let failedReject;
const completed = new Promise((resolve, reject) => {
  completedResolve = resolve;
  failedReject = reject;
});

const html = `<!doctype html>
<html><head><meta charset="utf-8"><style>
html,body{width:512px;height:512px;margin:0;background:transparent;overflow:hidden}
model-viewer{width:512px;height:512px;background:transparent}
</style></head><body>
<model-viewer id="model" camera-controls="false" auto-rotate="false"
  camera-orbit="0deg 75deg 110%" field-of-view="30deg"
  shadow-intensity="0.8" exposure="1.1" environment-image="neutral">
</model-viewer>
<script type="module">
const models = ${JSON.stringify(renderItems)};
const viewer = document.querySelector('#model');
const waitForLoad = (source) => new Promise((resolve, reject) => {
  const timeout = setTimeout(() => reject(new Error('Model load timed out: ' + source)), 20000);
  viewer.addEventListener('load', () => { clearTimeout(timeout); resolve(); }, { once: true });
  viewer.addEventListener('error', () => { clearTimeout(timeout); reject(new Error('Model load failed: ' + source)); }, { once: true });
  viewer.src = source;
});
try {
  await customElements.whenDefined('model-viewer');
  for (const item of models) {
    const source = '/models/' + encodeURIComponent(item.model);
    await waitForLoad(source);
    await new Promise((resolve) => setTimeout(resolve, 300));
    const image = await viewer.toBlob({ mimeType: 'image/png', idealAspect: 1 });
    const response = await fetch('/preview/' + encodeURIComponent(item.id), {
      method: 'POST',
      headers: { 'content-type': 'image/png' },
      body: image
    });
    if (!response.ok) throw new Error('Could not save preview for ' + item.id);
    document.title = 'Rendered ' + item.id;
  }
  await fetch('/complete', { method: 'POST' });
} catch (error) {
  await fetch('/failure', { method: 'POST', body: String(error) });
}
</script>
<script type="module" src="/model-viewer.min.js"></script>
</body></html>`;

let server;
let browser;

server = http.createServer((request, response) => {
  const url = new URL(request.url, 'http://127.0.0.1');
  if (request.method === 'GET' && url.pathname === '/') {
    response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    response.end(html);
    return;
  }
  if (request.method === 'GET' && url.pathname === '/model-viewer.min.js') {
    response.writeHead(200, { 'content-type': 'text/javascript' });
    fs.createReadStream(viewerScript).pipe(response);
    return;
  }
  if (request.method === 'GET' && url.pathname.startsWith('/models/')) {
    const filename = path.basename(decodeURIComponent(url.pathname.slice(8)));
    const modelPath = path.join(modelsDirectory, filename);
    if (!fs.existsSync(modelPath)) {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, { 'content-type': 'model/gltf-binary' });
    fs.createReadStream(modelPath).pipe(response);
    return;
  }
  if (request.method === 'POST' && url.pathname.startsWith('/preview/')) {
    const id = path.basename(decodeURIComponent(url.pathname.slice(9)));
    if (!renderItems.some((item) => item.id === id)) {
      response.writeHead(404).end();
      return;
    }
    const output = fs.createWriteStream(path.join(outputDirectory, `${id}.png`));
    request.pipe(output);
    output.on('finish', () => {
      console.log(`Rendered ${id}`);
      response.writeHead(200).end('ok');
    });
    output.on('error', failedReject);
    return;
  }
  if (request.method === 'POST' && url.pathname === '/complete') {
    response.writeHead(200).end('ok');
    completedResolve();
    return;
  }
  if (request.method === 'POST' && url.pathname === '/failure') {
    let message = '';
    request.setEncoding('utf8').on('data', (chunk) => (message += chunk));
    request.on('end', () => {
      response.writeHead(200).end('ok');
      failedReject(new Error(message));
    });
    return;
  }
  response.writeHead(404).end();
});

server.listen(0, '127.0.0.1', () => {
  const address = server.address();
  browser = spawn(
    edge,
    [
      '--headless=new',
      '--no-sandbox',
      '--enable-webgl',
      '--use-gl=angle',
      '--use-angle=swiftshader',
      '--disable-dev-shm-usage',
      '--hide-scrollbars',
      '--window-size=512,512',
      `http://127.0.0.1:${address.port}/`,
    ],
    { stdio: 'ignore' },
  );
  browser.on('error', failedReject);
  browser.on('close', (code) => {
    if (code !== 0) failedReject(new Error(`Edge exited with code ${code}.`));
  });
});

const timeout = setTimeout(
  () => failedReject(new Error('Preview rendering timed out.')),
  300000,
);

completed.then(
  () => {
    clearTimeout(timeout);
    browser.kill();
    server.close(() => {
      console.log(`Rendered ${renderItems.length} mascot previews.`);
    });
  },
  (error) => {
    clearTimeout(timeout);
    if (browser && browser.exitCode === null) browser.kill();
    server.close();
    console.error(error);
    process.exitCode = 1;
  },
);
