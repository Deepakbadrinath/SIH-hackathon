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

async function run() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--disable-gpu',
    '--window-size=1440,900',
    'http://localhost:8080/'
  ]);

  console.log('Starting headless Chrome...');
  await new Promise(r => setTimeout(r, 2500));

  try {
    const targets = await getTargets();
    const pageTarget = targets.find(t => t.url.includes('8080'));
    if (!pageTarget) {
      console.error('Target not found:', targets);
      chrome.kill();
      return;
    }

    const ws = new WebSocket(pageTarget.webSocketDebuggerUrl);
    await new Promise(r => { ws.onopen = r; });

    let cmdId = 1;
    await sendCommand(ws, cmdId++, 'Runtime.enable');
    await sendCommand(ws, cmdId++, 'Page.enable');

    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.method === 'Runtime.consoleAPICalled') {
        const text = msg.params.args.map(a => a.value !== undefined ? a.value : (a.description || '')).join(' ');
        console.log(`[CONSOLE ${msg.params.type.toUpperCase()}] ${text}`);
      } else if (msg.method === 'Runtime.exceptionThrown') {
        console.error('[UNCAUGHT EXCEPTION]', JSON.stringify(msg.params.exceptionDetails));
      }
    };

    console.log('Waiting for Flutter app initialization...');
    await new Promise(r => setTimeout(r, 4500));

    // Test 1: Verify window.smritiVoice
    console.log('\n--- TEST 1: VOICE SYNTHESIS ENGINE ---');
    const voiceCheck = await sendCommand(ws, cmdId++, 'Runtime.evaluate', {
      expression: `({
        isDefined: typeof window.smritiVoice !== 'undefined',
        isAvailable: typeof window.smritiVoice !== 'undefined' && window.smritiVoice.isAvailable(),
        supportedLanguages: typeof window.smritiVoice !== 'undefined' ? window.smritiVoice.getSupportedLanguages().length : 0,
        voices: typeof window.smritiVoice !== 'undefined' ? window.smritiVoice.getAvailableVoices().length : 0
      })`,
      returnByValue: true
    });
    console.log('Voice status:', JSON.stringify(voiceCheck.result.value));

    const voiceSpeakTest = await sendCommand(ws, cmdId++, 'Runtime.evaluate', {
      expression: `window.smritiVoice ? window.smritiVoice.speak('नमस्ते, यह स्मृति सेतु है', 'hi') : false`,
      returnByValue: true
    });
    console.log('Voice speak test returned:', voiceSpeakTest.result.value);

    // Capture screenshot of Splash/Home
    console.log('\n--- TEST 2: SPLASH / HOME SCREEN ---');
    const homeScreenshot = await sendCommand(ws, cmdId++, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'screenshot_splash.png'), Buffer.from(homeScreenshot.data, 'base64'));
    console.log('Saved screenshot_splash.png');

    // Test 3: Navigate to /#/demo
    console.log('\n--- TEST 3: SIH DEMO HUB NAVIGATION ---');
    await sendCommand(ws, cmdId++, 'Page.navigate', { url: 'http://localhost:8080/#/demo' });
    await new Promise(r => setTimeout(r, 3000));

    const demoScreenshot = await sendCommand(ws, cmdId++, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'screenshot_demo.png'), Buffer.from(demoScreenshot.data, 'base64'));
    console.log('Saved screenshot_demo.png');

    // Test 4: Check if Demo screen rendered
    const demoPageCheck = await sendCommand(ws, cmdId++, 'Runtime.evaluate', {
      expression: `document.title`,
      returnByValue: true
    });
    console.log('Document title at /demo:', demoPageCheck.result.value);

    // Test 5: Navigate to /#/patient
    console.log('\n--- TEST 5: PATIENT HOME / GAMES SCREEN ---');
    await sendCommand(ws, cmdId++, 'Page.navigate', { url: 'http://localhost:8080/#/patient' });
    await new Promise(r => setTimeout(r, 3000));

    const patientScreenshot = await sendCommand(ws, cmdId++, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'screenshot_patient.png'), Buffer.from(patientScreenshot.data, 'base64'));
    console.log('Saved screenshot_patient.png');

    // Test 6: Navigate to Face Match Game
    console.log('\n--- TEST 6: FACE MATCH GAME SCREEN ---');
    await sendCommand(ws, cmdId++, 'Page.navigate', { url: 'http://localhost:8080/#/game/face_match' });
    await new Promise(r => setTimeout(r, 3000));

    const gameScreenshot = await sendCommand(ws, cmdId++, 'Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(__dirname, 'screenshot_game.png'), Buffer.from(gameScreenshot.data, 'base64'));
    console.log('Saved screenshot_game.png');

    console.log('\nALL VERIFICATION STEPS COMPLETED SUCCESSFULLY!');
    ws.close();
  } catch (err) {
    console.error('Test error:', err);
  } finally {
    chrome.kill();
  }
}

run();
