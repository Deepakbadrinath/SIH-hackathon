import { describe, it, before, after } from 'node:test';
import * as assert from 'node:assert';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../app.module';
import { HttpExceptionFilter } from '../common/filters/http-exception.filter';

describe('Phase 14: Secure Backend Automated API Test Suite', () => {
  let app: INestApplication;
  let baseUrl: string;
  let jwtService: JwtService;

  before(async () => {
    // Spin up real NestJS server instance in test environment
    app = await NestFactory.create(AppModule, { logger: false });

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalFilters(new HttpExceptionFilter());

    // Listen on dynamic random available port
    await app.listen(0);
    const address = app.getHttpServer().address();
    const port = typeof address === 'string' ? address : address.port;
    baseUrl = `http://127.0.0.1:${port}`;
    jwtService = app.get(JwtService);
  });

  after(async () => {
    if (app) {
      await app.close();
    }
  });

  // =========================================================================
  // 1. VALID LOGIN
  // =========================================================================
  describe('1. Valid Login', () => {
    it('successfully logs in authorized caregiver and returns access + refresh tokens', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'caregiver1@smritisetu.org',
          password: 'Caregiver@12345!',
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();

      assert.ok(data.accessToken, 'Access token should be returned');
      assert.ok(data.refreshToken, 'Refresh token should be returned');
      assert.strictEqual(data.tokenType, 'Bearer');
      assert.strictEqual(data.user.email, 'caregiver1@smritisetu.org');
      assert.strictEqual(data.user.role, 'CAREGIVER');
      assert.strictEqual(data.user.id, 'caregiver_1');
      assert.strictEqual(data.user.passwordHash, undefined, 'Password hash must NEVER be leaked');
    });

    it('successfully logs in patient and returns user identity', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'patient1@smritisetu.org',
          password: 'Patient@12345!',
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.user.role, 'PATIENT');
      assert.strictEqual(data.user.id, 'patient_1');
    });
  });

  // =========================================================================
  // 2. INVALID LOGIN
  // =========================================================================
  describe('2. Invalid Login & Safe Error Messages', () => {
    it('rejects incorrect password with generic 401 error (no credential hint)', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'caregiver1@smritisetu.org',
          password: 'WrongPassword@123!',
        }),
      });

      assert.strictEqual(res.status, 401);
      const error = await res.json();
      assert.strictEqual(error.statusCode, 401);
      assert.strictEqual(error.message, 'Invalid email or password');
      assert.strictEqual(error.stack, undefined, 'Stack trace must NEVER be leaked');
    });

    it('rejects nonexistent user email with the identical generic 401 error (no user enumeration)', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'nonexistent_person_99@smritisetu.org',
          password: 'AnyPassword@123!',
        }),
      });

      assert.strictEqual(res.status, 401);
      const error = await res.json();
      assert.strictEqual(error.message, 'Invalid email or password');
      assert.strictEqual(error.stack, undefined);
    });
  });

  // =========================================================================
  // 3. EXPIRED TOKEN
  // =========================================================================
  describe('3. Expired & Invalid Token Verification', () => {
    it('rejects expired JWT token with 401 Unauthorized', async () => {
      // Craft an already-expired JWT token using same secret
      const expiredToken = await jwtService.signAsync(
        { sub: 'patient_1', email: 'patient1@smritisetu.org', role: 'PATIENT' },
        { expiresIn: '-10s' }, // Expired 10 seconds ago
      );

      const res = await fetch(`${baseUrl}/api/v1/patients/patient_1/dashboard`, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${expiredToken}`,
        },
      });

      assert.strictEqual(res.status, 401);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 401);
      assert.strictEqual(data.message, 'Authentication token has expired');
    });

    it('rejects forged/tampered JWT signature with 401 Unauthorized', async () => {
      const res = await fetch(`${baseUrl}/api/v1/patients/patient_1/dashboard`, {
        method: 'GET',
        headers: {
          Authorization: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.tampered.signature',
        },
      });

      assert.strictEqual(res.status, 401);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 401);
    });
  });

  // =========================================================================
  // 4. UNAUTHORIZED PATIENT ACCESS (Cross-Patient Access Breach)
  // =========================================================================
  describe('4. Unauthorized Patient Access', () => {
    let patient1Token: string;

    before(async () => {
      patient1Token = await jwtService.signAsync({
        sub: 'patient_1',
        email: 'patient1@smritisetu.org',
        role: 'PATIENT',
      });
    });

    it('allows patient to access their own dashboard', async () => {
      const res = await fetch(`${baseUrl}/api/v1/patients/patient_1/dashboard`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${patient1Token}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.patientId, 'patient_1');
      assert.strictEqual(data.fullName, 'Deka Da');
    });

    it('strictly denies Patient 1 access to Patient 2 records with 403 Forbidden', async () => {
      const res = await fetch(`${baseUrl}/api/v1/patients/patient_2/dashboard`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${patient1Token}` },
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 403);
      assert.match(data.message, /Access denied: You do not have permission to access another patient's records/);
    });

    it('strictly denies Patient 1 access to Secret Patient records with 403 Forbidden', async () => {
      const res = await fetch(`${baseUrl}/api/v1/patients/patient_secret/dashboard`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${patient1Token}` },
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 403);
    });
  });

  // =========================================================================
  // 5. UNAUTHORIZED CAREGIVER ACCESS
  // =========================================================================
  describe('5. Unauthorized Caregiver Access', () => {
    let caregiver1Token: string;
    let caregiver2Token: string;

    before(async () => {
      // Caregiver 1 has active relationships with patient_1 and patient_2
      caregiver1Token = await jwtService.signAsync({
        sub: 'caregiver_1',
        email: 'caregiver1@smritisetu.org',
        role: 'CAREGIVER',
      });

      // Caregiver 2 has NO relationship with any patient
      caregiver2Token = await jwtService.signAsync({
        sub: 'caregiver_2',
        email: 'caregiver2@smritisetu.org',
        role: 'CAREGIVER',
      });
    });

    it('allows Caregiver 1 to access authorized Patient 1 dashboard', async () => {
      const res = await fetch(`${baseUrl}/api/v1/patients/patient_1/dashboard`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${caregiver1Token}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.patientId, 'patient_1');
    });

    it('denies Caregiver 2 (unlinked) access to Patient 1 with 403 Forbidden', async () => {
      const res = await fetch(`${baseUrl}/api/v1/patients/patient_1/dashboard`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${caregiver2Token}` },
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 403);
      assert.match(data.message, /Access denied: You are not authorized to access this patient's records/);
    });

    it('denies Caregiver 1 access to unassigned Secret Patient with 403 Forbidden', async () => {
      const res = await fetch(`${baseUrl}/api/v1/patients/patient_secret/dashboard`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${caregiver1Token}` },
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 403);
    });

    it('denies Caregiver 2 from querying Caregiver 1 patient roster with 403 Forbidden', async () => {
      const res = await fetch(`${baseUrl}/api/v1/caregivers/caregiver_1/patients`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${caregiver2Token}` },
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 403);
      assert.match(data.message, /You cannot view another caregiver's connected patients/);
    });
  });

  // =========================================================================
  // 6. INVALID PAYLOAD REJECTION (Data Validation & Whitelist)
  // =========================================================================
  describe('6. Invalid Payload Rejection', () => {
    it('rejects registration with weak password lacking complexity', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'test_weak@smritisetu.org',
          password: 'simple', // < 8 characters and no uppercase/symbols
          fullName: 'Test User',
          role: 'CAREGIVER',
        }),
      });

      assert.strictEqual(res.status, 400);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 400);
      assert.ok(
        Array.isArray(data.message)
          ? data.message.some((m: string) => m.includes('Password must'))
          : data.message.includes('Password must'),
      );
    });

    it('rejects unexpected injected properties (forbidNonWhitelisted test)', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'test_injection@smritisetu.org',
          password: 'ValidPassword@123!',
          fullName: 'Valid Name',
          role: 'CAREGIVER',
          isAdmin: true, // INJECTED EXTRANEOUS PROPERTY
        }),
      });

      assert.strictEqual(res.status, 400);
      const data = await res.json();
      assert.strictEqual(data.statusCode, 400);
      assert.ok(
        Array.isArray(data.message)
          ? data.message.some((m: string) => m.includes('property isAdmin should not exist'))
          : data.message.includes('isAdmin'),
      );
    });

    it('rejects self-registration with ADMIN role', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'rogue_admin@smritisetu.org',
          password: 'RogueAdmin@123!',
          fullName: 'Rogue Admin',
          role: 'ADMIN', // Prohibited role for public registration
        }),
      });

      assert.strictEqual(res.status, 400);
    });
  });

  // =========================================================================
  // 7. RATE LIMITING
  // =========================================================================
  describe('7. Rate Limiting Protection', () => {
    it('triggers HTTP 429 Too Many Requests when endpoint limit is exceeded', async () => {
      // The /api/v1/auth/login endpoint has limit: 5 requests per 60s
      let lastStatus = 200;
      for (let i = 0; i < 8; i++) {
        const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email: 'caregiver1@smritisetu.org',
            password: 'Caregiver@12345!',
          }),
        });
        lastStatus = res.status;
        if (lastStatus === 429) {
          break;
        }
      }

      assert.strictEqual(lastStatus, 429, 'Excessive rapid requests must trigger HTTP 429');
    });
  });

  // =========================================================================
  // 8. DUPLICATE REQUESTS & IDEMPOTENCY
  // =========================================================================
  describe('8. Duplicate Requests & Idempotency Handling', () => {
    let patientToken: string;

    before(async () => {
      // Create fresh token for patient 1 to use in sync endpoint
      patientToken = await jwtService.signAsync({
        sub: 'patient_1',
        email: 'patient1@smritisetu.org',
        role: 'PATIENT',
      });
    });

    it('handles duplicate operation idempotently with CONFLICT_IGNORED on replay', async () => {
      const payload = {
        batchId: 'batch_test_idempotency_1',
        clientTimestamp: new Date().toISOString(),
        operations: [
          {
            operationId: 'op_idempotent_unique_9999',
            entityId: 'session_888',
            entityType: 'GAME_SESSION',
            operationType: 'INSERT',
            payload: { game: 'PatternRecall', score: 100 },
            timestamp: new Date().toISOString(),
          },
        ],
      };

      // First submission
      const res1 = await fetch(`${baseUrl}/api/v1/sync/batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${patientToken}`,
        },
        body: JSON.stringify(payload),
      });

      assert.strictEqual(res1.status, 200);
      const data1 = await res1.json();
      assert.strictEqual(data1.results[0].status, 'SUCCESS');

      // Duplicate submission with the same operationId
      const res2 = await fetch(`${baseUrl}/api/v1/sync/batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${patientToken}`,
        },
        body: JSON.stringify(payload),
      });

      assert.strictEqual(res2.status, 200);
      const data2 = await res2.json();
      assert.strictEqual(
        data2.results[0].status,
        'CONFLICT_IGNORED',
        'Duplicate operationId must return CONFLICT_IGNORED without secondary mutation',
      );
      assert.match(data2.results[0].message, /Operation was already processed previously/);
    });
  });

  // =========================================================================
  // 9. ADMIN ROLE-BASED ACCESS CONTROL
  // =========================================================================
  describe('9. Admin RBAC Restrictions', () => {
    it('allows Admin to access /api/v1/admin/users', async () => {
      const adminToken = await jwtService.signAsync({
        sub: 'user_admin',
        email: 'admin@smritisetu.org',
        role: 'ADMIN',
      });

      const res = await fetch(`${baseUrl}/api/v1/admin/users`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const users = await res.json();
      assert.ok(Array.isArray(users));
      assert.ok(users.length > 0);
    });

    it('denies Caregiver from accessing /api/v1/admin/users with 403 Forbidden', async () => {
      const caregiverToken = await jwtService.signAsync({
        sub: 'caregiver_1',
        email: 'caregiver1@smritisetu.org',
        role: 'CAREGIVER',
      });

      const res = await fetch(`${baseUrl}/api/v1/admin/users`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${caregiverToken}` },
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.match(data.message, /Required role \(ADMIN\) not granted for role 'CAREGIVER'/);
    });
  });

  // =========================================================================
  // 10. BATCH SYNC ACCESS CONTROL & IDOR PREVENTION
  // =========================================================================
  describe('10. Batch Sync Broken Access Control & IDOR Prevention', () => {
    it('rejects patient attempting to synchronize records for another patient with ERROR status', async () => {
      const patient1Token = await jwtService.signAsync({
        sub: 'patient_1',
        email: 'patient1@smritisetu.org',
        role: 'PATIENT',
      });

      const payload = {
        batchId: `batch-pat-idor-${Date.now()}`,
        clientTimestamp: new Date().toISOString(),
        operations: [
          {
            operationId: `idor-test-pat-${Date.now()}`,
            entityId: 'session_rogue_999',
            entityType: 'GAME_SESSION',
            operationType: 'INSERT',
            timestamp: new Date().toISOString(),
            payload: {
              patientId: 'patient_2', // Attempting to sync into another patient's records
              gameType: 'PATTERN_RECALL',
              score: 999,
            },
          },
        ],
      };

      const res = await fetch(`${baseUrl}/api/v1/sync/batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${patient1Token}`,
        },
        body: JSON.stringify(payload),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.results[0].status, 'ERROR');
      assert.match(data.results[0].message, /Unauthorized: Patient cannot synchronize data for another patient/);
    });

    it('rejects caregiver attempting to sync records for an unlinked patient', async () => {
      const caregiver2Token = await jwtService.signAsync({
        sub: 'caregiver_2',
        email: 'caregiver2@smritisetu.org',
        role: 'CAREGIVER',
      });

      const payload = {
        batchId: `batch-cg2-idor-${Date.now()}`,
        clientTimestamp: new Date().toISOString(),
        operations: [
          {
            operationId: `idor-test-cg2-${Date.now()}`,
            entityId: 'med_rogue_999',
            entityType: 'MEDICATION_LOG',
            operationType: 'INSERT',
            timestamp: new Date().toISOString(),
            payload: {
              patientId: 'patient_1', // Caregiver 2 is not linked to patient 1
              medicationName: 'Donepezil',
              status: 'TAKEN',
            },
          },
        ],
      };

      const res = await fetch(`${baseUrl}/api/v1/sync/batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${caregiver2Token}`,
        },
        body: JSON.stringify(payload),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.results[0].status, 'ERROR');
      assert.match(data.results[0].message, /Unauthorized: Caregiver does not have an active relationship/);
    });

    it('permits authorized caregiver to sync records for assigned patient', async () => {
      const caregiver1Token = await jwtService.signAsync({
        sub: 'caregiver_1',
        email: 'caregiver1@smritisetu.org',
        role: 'CAREGIVER',
      });

      const payload = {
        batchId: `batch-cg1-valid-${Date.now()}`,
        clientTimestamp: new Date().toISOString(),
        operations: [
          {
            operationId: `auth-cg1-${Date.now()}`,
            entityId: 'med_valid_111',
            entityType: 'MEDICATION_LOG',
            operationType: 'INSERT',
            timestamp: new Date().toISOString(),
            payload: {
              patientId: 'patient_1', // Caregiver 1 has active relationship with patient 1
              medicationName: 'Memantine',
              status: 'TAKEN',
            },
          },
        ],
      };

      const res = await fetch(`${baseUrl}/api/v1/sync/batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${caregiver1Token}`,
        },
        body: JSON.stringify(payload),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.results[0].status, 'SUCCESS');
    });
  });
});
