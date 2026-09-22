# SmritiSetu — System Architecture & Data Flow Diagrams

> **Document:** SIH Grand Finale Architectural Reference  
> **System Architecture:** Offline-First Dual-Client (Patient/Caregiver) with REST Sync Gateway  

---

## 1. High-Level System Architecture

```mermaid
flowchart TB
    subgraph Client["Mobile & Web Client (Flutter 3.x)"]
        subgraph UI["Presentation Layer"]
            EH["Elderly Home & Accessibility UI"]
            CG["Caregiver Collaboration Dashboard"]
            GM["Cognitive Games (4 Types)"]
            MED["Medication Adherence Module"]
        end

        subgraph Logic["State & Domain Layer"]
            CTRL["State Controllers (ChangeNotifier)"]
            AD["Adaptive Difficulty Engine"]
            SEC["TokenVault & Security Service"]
            VOICE["VoiceService (Bhashini + Platform TTS)"]
        end

        subgraph LocalData["Local Data & Storage"]
            SQL["SQLite Engine (WAL Mode, 14 Tables)"]
            QUEUE["Persistent SyncQueue"]
            SECSTORE["Flutter Secure Storage (Keystore/Keychain)"]
        end

        subgraph SyncEngine["Background Sync Engine"]
            SM["SyncManagerImpl (Batching & Backoff)"]
            NET["NetworkInfo Monitor"]
        end
    end

    subgraph Network["Network Boundary (Zero-Trust)"]
        HTTPS["HTTPS / TLS 1.3"]
        JWT["Bearer JWT Token Header"]
    end

    subgraph Server["Backend Services (Node.js / Express / NestJS)"]
        GW["API Gateway & Reverse Proxy"]
        RL["Rate Limiter (Express-Rate-Limit)"]
        AUTH["Auth & JWT RBAC Guards"]
        IDOR["Caregiver Ownership & IDOR Filter"]
        SYNC_API["Idempotent Sync Ingestion Controller"]
        ML["Explainable ML Pipeline (Logistic / Linear Trend)"]
        AUDIT["Immutable Audit Logger"]
        DB[(Server Relational Database)]
    end

    subgraph External["External Cloud Services"]
        BHASHINI["Bhashini Government AI API (TTS / STT)"]
    end

    %% Client internal flow
    UI --> Logic
    Logic --> LocalData
    LocalData --> SyncEngine
    VOICE -.->|Online Primary| BHASHINI
    VOICE -.->|Offline Fallback| Logic

    %% Client to Server flow
    SyncEngine -->|Idempotent Batches| Network
    Network --> GW
    GW --> RL
    RL --> AUTH
    AUTH --> IDOR
    IDOR --> SYNC_API
    IDOR --> ML
    SYNC_API --> DB
    SYNC_API --> AUDIT
```

---

## 2. Offline-First Write & Synchronization Flow

This sequence visualizes what happens when an elderly patient plays a game or confirms medication while offline, and how synchronization reconciles automatically when connection returns.

```mermaid
sequenceDiagram
    autonumber
    actor Patient as Elderly Patient
    participant UI as Flutter Screen
    participant DB as Local SQLite
    participant Queue as SyncQueue (SQLite)
    participant SM as SyncManager
    participant Net as Network Monitor
    participant Server as Backend API Gateway
    participant SDB as Server Database

    Note over Patient,Queue: SCENARIO A: PATIENT IS OFFLINE
    Patient->>UI: Complete Game / Confirm Medication
    UI->>DB: INSERT GameSession, GameResult, PerformanceMetrics
    DB-->>UI: Transaction Committed Locally (<5ms)
    UI->>Queue: Enqueue SyncItem (UUIDv4 token, Status: PENDING)
    Queue-->>UI: Stored in Persistent Queue
    UI->>Patient: Display Celebration & Score Immediately (Zero Lag)

    Note over SM,Net: SCENARIO B: NETWORK RESTORATION DETECTED
    Net->>SM: onConnectivityChanged(true)
    SM->>Queue: Fetch Pending Operations (Limit: batchSize 20)
    Queue-->>SM: List<SyncItem> (Eligible by Backoff Policy)
    
    SM->>Server: POST /api/v1/sync/batch (Bearer JWT, Batch of Ops)
    Server->>Server: Verify Caregiver/Patient Ownership (IDOR Guard)
    Server->>SDB: Check operation_id for Duplication
    
    alt Operation Already Ingested (Network Replay)
        Server->>SDB: Ignore Duplicate (Idempotency Safe)
        Server-->>SM: Status: CONFLICT_IGNORED
    else New Operation
        Server->>SDB: Insert Record
        Server-->>SM: Status: SUCCESS
    end

    SM->>Queue: Mark Operation Status: COMPLETED / DELETE
    SM->>UI: Notify Sync Complete (Update Pending Badge to 0)
```

---

## 3. Dual-Tier Regional Voice Synthesis Architecture

How the speech engine ensures zero failures even during network blackouts in remote North-Eastern villages:

```mermaid
flowchart TD
    START(["Voice Instruction Triggered"]) --> SANITIZE["Sanitize PHI via PatientDataSanitizer"]
    SANITIZE --> CHECK_NET{"Is Network Connected &<br/>Bhashini Configured?"}
    
    CHECK_NET -- Yes --> BHASHINI_REQ["Invoke Bhashini Cloud AI API<br/>(Regional Indian Intonation)"]
    BHASHINI_REQ --> BHASHINI_RESP{"API Success<br/>within 3s?"}
    
    BHASHINI_RESP -- Yes --> PLAY_CLOUD["Stream & Play Audio Stream"]
    PLAY_CLOUD --> END(["Instruction Complete"])
    
    CHECK_NET -- No --> NATIVE_FALLBACK["Fallback: On-Device Platform TTS<br/>(Android TTS / iOS AVSpeech / Windows SAPI)"]
    BHASHINI_RESP -- No (Timeout/Error) --> NATIVE_FALLBACK
    
    NATIVE_FALLBACK --> PLAY_NATIVE["Synthesize Audio Locally<br/>(Zero Delay, Offline Safe)"]
    PLAY_NATIVE --> END
```

---

## 4. Caregiver Zero-Trust Security & Authorization Architecture

How SmritiSetu strictly prevents Insecure Direct Object References (IDOR) and unauthorized surveillance:

```mermaid
flowchart LR
    REQ["Caregiver Request:<br/>GET /api/v1/caregiver/patient/:patientId/dashboard"] --> JWT_CHECK{"JWT Valid &<br/>Role == CAREGIVER?"}
    
    JWT_CHECK -- No --> E401["HTTP 401 Unauthorized"]
    
    JWT_CHECK -- Yes --> REL_CHECK{"Does active relation exist in<br/>caregiver_patient_relationships<br/>between requester and patientId?"}
    
    REL_CHECK -- No (Unauthorized/Attacker) --> AUDIT_ALERT["Log Security Alert in AuditLog"]
    AUDIT_ALERT --> E403["HTTP 403 Forbidden<br/>(Zero-Trust Rejection)"]
    
    REL_CHECK -- Yes --> SERVE["Query & Aggregate Longitudinal Trends"]
    SERVE --> AUDIT_OK["Log Read Access in AuditLog"]
    AUDIT_OK --> RESP["HTTP 200 OK with Anonymized Dashboard Data"]
```
