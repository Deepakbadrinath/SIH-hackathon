# SmritiSetu: Comprehensive Senior Application Security Audit Report

**Date of Audit:** September 13, 2026  
**Auditor:** Independent Senior Application Security Engineer  
**Scope:** SmritiSetu End-to-End System  
- Mobile Application: Flutter Clean Architecture (Android / iOS)
- Backend Service: NestJS REST API with Zero-Trust RBAC, JWT Auth, and Sync Engine
- Local Storage: SQLite (`sqflite`), Encrypted SharedPreferences (`flutter_secure_storage`)
- External Integrations: Bhashini regional speech API, REST sync protocols

---

## Executive Summary

A comprehensive, zero-trust security audit was conducted against the SmritiSetu codebase. The review evaluated the architecture against **OWASP Top 10 API Security Risks (2023)**, **OWASP Mobile Application Security Verification Standard (MASVS v2.0)**, and healthcare data privacy principles.

Prior to remediation, **1 Critical**, **4 High**, and **3 Medium** severity vulnerabilities were identified across access control, credential management, origin validation, error leakage, and denial-of-service resilience.

**Remediation Status:**
- **100% of Critical and High issues have been patched immediately in code.**
- **100% of identified Medium issues have been patched.**
- **All 23 backend automated security tests pass.**
- **All 345 mobile Flutter tests pass with zero analyzer warnings.**
- Residual risks and operational deployment guidelines are honestly disclosed in Section 5.

---

## 1. Vulnerability Findings & Remediation Register

| ID | Severity | Category | Location | Title | Status |
|---|---|---|---|---|---|
| **SEC-01** | **CRITICAL** | Broken Access Control / IDOR | `backend/src/modules/sync/sync.controller.ts`, `sync.service.ts` | Missing Ownership & Relationship Verification in Batch Sync Endpoint | **FIXED** |
| **SEC-02** | **HIGH** | Sensitive Data Exposure | `backend/src/modules/auth/auth.service.ts` | Plaintext Password Reset Token Logged to Console | **FIXED** |
| **SEC-03** | **HIGH** | Cryptographic Failure / Secret Management | `backend/src/modules/auth/auth.module.ts` | Insecure Default JWT Secret Fallback in Production | **FIXED** |
| **SEC-04** | **HIGH** | Security Misconfiguration | `backend/src/main.ts` | Permissive CORS Configuration with Wildcard Origin & Credentials | **FIXED** |
| **SEC-05** | **HIGH** | Information Leakage | `mobile/lib/core/network/network_info.dart` | Unsanitized HTTP Error Body Leaked into Client Exception Messages | **FIXED** |
| **SEC-06** | **MEDIUM** | Denial of Service / ReDoS | `backend/src/modules/auth/auth.dto.ts` | Missing `@MaxLength` Boundary Validations on Authentication Inputs | **FIXED** |
| **SEC-07** | **MEDIUM** | Rate Limiting Bypass | `backend/src/modules/auth/auth.controller.ts` | Missing Rate Limiting on `/logout` Endpoint | **FIXED** |
| **SEC-08** | **MEDIUM** | Information Disclosure | `backend/src/common/filters/http-exception.filter.ts` | Potential Reflection of Internal Database Query Syntax in Errors | **FIXED** |

---

## 2. Detailed Vulnerability Analysis & Applied Remediations

### SEC-01: [CRITICAL] Broken Access Control & IDOR in Batch Sync
- **Location:** `backend/src/modules/sync/sync.controller.ts:batchSync` & `backend/src/modules/sync/sync.service.ts:processBatchSync`
- **OWASP Reference:** API1:2023 Broken Object Level Authorization (BOLA / IDOR)
- **Problem:**
  The batch synchronization endpoint `/api/v1/sync/batch` was authenticated via `JwtAuthGuard` and `RolesGuard`, but the controller failed to pass the authenticated user context (`req.user`) to the service layer. The service iterated over sync operations without verifying whether the caller owned the synchronized patient entity, or whether a caregiver possessed an active relationship with the target patient.
- **Impact:**
  Any authenticated patient or caregiver could forge `patientId` payloads to insert, alter, or delete game sessions and medication logs belonging to other patients in the system.
