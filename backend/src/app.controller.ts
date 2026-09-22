import { Controller, Get, Req, Res } from '@nestjs/common';
import { Request, Response } from 'express';

@Controller()
export class AppController {
  @Get()
  getRoot(@Req() req: Request, @Res() res: Response) {
    const acceptsHtml = req.headers.accept && req.headers.accept.includes('text/html');

    if (acceptsHtml) {
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SmritiSetu Cloud Backend</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #0f172a;
      color: #f8fafc;
      margin: 0;
      padding: 40px 20px;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      box-sizing: border-box;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      max-width: 620px;
      width: 100%;
      padding: 32px;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.5);
    }
    .badge {
      display: inline-block;
      background: #10b981;
      color: #064e3b;
      font-weight: 700;
      font-size: 12px;
      padding: 4px 10px;
      border-radius: 9999px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    h1 {
      margin-top: 16px;
      font-size: 24px;
      color: #38bdf8;
    }
    p {
      color: #94a3b8;
      line-height: 1.6;
    }
    .btn {
      display: inline-block;
      background: #0284c7;
      color: #ffffff;
      padding: 12px 24px;
      border-radius: 8px;
      text-decoration: none;
      font-weight: 600;
      margin-top: 16px;
      transition: background 0.2s ease;
    }
    .btn:hover {
      background: #0369a1;
    }
    .endpoints {
      background: #0f172a;
      border: 1px solid #334155;
      border-radius: 8px;
      padding: 16px;
      margin-top: 24px;
      font-family: monospace;
      font-size: 13px;
    }
    .endpoints div {
      margin-bottom: 6px;
      color: #cbd5e1;
    }
    .method {
      color: #38bdf8;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">Online &amp; Healthy</span>
    <h1>SmritiSetu Secure Cloud Backend</h1>
    <p>
      The REST API service is active and listening on port <strong>3000</strong>.
      If you are looking for the graphical user interface, open the Flutter Web application at:
    </p>
    <p>
      <a class="btn" href="http://localhost:8080" target="_blank">Open Frontend App (http://localhost:8080)</a>
    </p>
    <div class="endpoints">
      <div><strong>Key API Endpoints:</strong></div>
      <div><span class="method">POST</span> /api/v1/auth/login</div>
      <div><span class="method">POST</span> /api/v1/auth/register</div>
      <div><span class="method">POST</span> /api/v1/sync</div>
      <div><span class="method">GET</span> /api/v1/patients/:id</div>
      <div><span class="method">GET</span> /api/v1/caregivers/:id/patients</div>
      <div><span class="method">GET</span> /api/v1/ml/model-card</div>
      <div><span class="method">GET</span> /health</div>
    </div>
  </div>
</body>
</html>
      `);
    }

    return res.json({
      name: 'SmritiSetu Cognitive Support & Monitoring Backend',
      version: '1.0.0',
      status: 'online',
      environment: process.env.NODE_ENV || 'development',
      frontendUrl: 'http://localhost:8080',
      endpoints: {
        auth: '/api/v1/auth/login',
        register: '/api/v1/auth/register',
        sync: '/api/v1/sync',
        patients: '/api/v1/patients',
        caregivers: '/api/v1/caregivers',
        ml: '/api/v1/ml/model-card',
        health: '/health',
      },
      timestamp: new Date().toISOString(),
    });
  }

  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      uptimeSeconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    };
  }
}
