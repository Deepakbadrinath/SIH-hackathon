# SmritiSetu Robust Offline Synchronization Architecture (Phase 15)

## 1. Executive Summary
SmritiSetu is engineered specifically for elderly cognitive assistance in rural and remote regions of North East India where connectivity is frequently intermittent, high-latency, or completely offline for extended periods.

The synchronization subsystem guarantees:
- **Zero Local Data Loss**: Local writes always commit to encrypted SQLite storage before entering the synchronization queue.
- **Strict Idempotency**: Every sync operation carries a globally unique UUIDv4 idempotency key (`operationId`). Retrying a request will never create duplicate game sessions or medication records.
- **Exponential Backoff with Max Retry Policy**: Retries back off exponentially to avoid network congestion and battery drain, capping at a maximum retry limit (default: 5 retries). The engine **never retries forever**.
- **Crash & Reboot Resilience**: Operations stranded in `IN_PROGRESS` due to process termination or device reboot are safely recovered back to `PENDING` upon application boot.
- **Partial Synchronization**: Each operation within a batch is acknowledged independently, ensuring that successful uploads are committed even if peer operations in the same batch fail.

---

## 2. Synchronization Architecture & Lifecycle

```
           [User Action / Cognitive Game / Medication Action]
                                   │
                                   ▼
                       1. Local SQLite Write
                   (Committed with is_synced = 0)
                                   │
                                   ▼
                 2. Enqueue to Persistent SyncQueue
              (UUIDv4 operationId, status = PENDING,
                 retryCount = 0, timestamp = now)
                                   │
                                   ▼
                    3. Network Connectivity Check
                                   │
                ┌──────────────────┴──────────────────┐
                ▼                                     ▼
        [Offline Mode]                          [Online Mode]
   (Retain in SQLite queue,              (Trigger Batch Upload via
    wait for network transition)             SyncManager.synchronize())
                                                      │
                                                      ▼
                                            4. Exponential Backoff
                                                & Retry Filter
                                          (Skip if still in backoff window;
                                           mark FAILED if >= maxRetries)
                                                      │
                                                      ▼
                                            5. Mark IN_PROGRESS
                                                      │
                                                      ▼
                                           6. POST /api/v1/sync/batch
                                                      │
                 ┌────────────────────────────────────┴────────────────────────────────────┐
                 ▼                                                                         ▼
     [Network Drop / Timeout / 5xx]                                                [Server Response]
      - Increment retryCount                                                7. Process Per-Operation Results:
      - Calculate next backoff                                                     │
      - Revert status to FAILED                                                    ├── [SUCCESS]
      - If retryCount >= maxRetries:                                               │   - Mark COMPLETED
        mark PERMANENTLY FAILED                                                    │   - Update local is_synced = 1
                                                                                   │
                                                                                   ├── [CONFLICT_IGNORED]
                                                                                   │   - Idempotent duplicate
                                                                                   │   - Mark COMPLETED
                                                                                   │   - Update local is_synced = 1
                                                                                   │
                                                                                   └── [ERROR]
                                                                                       - Increment retryCount
                                                                                       - Mark FAILED / Backoff
```

---

## 3. Core Components

### 3.1 `SyncManager`
The central orchestrator in `mobile/lib/domain/services/sync_manager.dart` and `mobile/lib/features/offline_sync/data/services/sync_manager_impl.dart`.
- **`initialize()`**: Recovers orphaned `IN_PROGRESS` operations from past crashes, attaches connectivity listeners, and initiates auto-sync if connected.
- **`enqueueOperation(...)`**: Atomically enqueues a new operation with a UUIDv4 operation ID.
- **`synchronizePendingBatch({bool force = false})`**: Gathers eligible pending items, respects backoff windows, packages batch requests, and handles partial outcomes.
- **`recoverUnfinishedOperations()`**: Resets stranded `IN_PROGRESS` items to `PENDING`.
- **`stateStream`**: Emits high-level status (`idle`, `syncing`, `offline`, `error`, `success`) to drive UI sync indicators.

### 3.2 `SyncQueue` (Persistent SQLite Table)
Table schema (`sync_queue`) in SQLite:
| Column | Type | Constraints | Description |
|---|---|---|---|
| `operation_id` | `TEXT` | `PRIMARY KEY` | Globally unique UUIDv4 idempotency key. |
| `entity_id` | `TEXT` | `NOT NULL` | ID of the target local entity (e.g. `session_123`). |
| `entity_type` | `TEXT` | `NOT NULL` | Entity type (`GAME_SESSION`, `GAME_RESULT`, `MEDICATION_LOG`). |
| `operation_type` | `TEXT` | `CHECK IN ('INSERT', 'UPDATE', 'DELETE')` | Operation mutation type. |
| `payload_json` | `TEXT` | `NOT NULL` | Serialized JSON payload. |
| `timestamp` | `TEXT` | `NOT NULL` | Client timestamp of creation. |
| `retry_count` | `INTEGER` | `DEFAULT 0` | Current number of failed retry attempts. |
| `sync_status` | `TEXT` | `CHECK IN ('PENDING', 'IN_PROGRESS', 'FAILED', 'COMPLETED')` | Current queue lifecycle state. |
| `last_error` | `TEXT` | `NULLABLE` | Error message from last attempt. |