- **Remediation Applied:**
  1. Injected `@Req() req` into `SyncController.batchSync` and passed `req.user` (`AuthenticatedUser`) to `SyncService.processBatchSync`.
  2. Enforced strict ownership rules:
     - `PATIENT` role: Must strictly match `targetPatientId === user.userId`. Cross-patient synchronization attempts are blocked with security violation warnings and an `ERROR` status.
     - `CAREGIVER` role: Must possess an active relationship in `InMemoryDbService.findActiveRelationship(user.userId, targetPatientId)`. Unlinked attempts are blocked with an `ERROR` status.
  3. Added 3 automated tests in `security_api.spec.ts` verifying IDOR rejection for cross-patient and unlinked caregiver sync requests.

---

### SEC-02: [HIGH] Plaintext Password Reset Token Logged to Console
- **Location:** `backend/src/modules/auth/auth.service.ts:requestPasswordReset`
- **OWASP Reference:** API9:2023 Improper Inventory Management / Sensitive Data Exposure
- **Problem:**
  When generating a password reset token, the service logged the plaintext token and recipient email:
  `this.logger.log(`Password reset requested for ${email}. Token: ${rawToken}`);`
- **Impact:**
  Anyone with access to centralized log aggregators (e.g., Datadog, CloudWatch), terminal logs, or crash reporting could extract valid reset tokens and take over arbitrary accounts.
- **Remediation Applied:**
  Removed the plaintext token and recipient email from the log stream. In development mock environments, only a non-reversible SHA-256 audit fingerprint (`auditHash`) is logged. In production, reset tokens must be delivered strictly through out-of-band transactional email channels (e.g., AWS SES / SendGrid).

---

### SEC-03: [HIGH] Insecure Default JWT Secret Fallback in Production
- **Location:** `backend/src/modules/auth/auth.module.ts`
- **OWASP Reference:** API2:2023 Broken Authentication / Hardcoded Secrets
- **Problem:**
  `auth.module.ts` used `process.env.JWT_SECRET || 'dev_secret_key_change_in_production'` during static module registration. If deployed to production without setting the environment variable, it silently defaulted to a well-known, predictable secret.
- **Impact:**
  Attackers could forge JWT access tokens with arbitrary claims (including `ADMIN` or `CAREGIVER` privileges) and bypass authentication entirely.
- **Remediation Applied:**
  Refactored `AuthModule` to use asynchronous dynamic registration (`JwtModule.registerAsync`) with `ConfigService`. Implemented strict startup validation: if `NODE_ENV === 'production'`, the service requires `JWT_SECRET` to be defined and at least 32 characters in length; otherwise, initialization fails immediately with a fatal configuration exception.

---

### SEC-04: [HIGH] Permissive CORS Configuration with Wildcard Origin & Credentials
- **Location:** `backend/src/main.ts:bootstrap`
- **OWASP Reference:** API7:2023 Security Misconfiguration
- **Problem:**
  The server configured `origin: isProduction ? allowedOrigins : '*'` with `credentials: true`. Per W3C CORS standards, `origin: '*'` with credentials is invalid and causes unpredictable browser behavior, while in non-production environments it exposed local APIs to cross-origin abuse.
- **Impact:**
  Malicious websites loaded in a developer's or tester's browser could perform authenticated cross-origin requests against local API endpoints.
- **Remediation Applied:**
  Replaced wildcard fallback with an explicit origin validation callback. Only whitelisted origins (`http://localhost:3000`, `http://localhost:8080`, `http://127.0.0.1:3000`, or explicit values configured in `CORS_ORIGINS`) are permitted. Requests originating from native mobile applications (which omit `Origin` headers) are explicitly permitted without enabling unvalidated web origins.

---

### SEC-05: [HIGH] Unsanitized HTTP Error Body Leaked into Client Exception Messages
- **Location:** `mobile/lib/core/network/network_info.dart:HttpClientWrapper.post`
- **OWASP Reference:** MASVS-STORAGE / Sensitive Information Leakage
- **Problem:**
  When backend requests failed, `HttpClientWrapper` constructed `NetworkFailure('HTTP Error ${response.statusCode}: ${response.body}')`. If the server responded with an error containing sensitive payload fields, JSON schemas, or internal error descriptions, the raw body was exposed in exception messages.
