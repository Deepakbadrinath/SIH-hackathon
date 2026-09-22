# SmritiSetu — Offline-First Architecture & Robust Synchronization

> **Document:** SIH Grand Finale Technical Deep Dive  
> **Topic:** Local-First Persistence, SyncQueue, Idempotency, and Conflict Resolution  
> **Design Philosophy:** Zero-Drop Reliability • Resilient to Intermittent Connectivity • Deterministic State  

---

## 1. Why SQLite? Why Offline-First?

In the North-Eastern Region of India (NER) and rural communities nationwide, mobile network connectivity is inherently intermittent. Relying on continuous cloud connections for an elderly patient’s daily cognitive routine is fatal to app adoption.

### Engineering Rationale for SQLite:
1. **Zero Latency & 100% Availability**: Every game session, trial touch, and medication confirmation writes locally in `< 5ms`. The app never displays a network spinner to an elderly patient.
2. **ACID Transactional Guarantees**: SQLite provides atomic commits across relational entities (e.g. committing `GameSession`, `GameResult`, and `PerformanceMetrics` in one atomic transaction).
3. **Write-Ahead Logging (WAL Mode)**: Enables concurrent reads while a write is occurring, eliminating database lock contention between background synchronization and UI rendering.
4. **Structured Querying & Longitudinal Analytics**: Relational schema allows instant local aggregations (averaging accuracy over 7, 14, or 30 days) on-device without calling external servers.

---

## 2. The Complete Offline-First Lifecycle

```
[Local Event: Game / Medication]
           │
           ▼
[Step 1: Local SQLite Write] ───► ACID Transaction Committed Locally
           │
           ▼
[Step 2: SyncQueue Ingestion] ──► Persistent Queue Entry (UUIDv4, Status: PENDING)
           │
           ▼
[Step 3: Network Monitor] ──────► NetworkInfo detects Online status
           │
           ▼
[Step 4: Bounded Batching] ─────► Fetch top 20 eligible operations (Backoff Filtered)
           │
           ▼
[Step 5: Idempotent Upload] ────► POST /api/v1/sync/batch (Bearer JWT, UUID tokens)
           │
           ▼
[Step 6: Server Verification] ──► Deduplication Check & Relational Ownership Check
           │
           ▼
[Step 7: Reconcile Queue] ──────► Mark COMPLETED / DELETE from SyncQueue
```

---

## 3. Handling Edge Cases & Network Chaos

### 3.1 What Prevents Duplicate Synchronization? (Idempotency)
When an upload succeeds on the server but the connection drops before the mobile client receives the HTTP response, standard sync engines re-upload the record upon reconnect, resulting in duplicate game sessions and distorted caregiver analytics.

**SmritiSetu’s Solution**:
- Every operation generated on the client is stamped with an immutable **UUIDv4 `operation_id`**.
- When the backend receives an operation, it inspects its historical transaction log:
  ```typescript
  // Backend Idempotency Guard in sync.service.ts
  const existingOp = await this.syncRepository.findByOperationId(op.operationId);
  if (existingOp) {
    // Record already processed; acknowledge without duplicating
    return { operationId: op.operationId, status: 'CONFLICT_IGNORED' };
  }
  ```
- The operation is acknowledged safely without creating duplicate database rows.

### 3.2 Exponential Backoff Retry Policy
If the server returns an HTTP 500 error or a timeout occurs, operations must not be retried infinitely in a tight loop (which drains mobile battery and overloads servers).

- **Policy**:
  - Initial delay: $2\text{ seconds}$
  - Multiplier: $2.0\times$
  - Maximum delay: $60\text{ seconds}$
  - Max Retries: **5 attempts**
- Once an operation exceeds 5 failed attempts, its status transitions to `FAILED_PERMANENT`. It remains preserved in the local queue for diagnostics without blocking subsequent operations.

### 3.3 Crash Recovery & App Termination During Sync
If the user's device runs out of battery or the OS kills the app while an upload is marked `IN_PROGRESS`:
- On the next app startup, `SyncManagerImpl.initialize()` executes `recoverUnfinishedOperations()`.
- Any operation stranded in `IN_PROGRESS` is reset back to `PENDING` with its retry count intact:
  ```sql
  UPDATE sync_queue 
  SET sync_status = 'PENDING' 
  WHERE sync_status = 'IN_PROGRESS';
  ```

### 3.4 Deterministic Conflict Resolution Strategy
When records are updated across multiple sessions or devices, conflicts must be resolved deterministically without silent data corruption:

| Entity Type | Conflict Strategy | Rationale |
| :--- | :--- | :--- |
| **Game Sessions & Results** | **Append-Only (Immutability)** | Completed gameplay telemetry is historical fact; trials are never edited, only appended. |
| **Medication Logs** | **First-Confirmed-Wins** | Once a dose is marked `TAKEN` by patient or caregiver, subsequent `MISSED` triggers are superseded. |
| **Patient Settings (Font/Dialect)** | **Last-Write-Wins (LWW)** | Higher UTC timestamp `updated_at` takes precedence. |

---

## 4. Local SQLite Schema Overview (14 Relational Entities)

The database schema (`DatabaseConstants.databaseName = 'smriti_setu.db'`) enforces strict foreign keys with cascading deletions:

1. `users` — Base user identity and role (`PATIENT` or `CAREGIVER`).
2. `patients` — Patient clinical profile, birth year, dialect, and font preferences.
3. `caregivers` — Caregiver profile, contact phone, and relationship title.
4. `caregiver_patient_relationships` — Zero-trust access link with access role (`PRIMARY`, `SECONDARY`, `VIEWER`).
5. `game_sessions` — Game instance metadata, type, difficulty level, and duration.
6. `game_results` — Summary metrics (score, accuracy percentage, average response time, hesitation pause).
7. `performance_metrics` — Granular per-trial behavioral telemetry (stimulus ID, user choice, reaction latency).
8. `difficulty_history` — Longitudinal history of adaptive level promotions, demotions, and mathematical scores.
9. `medications` — Active prescriptions, dosages, and instructions.
10. `medication_schedules` — Scheduled dosing times, meal relation, and active weekdays.
11. `medication_logs` — Dosing compliance entries (`TAKEN`, `MISSED`, `SKIPPED`) with confirming role.
12. `sync_queue` — Persistent offline outbox (`operation_id`, `payload_json`, `retry_count`, `sync_status`).
13. `audit_logs` — Immutable client audit trail recording sensitive data access.
14. `app_settings` — Key-value configuration cache.

---

## 5. Summary for Judges

> SmritiSetu is **not** an app that "caches some data when offline."  
> It is an **offline-first application** where local SQLite is the primary source of truth, and the cloud is an asynchronous backup and caregiver collaboration hub. It guarantees 100% operational availability with zero dependence on continuous internet connectivity.
