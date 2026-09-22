# SmritiSetu — Security & Privacy Architecture

## 1. Security Principles & Threat Model

SmritiSetu processes sensitive cognitive interaction telemetry and daily routine data for elderly individuals. Security and privacy are primary non-functional requirements embedded directly into the system design.

### Threat Model Matrix:
| Threat Category | Potential Attack Vector | Mitigation in SmritiSetu |
|---|---|---|
| **Unauthorized Access** | Intruder attempts to view cognitive trends or patient profile | JWT Bearer tokens with short expiry (15 min), Argon2/Bcrypt password hashing, Role-Based Access Control (RBAC). |
| **Data in Transit Interception** | Man-in-the-Middle (MitM) over public Wi-Fi or cellular network | Enforced TLS 1.3 with Certificate Pinning in production builds, strict HSTS headers. |
| **Device Compromise / Theft** | Physical extraction of SQLite database file from mobile device | Sensitive credentials stored in hardware-backed Secure Enclave / Keystore (`flutter_secure_storage`). |
| **SQL Injection** | Malicious input injected via profile or search fields | 100% parameterized queries in SQLite and ORM/query builder on the server. Zero raw SQL concatenation. |
| **Denial of Service** | Flooding backend sync or authentication endpoints | `@nestjs/throttler` rate limiting (max 10 auth requests/min, 100 sync requests/min). |
| **Unauthorized Third-Party AI Leakage** | Transmission of patient identities to external LLMs/APIs | Strict data minimization: only acoustic speech features are sent to Bhashini; patient names, photos, and IDs are never sent to external AI services. |

---

## 2. Authentication & Authorization Architecture

### Role-Based Access Control (RBAC):
- **PATIENT:**
  - Can read own profile and assigned games.
  - Can submit game sessions and medication logs.
  - **Cannot** view system audit trails or modify caregiver relationships.
- **CAREGIVER (PRIMARY):**
  - Can view cognitive game trends and medication adherence graphs.
  - Can configure medication schedules and emergency contacts.
  - Can invite secondary caregivers.
- **CAREGIVER (VIEWER):**
  - Read-only access to trends and medication logs.

### Token Lifecycle:
- **Access Token:** JWT with 15-minute lifespan containing `sub` (User ID), `role`, and `patientId`.
- **Refresh Token:** High-entropy random token stored in HttpOnly cookie or secure storage with 30-day lifespan and cryptographic rotation.

---

## 3. Data Minimization & Privacy Controls

1. **Local-First Retention:** All granular per-trial tap times and hesitation recordings remain on the local device by default. Only aggregated performance metrics (average response time, accuracy, error count) are synchronized to the caregiver dashboard.
2. **Audit Logging:** Every authorization attempt, relationship link, profile edit, and medication status change generates an immutable `audit_logs` entry.
3. **Right to Erasure (Data Purge):** Patients or primary caregivers can trigger complete local database wipe and remote profile deletion via a cryptographically confirmed action.