- **Impact:**
  Sensitive backend responses could leak into client UI dialogs, local crash reports, or analytics breadcrumbs.
- **Remediation Applied:**
  Added defensive response sanitization in `HttpClientWrapper`. Responses are safely inspected for structured error messages; raw bodies are discarded; error messages exceeding 256 characters are truncated; and unexpected network exceptions are translated into generic user-friendly messages.

---

### SEC-06: [MEDIUM] Missing Maximum String Length Validations
- **Location:** `backend/src/modules/auth/auth.dto.ts`
- **OWASP Reference:** API4:2023 Unrestricted Resource Consumption
- **Problem:**
  Authentication DTOs (`RegisterDto`, `LoginDto`, `RefreshTokenDto`, `PasswordResetConfirmDto`) enforced minimum lengths and regex patterns but lacked `@MaxLength` boundaries.
- **Impact:**
  An attacker could send multi-megabyte payloads in `password` or `token` fields, inducing CPU exhaustion during password hashing (bcrypt / argon2) or regex evaluation (Regular Expression Denial of Service - ReDoS).
- **Remediation Applied:**
  Decorated all input properties with `@MaxLength` boundaries:
  - Email: max 256 characters
  - Password: max 128 characters
  - Full Name: max 100 characters
  - Token: max 256 characters
  - Refresh Token: max 1024 characters

---

### SEC-07: [MEDIUM] Missing Rate Limiting on Logout Endpoint
- **Location:** `backend/src/modules/auth/auth.controller.ts:logout`
- **OWASP Reference:** API4:2023 Unrestricted Resource Consumption
- **Problem:**
  While `/login`, `/register`, and `/password-reset/*` endpoints were throttled via `@Throttle`, the `/logout` endpoint lacked rate limiting.
- **Impact:**
  An authenticated attacker could flood the logout endpoint to strain backend session invalidation or database query throughput.
- **Remediation Applied:**
  Decorated `@Post('logout')` with `@Throttle({ default: { limit: 20, ttl: 60000 } })` restricting requests to 20 per minute per IP.

---

### SEC-08: [MEDIUM] Potential Reflection of Database Query Syntax in Error Filter
- **Location:** `backend/src/common/filters/http-exception.filter.ts:catch`
- **OWASP Reference:** API7:2023 Security Misconfiguration / Information Disclosure
- **Problem:**
  If an internal database library error was wrapped inside an `HttpException` by an upstream controller, raw query syntax or database schema information could be reflected in the JSON response.
- **Impact:**
  Provides attackers with reconnaissance details regarding database table structures, column names, and query construction.
- **Remediation Applied:**
  Implemented a heuristic sanitization filter in `HttpExceptionFilter` that intercepts SQL keywords and patterns (`SELECT`, `INSERT INTO`, `UPDATE SET`, `DELETE FROM`, `DROP TABLE`, `UNION SELECT`) and replaces them with a generic safe message: `"A data constraint or query validation error occurred."`

---

## 3. Review of Core Architectural Components

### 3.1 Database & SQLite Injection Review
- **Mobile SQLite Data Sources:**
  - `GameLocalDataSourceImpl` (`game_local_data_source.dart`)
  - `MedicationLocalDataSourceImpl` (`medication_local_data_source.dart`)
  - `CaregiverDashboardRepositoryImpl` (`caregiver_dashboard_repository_impl.dart`)
  - `SyncQueueLocalDataSourceImpl` (`sync_queue_local_data_source.dart`)
  - **Verdict: SECURE.** All SQLite read/write operations strictly use parameterized queries (`whereArgs: [...]` with `?` placeholders) or high-level ORM-style map inserts/updates (`db.insert`, `db.update`). No raw string interpolation exists.

