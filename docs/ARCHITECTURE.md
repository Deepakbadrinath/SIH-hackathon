# SmritiSetu (স্মৃতি সেতু / स्मृति सेतु) — System Architecture

## 1. Executive Summary & Problem Context

**Problem Statement:** SIH26003 — AI-Based Cognitive Gaming for Elderly Dementia Patients in North Eastern Region  
**System Designation:** *SmritiSetu* (Cognitive Memory Bridge)  
**Primary Target Demographics:** Elderly individuals presenting early cognitive decline or mild dementia symptoms across the North Eastern Indian states (Assam, Manipur, Meghalaya, Tripura, Mizoram, Nagaland, Arunachal Pradesh, Sikkim) and their caregivers.

### Mandatory Clinical & Legal Disclaimer Boundary
> **MANDATORY NOTICE:**  
> *SmritiSetu* is exclusively an assistive cognitive-support, daily engagement, and non-clinical caregiver monitoring prototype. It **does not** provide medical diagnoses, clinical classifications, neurological prognosis, medical treatment prescriptions, or clinical therapy. All scores are internal application performance metrics and behavioral trends, not clinical diagnostic measurements (e.g., MMSE or MoCA scores).

---

## 2. High-Level Architectural Layers

The system enforces strict unidirectional data flow and clean feature-based modularity:

```mermaid
graph TD
    subgraph UI ["Presentation Layer (Flutter)"]
        SCREENS[Accessible Screens / WCAG AAA]
        WIDGETS[Custom 56px Touch Widgets]
        CONTROLLERS[ChangeNotifier Feature Controllers]
    end

    subgraph Domain ["Domain Layer (Pure Dart)"]
        MODELS[Immutable Domain Models]
        REPO_INTERFACES[Abstract Repository Contracts]
        SERVICE_INTERFACES[Abstract Service Contracts]
    end

    subgraph Data ["Data Layer"]
        REPO_IMPL[Repository Implementations]
        SQLITE[(Normalized SQLite Database)]
        SECURE_STORE[(Hardware Keystore / SecureStorage)]
        SYNC_ENGINE[Batch Sync Engine]
    end

    subgraph Cloud ["NestJS Enterprise Cloud Service"]
        API_GATEWAY[REST API / Helmet / Throttler]
        BATCH_SYNC[POST /api/v1/sync/batch (Idempotent)]
    end

    SCREENS --> CONTROLLERS
    WIDGETS --> CONTROLLERS
    CONTROLLERS --> REPO_INTERFACES
    CONTROLLERS --> SERVICE_INTERFACES
    REPO_INTERFACES <|.. REPO_IMPL
    REPO_IMPL --> SQLITE
    REPO_IMPL --> SECURE_STORE
    REPO_IMPL --> SYNC_ENGINE
    SYNC_ENGINE --> API_GATEWAY
    API_GATEWAY --> BATCH_SYNC
```

---

## 3. Production Feature-First Directory Structure