---

## 4. Exponential Backoff & Maximum Retry Policy

To prevent battery drain and server thundering herds during intermittent network connectivity, retries follow a deterministic exponential backoff algorithm.

### 4.1 Formula
$$\text{delay} = \min\left(\text{maxBackoffSeconds}, \;\text{initialBackoffSeconds} \times 2^{\text{retryCount}}\right)$$

### 4.2 Configuration Parameters
- **`initialBackoffSeconds`**: 2 seconds
- **`maxBackoffSeconds`**: 300 seconds (5 minutes)
- **`maxRetries`**: 5 attempts
- **`requestTimeout`**: 15 seconds

### 4.3 Progression Table
| Retry Attempt | Calculation | Backoff Window |
|---|---|---|
| Retry 1 | $2 \times 2^1$ | 4 seconds |
| Retry 2 | $2 \times 2^2$ | 8 seconds |
| Retry 3 | $2 \times 2^3$ | 16 seconds |
| Retry 4 | $2 \times 2^4$ | 32 seconds |
| Retry 5 | $2 \times 2^5$ | 64 seconds |
| **Retry 6+** | Exceeds `maxRetries` | **Permanently Failed (Stopped)** |

> [!NOTE]
> Operations exceeding 5 retries are flagged as permanently failed with a descriptive error. They are excluded from future automated sync batches to avoid infinite loops, but remain inspectable for debugging or manual retry.

---

## 5. Crash & Reboot Recovery (Process Termination)

If the application is killed by the OS (low memory, force quit, or device reboot) while a batch is in the middle of uploading:
1. Operations remain recorded in SQLite with `sync_status = 'IN_PROGRESS'`.
2. When the app boots, `SyncManager.initialize()` executes `recoverUnfinishedOperations()`.
3. An atomic SQL statement resets all `IN_PROGRESS` rows back to `PENDING`:
   ```sql
   UPDATE sync_queue
   SET sync_status = 'PENDING',
       last_error = 'Recovered from unexpected process termination (app restart/crash)'
   WHERE sync_status = 'IN_PROGRESS';
   ```
4. The operations become immediately eligible for synchronization on the next sync cycle.

---

## 6. Deterministic Conflict Resolution Strategy

When data is generated or updated offline and synchronized later, conflicting changes are resolved deterministically based on domain semantics:

| Entity Type | Sync Strategy | Conflict Resolution Rule |
|---|---|---|
| **`GAME_SESSION`** | **Append-Only** | Game sessions are immutable once completed. If an operation with the same `operationId` or `entityId` is received by the server, the server responds with `CONFLICT_IGNORED`. The client marks the item as synchronized without creating duplicate sessions. |
| **`GAME_RESULT`** | **Append-Only** | Game results are tied 1-to-1 with sessions. Duplicate results are discarded as idempotent duplicates. |
| **`PERFORMANCE_METRICS`** | **Append-Only** | Trial metrics are strictly append-only trial logs. |
| **`MEDICATION_LOG`** | **State-Based LWW** | Medication status changes (`TAKEN`, `MISSED`, `SKIPPED`) use **Last-Write-Wins (LWW)** resolved by `action_timestamp`. A confirmed `TAKEN` event recorded offline takes precedence over an earlier scheduled `PENDING` state. |
| **`MEDICATION_SCHEDULE`** | **Last-Write-Wins** | Caregiver schedule modifications resolve via `updated_at` ISO-8601 timestamp comparison. |

---

## 7. Network Scenarios & Resilience Matrix

| Scenario | System Behavior | Outcome |
|---|---|---|
| **Complete Offline** | Write succeeds locally. Item queued as `PENDING`. Connectivity listener waits. | Zero errors displayed to patient. Data safe in SQLite. |
| **Online Available** | Write succeeds locally. `SyncManager` uploads batch immediately. | Data synced to cloud, local `is_synced = 1`. |
| **Intermittent Disconnect** | Network drops mid-upload. `HttpClientWrapper` throws socket exception or timeout. | `SyncManager` marks batch items `FAILED`, increments `retryCount`, and calculates backoff window. |
| **5xx Server Error** | Server returns HTTP 500/503. | Batch items marked `FAILED`, retry count incremented, retried after backoff. |
| **Duplicate Request** | Client re-submits previously uploaded operation. Server checks idempotency cache. | Server returns `CONFLICT_IGNORED`. Client marks item `COMPLETED` without duplicate records. |
| **App Killed During Upload** | Process terminated while uploading. | On restart, `recoverUnfinishedOperations()` resets `IN_PROGRESS` to `PENDING`. Upload resumes automatically. |
| **Partial Batch Success** | Server processes 3 out of 5 items; 2 fail due to temporary validation/network issue. | The 3 successful items are marked `COMPLETED` and `is_synced = 1`. The 2 failed items are rescheduled for retry. |
