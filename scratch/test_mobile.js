const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

function getTargets() {
  return new Promise((resolve, reject) => {
    http.get('http://127.0.0.1:9222/json', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

function sendCommand(ws, id, method, params = {}) {
  return new Promise((resolve) => {
    const handler = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id === id) {
        ws.removeEventListener('message', handler);
        resolve(msg.result);
      }
    };
    ws.addEventListener('message', handler);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function testMobile() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--disable-gpu',
    '--window-size=390,844',
    'http://localhost:8080/#/demo'
  ]);

  await new Promise(r => setTimeout(r, 2500));

  try {
    const targets = await getTargets();
    const pageTarget = targets.find(t => t.url.includes('8080'));
    if (!pageTarget) {
      chrome.kill();
      return;
    }

    const ws = new WebSocket(pageTarget.webSocketDebuggerUrl);
    await new Promise(r => { ws.onopen = r; });

    let cmdId = 1;
    await sendCommand(ws, cmdId++, 'Page.enable');
    await new Promise(r => setTimeout(r, 3000));

    const mobileScreenshot = await sendCommand(ws, cmdId++, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'screenshot_mobile_demo.png'), Buffer.from(mobileScreenshot.data, 'base64'));
    console.log('Saved screenshot_mobile_demo.png');
    ws.close();
  } catch (err) {
    console.error('Mobile test error:', err);
  } finally {
    chrome.kill();
  }
}

testMobile();
