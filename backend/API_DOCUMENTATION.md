# SmritiSetu Secure Backend API Documentation

## 1. System Overview
SmritiSetu Secure Backend is an enterprise-grade RESTful API service developed with NestJS to support cognitive assistance, patient activity tracking, caregiver dashboards, and medication adherence.

The backend enforces **Zero-Trust Security**:
- Authentication, authorization, and ownership/relationship checks are executed exclusively on the server.
- Client-side navigation guards, hidden buttons, or client claims are **never trusted**.
- Strict input validation filters out unexpected or malformed payload attributes.
- Exception filtering completely redacts database internals, stack traces, file paths, and environment secrets from API responses.

---

## 2. Role-Based Access Control (RBAC) Matrix

| Role | Scope & Permissions |
|---|---|
| **`ADMIN`** | System administrator. Full operational visibility, system user listing, cross-system audits. |
| **`CAREGIVER`** | Authorized family member or professional caregiver. Can view dashboard and medication records **only** for patients with an active registered relationship in `caregiver_patient_relationships`. Can query own connected patient roster. |
| **`PATIENT`** | Elderly or assistive user. Can access and synchronize **only their own** profile, game sessions, and medication schedule. Attempts to access any other patient's records return `403 Forbidden`. |

---

## 3. Security Architecture & Specifications

### 3.1 Authentication & Tokens
- **Password Hashing**: NIST-compliant salted `scrypt` (`N=16384`, `r=8`, `p=1`) with 16-byte cryptographically secure random salt and 64-byte key length. Verification utilizes `crypto.timingSafeEqual` to eliminate timing side-channel attacks.
- **Access Tokens**: Short-lived JSON Web Tokens (JWT) signed with HMAC-SHA256, containing `sub` (userId), `email`, and `role`. Expiry: **15 minutes**.
- **Refresh Tokens**: Cryptographically random 40-byte hex strings. The server hashes refresh tokens with SHA-256 before persisting in the revocation store. Expiry: **7 days**.
- **Single-Use Refresh Rotation**: Using a refresh token immediately revokes it and issues a fresh pair. Compromised tokens cannot be replayed.
- **Password Reset**: Generates 32-byte high-entropy crypto tokens with 15-minute expiry. Confirming a reset invalidates all existing user refresh tokens. Responses to reset requests are generic to prevent user enumeration.

### 3.2 Rate Limiting
Configured using `@nestjs/throttler`:
- **Global Limiter**: 100 requests per 60 seconds.
- **Brute-Force Protection**: 5 attempts per 60 seconds on `/api/v1/auth/login` and `/api/v1/auth/password-reset/*`. Exceeding limits returns `429 Too Many Requests`.

### 3.3 Data Validation & Sanitization
- Configured via NestJS `ValidationPipe`:
  - `whitelist: true`: Strips unknown properties automatically.
  - `forbidNonWhitelisted: true`: Rejects payloads with extraneous attributes with `400 Bad Request`.
  - Strong password complexity enforced via regex (uppercase, lowercase, number, special character, minimum 8 characters).

### 3.4 Error Handling & Information Leakage Prevention
All uncaught exceptions are intercepted by `HttpExceptionFilter`:
- Stack traces, SQL query errors, ORM exceptions, file paths, and secrets are logged internally and **never exposed** to clients.
- Sanitized client error format:
```json
{
  "statusCode": 403,
  "error": "Forbidden",
  "message": "Access denied: You are not authorized to access this patient's records.",
  "path": "/api/v1/patients/patient_secret/dashboard",
  "timestamp": "2026-09-12T12:00:00.000Z"
}
```

### 3.5 Production HTTPS & TLS Configuration
In production:
- Set `NODE_ENV=production`.
- Provide `SSL_KEY_PATH` and `SSL_CERT_PATH` for direct TLS termination, or run behind a reverse proxy (NGINX / Caddy / AWS ALB) with HSTS headers enabled.
- Helmet automatically enforces HSTS (`Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`) and CSP.

---

## 4. REST API Endpoint Specifications

### 4.1 Authentication (`/api/v1/auth`)

#### `POST /api/v1/auth/register`
Registers a new user (`CAREGIVER` or `PATIENT`).
- **Request Body**:
```json
{
  "email": "newcaregiver@smritisetu.org",
  "password": "SecurePassword@123!",
  "fullName": "Meera Goswami",
  "role": "CAREGIVER"
}
```
- **Response `201 Created`**:
```json
{
  "id": "user_e7b2...",
  "email": "newcaregiver@smritisetu.org",
  "fullName": "Meera Goswami",
  "role": "CAREGIVER",
  "createdAt": "2026-09-12T12:00:00.000Z"
}
```

