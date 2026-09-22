const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');

async function main() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--window-size=1280,800',
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
        chrome.kill();
        return;
      }

      const ws = new WebSocket(pageTarget.webSocketDebuggerUrl);
      ws.onopen = () => {
        ws.send(JSON.stringify({ id: 1, method: 'Page.enable' }));
        setTimeout(() => {
          ws.send(JSON.stringify({ id: 2, method: 'Page.captureScreenshot', params: { format: 'png' } }));
        }, 3000);
      };

      ws.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.id === 2 && msg.result && msg.result.data) {
          fs.writeFileSync('mobile/build/web/app_screenshot.png', Buffer.from(msg.result.data, 'base64'));
          console.log('Screenshot captured successfully! Size:', msg.result.data.length);
          ws.close();
          chrome.kill();
          process.exit(0);
        }
      };

      setTimeout(() => {
        chrome.kill();
        process.exit(0);
      }, 8000);
    });
  });
}

main();