```
d:/SIH hackathon/
├── .gitignore                   # Production ignore rules for Flutter, Node, IDEs
├── .env.example                 # Environment template (no secrets)
├── docs/                        # Formal specifications (Architecture, Security, etc.)
│   ├── ARCHITECTURE.md
│   ├── ADAPTIVE_DIFFICULTY.md
│   ├── OFFLINE_SYNC.md
│   ├── LOCALIZATION.md
│   ├── VOICE.md
│   ├── SECURITY.md
│   └── TESTING.md
│
├── mobile/                      # Flutter Client Application
│   ├── .env.example
│   ├── pubspec.yaml
│   ├── test/
│   │   ├── adaptive_difficulty_test.dart
│   │   └── app_architecture_test.dart
│   └── lib/
│       ├── main.dart            # MultiProvider dependency injection & routing
│       ├── core/
│       │   ├── config/          # AppConfig (development, staging, production)
│       │   ├── constants/       # AppConstants & Medical Disclaimer
│       │   ├── database/        # DatabaseHelper, DatabaseConstants, Tables & Indexes
│       │   ├── error/           # Failures & Exceptions hierarchy
│       │   ├── network/         # NetworkInfo & HttpClientWrapper
│       │   ├── security/        # SecureStorageService, TokenVault
│       │   └── theme/           # AccessibleTheme (WCAG AAA, 20px+ text, 56px touch)
│       ├── localization/        # AppLocalizations, RTL detection, language bundles
│       └── features/
│           ├── authentication/  # AuthState, AuthRepositoryImpl, AuthController, LoginScreen
│           ├── elderly_home/    # ElderlyHomeController, ElderlyActionTile
│           ├── games/           # GameEngineContracts, GameRepositoryImpl, GamesController
│           ├── adaptive_difficulty/ # AdaptiveDifficultyController, DifficultyBadge
│           ├── medication/      # MedicationRepositoryImpl, MedicationController
│           ├── caregiver/       # CaregiverRepositoryImpl, CaregiverController
│           ├── voice/           # BhashiniVoiceProvider, VoiceServiceImpl, VoiceController
│           ├── settings/        # SettingsController, SettingsScreen
│           └── offline_sync/    # SyncRepositoryImpl, SyncEngine, SyncController
│
└── backend/                     # NestJS Cloud Synchronization Service
    ├── .env.example
    ├── package.json
    ├── tsconfig.json
    └── src/
        ├── main.ts              # API bootstrap with Helmet, CORS, and Throttling
        ├── app.module.ts
        └── modules/
            └── sync/            # SyncController (POST /api/v1/sync/batch) & SyncService
```

---

## 4. State Management Approach

The application standardizes on **`ChangeNotifier`** and **`Provider`** across every feature:
- Unidirectional data flow: UI calls controller methods $\to$ controller invokes domain repositories/services $\to$ updates internal state $\to$ invokes `notifyListeners()`.
- Controllers are registered at the root via `MultiProvider` in [main.dart](file:///d:/SIH%20hackathon/mobile/lib/main.dart).
- Screens and widgets subscribe reactively using `context.watch<T>()` or `Consumer<T>()` and dispatch actions using `context.read<T>()`.
- Zero mixture of incompatible state systems (no ad-hoc event buses or uncontrolled global variables).

---

## 5. Environment Profiles

Defined in [app_config.dart](file:///d:/SIH%20hackathon/mobile/lib/core/config/app_config.dart):

| Property | Development (`development`) | Staging (`staging`) | Production (`production`) |
|---|---|---|---|
| **API Base URL** | `http://10.0.2.2:3000/api/v1` | `https://staging-api.smritisetu.gov.in/api/v1` | `https://api.smritisetu.gov.in/api/v1` |
| **Timeout** | 15 seconds | 20 seconds | 10 seconds |
| **Sync Interval** | 30 seconds | 60 seconds | 60 seconds |
| **Sync Batch Size** | 10 items | 25 items | 25 items |
| **Logging** | Enabled | Enabled | Disabled |
| **Mock Voice** | Enabled | Disabled | Disabled |

---

## 6. Offline Synchronization & Idempotency

- Every patient action writes to local SQLite first.
- Items are enqueued in `sync_queue` with client-generated UUIDv4 idempotency tokens.
- `SyncEngine` polls pending items and submits batches to `POST /api/v1/sync/batch`.
- Backend checks the idempotency token before performing transactions, guaranteeing that retried network requests never produce duplicate records or duplicate game sessions.

---

## 7. Quality Assurance & Verification Status

```
================================================================================
Mobile Dependencies:    flutter pub get -> Resolved (89 packages)
Static Code Analysis:   flutter analyze -> No issues found! (ran in 13.0s)
Unit & Widget Tests:    flutter test    -> 00:01 +11: All tests passed!
Backend Typecheck:      npx tsc --noEmit -> Exit code 0 (No type errors)
================================================================================
```