#### `POST /api/v1/auth/login`
Authenticates credentials and issues access + refresh tokens.
- **Request Body**:
```json
{
  "email": "caregiver1@smritisetu.org",
  "password": "Caregiver@12345!"
}
```
- **Response `200 OK`**:
```json
{
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "7a8b9c...",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "user": {
    "id": "caregiver_1",
    "email": "caregiver1@smritisetu.org",
    "fullName": "Anita Sharma",
    "role": "CAREGIVER"
  }
}
```

#### `POST /api/v1/auth/refresh`
Rotates refresh token and issues a new access token.
- **Request Body**:
```json
{
  "refreshToken": "7a8b9c..."
}
```
- **Response `200 OK`**: Returns new `accessToken` and rotating `refreshToken`.

#### `POST /api/v1/auth/logout`
Revokes active refresh token and terminates session. Requires `Authorization: Bearer <accessToken>`.

#### `POST /api/v1/auth/password-reset/request`
Initiates a password reset. Always returns generic success to prevent email enumeration.
- **Request Body**:
```json
{
  "email": "patient1@smritisetu.org"
}
```
- **Response `200 OK`**:
```json
{
  "success": true,
  "message": "If an active account exists for this email address, password reset instructions have been sent."
}
```

#### `POST /api/v1/auth/password-reset/confirm`
Confirms token and sets new password, invalidating all existing sessions.
- **Request Body**:
```json
{
  "token": "a1b2c3...",
  "newPassword": "BrandNewPassword@987!"
}
```

---

### 4.2 Patient Records (`/api/v1/patients`)
*All endpoints require `Authorization: Bearer <token>` and pass through `RolesGuard` and `OwnershipGuard`.*

#### `GET /api/v1/patients/:id/dashboard`
Returns the patient cognitive summary and medication overview.
- **Authorization**:
  - `PATIENT`: Must match `:id`.
  - `CAREGIVER`: Must have an active relationship with `:id`.
  - `ADMIN`: Allowed.
  - Other: `403 Forbidden`.
- **Response `200 OK`**:
```json
{
  "patientId": "patient_1",
  "fullName": "Deka Da",
  "age": 74,
  "location": "Guwahati, Assam",
  "performanceSummary": {
    "averageAccuracy": 88.5,
    "averageResponseTimeSeconds": 2.1,
    "totalGamesCompleted": 14,
    "currentDifficultyLevel": 2
  },
  "medications": [
    {
      "id": "med_1",
      "medicineName": "Donepezil",
      "dosage": "5mg - after dinner",
      "scheduleTime": "20:30",
      "status": "taken"
    }
  ]
}
```

#### `GET /api/v1/patients/:id/medications`
Returns scheduled medications for the patient.

---

### 4.3 Caregiver (`/api/v1/caregivers`)

#### `GET /api/v1/caregivers/:id/patients`
Returns list of connected authorized patients for caregiver `:id`.
- **Authorization**: `ADMIN` or the caregiver themself (`userId === :id`). Attempts by other caregivers return `403 Forbidden`.
- **Response `200 OK`**:
```json
{
  "caregiverId": "caregiver_1",
  "totalConnected": 2,
  "patients": [
    {
      "relationshipId": "rel_1",
      "patientId": "patient_1",
      "fullName": "Deka Da",
      "relationshipType": "Primary Caregiver",
      "isActive": true,
      "performanceSummary": { ... }
    }
  ]
}
```

---

### 4.4 Admin (`/api/v1/admin`)

#### `GET /api/v1/admin/users`
Returns all registered system users (passwords and salts redacted).
- **Authorization**: `ADMIN` only. `CAREGIVER` or `PATIENT` receiving `403 Forbidden`.

---

### 4.5 Sync (`/api/v1/sync`)

#### `POST /api/v1/sync/batch`
Synchronizes offline client operations with idempotency checks.
- **Authorization**: Requires Bearer JWT.
- **Idempotency**: Retransmitting an operation with the same `operationId` returns `CONFLICT_IGNORED` without executing duplicate database mutations.
- **Response `200 OK`**:
```json
{
  "batchId": "batch_101",
  "processedAt": "2026-09-12T12:00:00.000Z",
  "results": [
    {
      "operationId": "op_uuid_1",
      "status": "SUCCESS",
      "serverSyncTimestamp": "2026-09-12T12:00:00.000Z"
    }
  ]
}
```
