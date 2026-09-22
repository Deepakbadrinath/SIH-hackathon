import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import helmet from 'helmet';
import * as fs from 'fs';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  // Production HTTPS Configuration
  let httpsOptions: { key: Buffer; cert: Buffer } | undefined = undefined;
  const isProduction = process.env.NODE_ENV === 'production';
  const sslKeyPath = process.env.SSL_KEY_PATH;
  const sslCertPath = process.env.SSL_CERT_PATH;

  if (isProduction && sslKeyPath && sslCertPath) {
    try {
      httpsOptions = {
        key: fs.readFileSync(sslKeyPath),
        cert: fs.readFileSync(sslCertPath),
      };
      logger.log('Production TLS/HTTPS certificates loaded successfully.');
    } catch (err: any) {
      logger.warn(`Could not load HTTPS certificates: ${err.message}. Ensure reverse proxy (NGINX/Caddy) terminates TLS.`);
    }
  }

  const app = await NestFactory.create(AppModule, {
    httpsOptions,
  });

  // 1. Security Headers (Helmet)
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          imgSrc: ["'self'", 'data:', 'blob:'],
          connectSrc: ["'self'"],
          fontSrc: ["'self'"],
          objectSrc: ["'none'"],
          frameAncestors: ["'none'"],
          upgradeInsecureRequests: isProduction ? [] : null,
        },
      },
      hsts: {
        maxAge: 31536000, // 1 year
        includeSubDomains: true,
        preload: true,
      },
      referrerPolicy: { policy: 'same-origin' },
      crossOriginEmbedderPolicy: false,
    }),
  );

  // 2. Strict Input Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,            // Strip unexpected fields
      forbidNonWhitelisted: true, // Reject unexpected fields with 400 Bad Request
      transform: true,            // Auto-transform payloads to DTO instances
      transformOptions: {
        enableImplicitConversion: false,
      },
    }),
  );

  // 3. Sanitized Error Filter
  app.useGlobalFilters(new HttpExceptionFilter());

  const defaultOrigins = [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:8080',
    'http://127.0.0.1:8080',
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'http://localhost:8081',
    'http://127.0.0.1:8081',
    'http://localhost:5000',
    'http://127.0.0.1:5000',
    'http://localhost:5173',
    'http://127.0.0.1:5173',
  ];
  const configuredOrigins = process.env.CORS_ORIGINS
    ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
    : defaultOrigins;

  app.enableCors({
    origin: (origin, callback) => {
      // Allow requests with no origin (such as native mobile apps, Postman, server-to-server)
      if (!origin) return callback(null, true);
      if (configuredOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Cross-Origin Request Blocked by SmritiSetu CORS Policy'), false);
    },
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
    credentials: true,
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);

  logger.log(`================================================================`);
  logger.log(` SmritiSetu Secure Cloud Backend is running on port: ${port}`);
  logger.log(` Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.log(` Protocol: ${httpsOptions ? 'HTTPS (TLS enabled)' : 'HTTP (Local/Proxy terminating)'}`);
  logger.log(` Zero-Trust RBAC & Ownership enforcement ACTIVE`);
  logger.log(`================================================================`);
}

bootstrap();