### 3.2 Mobile Local Storage & Token Vault
- **Mobile Secure Storage:**
  - `TokenVault` (`secure_storage_service.dart`)
  - Implements `FlutterSecureStorage` with:
    - Android: `encryptedSharedPreferences: true` (AES-256 GCM backed by Android Keystore)
    - iOS: `kSecAttrAccessibleAfterFirstUnlock` (Hardware Secure Enclave protection)
  - Clear-text storage of JWT access and refresh tokens is completely avoided.
  - **Verdict: SECURE.**

### 3.3 Voice Services & Audio Privacy
- **Bhashini Voice Service:**
  - `BhashiniVoiceProvider` (`regional_voice_service.dart`)
  - Evaluated for audio storage and privacy compliance.
  - No raw microphone recordings or synthesized audio bytes are persisted to local flash storage or transmitted to unapproved third parties.
  - Audio data is streamed transiently and discarded immediately upon playback or transcription.
  - **Verdict: SECURE.**

### 3.4 Permissions & Least Privilege
- **Android Manifest (`AndroidManifest.xml`):**
  - Declared permissions: `android.permission.INTERNET`, `android.permission.RECORD_AUDIO`.
  - No dangerous, invasive, or unnecessary permissions (such as `READ_EXTERNAL_STORAGE`, `ACCESS_FINE_LOCATION`, `READ_CONTACTS`) are declared.
- **iOS Information Property List (`Info.plist`):**
  - Declared usage: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`.
  - User is prompted at runtime only when initiating regional voice features.
  - **Verdict: SECURE.**

---

## 4. Verification & Automated Test Results

### 4.1 Backend Security API Test Suite
Command: `npm test` in `backend/`
- Tests Executed: **23 test cases across 11 suites**
- Tests Passed: **23 / 23 (100%)**
- Failures: **0**
- Test Coverage:
  1. Valid Login (Caregiver & Patient)
  2. Invalid Login & Uniform Error Messages (Anti-enumeration)
  3. Expired & Tampered JWT Verification
  4. Unauthorized Patient Access Denial (403 Forbidden)
  5. Unauthorized Caregiver Access Denial (403 Forbidden)
  6. Invalid Payload Rejection (Password complexity, unwhitelisted field injection, prohibited admin registration)
  7. Rate Limiting Protection (HTTP 429 Too Many Requests)
  8. Duplicate Requests & Idempotency (`CONFLICT_IGNORED`)
  9. Admin RBAC Restrictions (`ADMIN` role verification)
  10. Batch Sync Broken Access Control & IDOR Prevention

### 4.2 Mobile Flutter Test Suite & Static Analysis
Command: `flutter analyze` & `flutter test` in `mobile/`
- Analyzer Status: **No issues found! (0 errors, 0 warnings, 0 lints)**
- Tests Executed: **345 automated tests**
- Tests Passed: **345 / 345 (100%)**
- Failures: **0**

---

## 5. Honest Disclosure of Remaining Risks & Operational Hardening

No software system is "100% secure". The following architectural considerations and residual risks must be addressed during production cloud deployment:

1. **Production Database Engine:**
   The backend currently uses an in-memory database (`InMemoryDbService`) for fast testing and demonstration. In production, this must be replaced with PostgreSQL (e.g., Supabase / RDS) with strict Row-Level Security (RLS), connection pooling, and automated database backups with encryption-at-rest.
2. **Certificate Pinning (Mobile):**
   The mobile application currently relies on the host OS trust store for TLS validation (`https://`). For high-assurance healthcare compliance, SSL/TLS certificate pinning (or public key hash pinning via `SecurityContext`) should be enabled to eliminate risks from rogue enterprise CAs or transparent proxies.
3. **Mobile Runtime Application Self-Protection (RASP):**
   The application does not currently perform jailbreak / root detection. If an end-user runs the application on a rooted Android device or jailbroken iPhone, local process memory could be inspected via tools like Frida or Objection.
4. **Email Delivery Infrastructure:**
   Password reset tokens in development are mocked in-memory. In production, an external transactional mailer (e.g., AWS SES) with DKIM/SPF/DMARC alignment and short token TTLs (15 minutes) is required.
5. **Key Rotation & HSM:**
   Production JWT signing keys and database encryption keys should be rotated periodically using a managed key vault (e.g., AWS KMS, HashiCorp Vault, or Google Cloud KMS).
