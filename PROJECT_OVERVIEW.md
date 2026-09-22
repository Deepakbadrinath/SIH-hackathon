# SmritiSetu (স্মৃতি সেতু) — Project Overview
### AI-Assisted Cognitive Support & Caregiver Collaboration System for Elderly Dementia Patients in North-Eastern India

> **SIH Problem Statement / Theme:** Healthcare & Biomedical Technology / Assistive Cognitive Support  
> **Status:** Production-Grade Working Prototype • 100% Offline-Safe • Zero-Trust Security  
> **Target Region:** North-Eastern Region (NER) of India & Multilingual Pan-India  

---

## 1. Problem Statement & Motivation

### The Challenge
Dementia and mild cognitive decline (MCI) among the elderly population are escalating public health challenges across India, with an estimated 8.8 million Indians aged 60+ living with dementia. In the **North-Eastern Region (NER)**—encompassing Assam, Manipur, Meghalaya, Mizoram, Nagaland, Tripura, Arunachal Pradesh, and Sikkim—the burden is compounded by distinct systemic barriers:
1. **Linguistic Marginalization**: Standard commercial healthcare and cognitive apps exist exclusively in English or Hindi, completely excluding elderly native speakers of Assamese (*অসমীয়া*), Manipuri (*মৈতৈলোন্*), Bodo, and regional dialects.
2. **Infrastructure Deficits & Intermittent Connectivity**: Rural and hilly terrains suffer frequent power outages and mobile network dropouts, rendering cloud-dependent applications unusable.
3. **Geriatric Digital Divide & Cognitive Anxiety**: Mainstream games are fast-paced, feature countdown timers, cluttered animations, and complex menus that provoke cognitive fatigue and frustration in dementia patients.
4. **Caregiver Burnout & Disconnect**: Family caregivers lack objective, non-intrusive longitudinal visibility into their loved ones' daily routine compliance, cognitive engagement consistency, and medication adherence.

---

## 2. Our Solution: SmritiSetu

**SmritiSetu ("Bridge of Memory")** is a dual-interface, local-first assistive healthcare ecosystem designed specifically for elderly dementia patients and their family caregivers.

### Core Innovations
- **Elderly-First Accessible Cognitive Therapy**: 4 targeted non-punitive cognitive games designed to stimulate distinct neuro-cognitive domains (associative memory, logical pattern matching, procedural sequencing, and categorical sorting) with timerless, gentle pacing.
- **Explainable Non-Clinical Adaptive Difficulty**: An on-device heuristic progression algorithm that dynamically adjusts game complexity based on trial accuracy, response latency, and hesitation pauses.
- **Zero-Drop Offline-First Architecture**: Powered by an embedded SQLite database and Write-Ahead Logging (WAL). All gameplay, scoring, difficulty changes, and medication confirmations execute locally without internet.
- **Idempotent Background Synchronization (`SyncManager`)**: Queues offline operations with unique UUIDv4 transaction tokens, automatic network state detection, and exponential backoff retry policies.
- **Inclusive Multilingual & Dual-Tier Voice Engine**: Native support for 14 Indian languages with primary Bhashini Cloud AI speech synthesis and instantaneous fallback to on-device platform TTS when offline.
- **Caregiver Collaboration Dashboard**: Secure, zero-trust authorized portal providing family physicians and caregivers with 7/14/30-day longitudinal engagement charts, medication adherence tracking, and fatigue trend alerts.

---

## 3. Product Status & Feature Classification

In strict adherence to medical software engineering ethics, we clearly delineate feature maturity:

| Feature Dimension | Status | Detailed Implementation Reality |
| :--- | :---: | :--- |
| **Elderly Accessible UI (WCAG AAA)** | **IMPLEMENTED** | Large touch targets (>56dp), high-contrast modes, dynamic font scaling (up to 1.3x), zero timer anxiety. |
| **Four Cognitive Games** | **IMPLEMENTED** | Family Face Match, Pattern Completion, Activity Sequence, and Object Sorting fully playable. |
| **Adaptive Difficulty Engine** | **IMPLEMENTED** | Deterministic mathematical heuristic evaluating accuracy, latency, and hesitation pause; saves progression history to SQLite. |
| **Offline SQLite Storage & WAL** | **IMPLEMENTED** | 14 relational tables, indexed foreign keys, crash recovery, persistent sync queue. |
| **Idempotent Sync Engine** | **IMPLEMENTED** | UUID operation tokens, deduplication guards (`CONFLICT_IGNORED`), exponential backoff retry. |
| **Zero-Trust Caregiver Auth & IDOR Guard** | **IMPLEMENTED** | JWT token authentication, role separation (Patient vs. Caregiver), relational ownership authorization check. |
| **Multilingual Translations** | **IMPLEMENTED** | Full translation catalogs for 14 Indian languages + RTL layout support (Urdu, Arabic). |
| **Dual-Tier Regional Voice** | **IMPLEMENTED** | Bhashini Cloud AI primary provider + on-device platform TTS automatic fallback. |
| **Explainable ML Trend Pipeline** | **PROTOTYPE** | Supervised logistic regression session completion predictor and linear regression trajectory slope (trained on synthetic dataset). |
| **Personalized Face Ingestion API** | **PROTOTYPE** | Family members can upload local photos for the Face Match game (uses synthetic portraits in demo). |
| **Clinical Diagnostic Validation** | **FUTURE WORK** | Formal IRB-approved longitudinal retention trials with institutions like AIIMS Guwahati / NIMHANS. |
| **Passive Biosensor Correlation** | **FUTURE WORK** | BLE wearable sensor integration for sleep hygiene and heart rate variability (HRV) sync. |

---

## 4. Key Engineering Differentiators

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           WHAT SMRITISETU IS NOT                            │
├─────────────────────────────────────────────────────────────────────────────┤
│ ✗ It is NOT a medical diagnostic tool or clinical decision support system. │
│ ✗ It does NOT make unscientific claims of "curing" or "reversing" dementia. │
│ ✗ It does NOT rely on fragile external APIs that break during auditorium demo│
│ ✗ It does NOT expose sensitive patient health information to public cloud LLMs│
└─────────────────────────────────────────────────────────────────────────────┘
                                      vs.
┌─────────────────────────────────────────────────────────────────────────────┐
│                            WHAT SMRITISETU IS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ ✓ An assistive accessibility companion reinforcing daily routine dignity.  │
│ ✓ An objective behavioral telemetry collector for family caregivers.        │
│ ✓ An offline-resilient tool functioning in remote North-Eastern villages.   │
│ ✓ A culturally anchored platform speaking Assamese, Manipuri, & Indian langs│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Technology Stack Summary

- **Mobile Client**: Flutter 3.x (Dart 3), Provider state management, Sqflite FFI, Flutter Secure Storage (Keystore/Keychain).
- **Backend API**: Node.js, Express / NestJS architecture, TypeScript, JWT (RS256/HS256), SQLite/PostgreSQL relational schema.
- **Voice & Speech**: Bhashini Government API (Cloud AI), Android Speech API, iOS AVSpeechSynthesizer, Windows SAPI.
- **Verification**: 403 Automated Tests (370 Flutter unit/widget/integration + 33 Backend REST API tests), 100% pass rate.
