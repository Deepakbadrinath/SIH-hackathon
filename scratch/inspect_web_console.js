const { spawn } = require('child_process');
const http = require('http');

async function main() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--disable-gpu',
    'http://localhost:8080/'
  ]);

  await new Promise(r => setTimeout(r, 2000));

  http.get('http://127.0.0.1:9222/json', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      const targets = JSON.parse(data);
      const pageTarget = targets.find(t => t.url.includes('8080'));
      if (!pageTarget) {
        console.log('No page target found');
        chrome.kill();
        return;
      }
      console.log('Connecting to:', pageTarget.webSocketDebuggerUrl);

      const ws = new WebSocket(pageTarget.webSocketDebuggerUrl);
      ws.onopen = () => {
        ws.send(JSON.stringify({ id: 1, method: 'Runtime.enable' }));
        ws.send(JSON.stringify({ id: 2, method: 'Log.enable' }));
      };
      ws.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.method === 'Runtime.consoleAPICalled') {
          console.log('[BROWSER CONSOLE]', msg.params.type, msg.params.args.map(a => a.value || a.description).join(' '));
        } else if (msg.method === 'Runtime.exceptionThrown') {
          console.error('[BROWSER EXCEPTION]', msg.params.exceptionDetails.text, msg.params.exceptionDetails.exception);
        } else if (msg.method === 'Log.entryAdded') {
          console.log('[BROWSER LOG]', msg.params.entry.level, msg.params.entry.text);
        }
      };

      setTimeout(() => {
        ws.close();
        chrome.kill();
        process.exit(0);
      }, 7000);
    });
  });
}

main();
