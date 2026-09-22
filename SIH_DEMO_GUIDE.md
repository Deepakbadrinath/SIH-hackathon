# SmritiSetu — Smart India Hackathon (SIH) Live Demonstration Guide

> **Document Version:** 1.0.0  
> **Target Audience:** SIH Evaluation Panel, Jury Members, and Presenters  
> **System Status:** 100% Repeatable • Offline-Safe • Zero External API Vulnerabilities  
> **Synthetic Data Disclaimer:** All patient records, caregiver links, medication logs, and gameplay sessions used in this demonstration are **clearly labeled synthetic test records**. SmritiSetu is a cognitive engagement, accessibility, and routine support tool; it **does NOT make medical diagnoses or clinical claims**.

---

## 1. Executive Summary & Demo Architecture

During live judging at Smart India Hackathon, network instability, auditorium Wi-Fi deadzones, or third-party cloud API rate limits (e.g., Bhashini API or cloud TTS servers) often disrupt presentations. 

SmritiSetu has been engineered with a **Resilient Demo Architecture**:
1. **Local-First SQLite Engine**: Every cognitive game trial, score, adaptive difficulty transition, medication reminder, and caregiver view runs from an embedded, encrypted-ready local SQLite database.
2. **Deterministic Baseline Seeder (`DemoDataManager`)**: A pre-configured 14-day baseline featuring synthetic patient **Deka Da (দাদা)** and caregiver **Dr. Ananya Sharma** is seeded automatically on initial launch.
3. **1-Click Instant Repeatability**: Tapping **"Reset Demo Baseline"** in the floating SIH Demo Bar purges and restores the entire system to a clean state in under 300ms—enabling seamless, repeatable demonstrations for consecutive evaluation panels.
4. **Multi-Tier Voice Architecture**: Bhashini Cloud AI is configured as the primary regional voice provider, with instantaneous, zero-delay fallback to native on-device Platform TTS if the network is disconnected or throttled.
5. **Interactive SIH Demo Bar (`SihDemoBar`)**: An unobtrusive floating badge pinned to the bottom of the screen allows presenters to simulate network failure, observe live sync queue counts, trigger sync, and jump between key screens without leaving the app.

---

## 2. Complete 20-Step Demonstration Flow

| Step | Action | Presenter Talking Point | Screen / Route | Expected Verification for Judges |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Launch Application** | "SmritiSetu initializes with zero external cloud dependencies, immediately loading the local accessibility profile and database." | Splash Screen (`/`) | App launches instantly; high-contrast toggle and language selector visible. |
| **2** | **Select Language** | "The application supports 14 Indian languages, localized for North-Eastern regional accessibility (Assamese, Manipuri, Bengali, etc.)." | Language Selection (`/language`) | Tap **Assamese (অসমীয়া)** or **English**. UI labels dynamically adapt; font scale and text flow adjust without layout distortion. |
| **3** | **Elderly User Enters Home** | "The elderly patient home screen features large, high-contrast touch targets (>56dp), clear iconography, and zero distracting visual clutter." | Elderly Home (`/elderly_home`) | Large cards appear for 'Cognitive Games', 'Daily Medications', and 'Past Activity'. Disclaimer banner displays non-diagnostic advisory. |
| **4** | **Voice Explains Available Games** | "Elderly users with mild cognitive impairment or visual decline can listen to auditory prompts rather than reading dense text." | Elderly Home (`/elderly_home`) | Tap the speaker icon on the top banner or on game cards. The voice explains available games in the selected regional language. |
| **5** | **User Selects Family Face Match** | "Family Face Match uses familiar family portraits to exercise facial recognition, associative memory, and emotional connection." | Games Screen (`/games`) → Face Match (`/face_match`) | Tap **Family Face Match**. The introductory screen displays clear, compassionate instructions with an audio readout button. |
| **6** | **Complete Game** | "The game is relaxing with no countdown timers, minimizing cognitive anxiety. Response times and accuracy are recorded locally." | Face Match (`/face_match`) | Tap **Start Game**. Match the prompt photo with the correct family member card (e.g., Son - Rahul, Granddaughter - Priya). Complete all 3 trials. |
| **7** | **Show Score** | "Immediate positive reinforcement is provided to encourage daily routine compliance." | Face Match Results | The results screen displays **"Great Job!"** with a score of 100% and star celebration badge. |
| **8** | **Show Performance Metrics** | "Detailed session telemetry is captured: average latency (e.g., 2.1s), trial accuracy (100%), and steady engagement rate." | Face Match Results | Metrics breakdown card displays **Score: 100%**, **Average Response Time: 2.1 sec**, **Accuracy: 3/3 Correct**. |
| **9** | **Adaptive Difficulty Changes** | "Our non-clinical adaptive algorithm analyzes performance across consecutive sessions. High accuracy and steady latency trigger a recommended progression." | Face Match Results | A dynamic **Adaptive Difficulty Progression Pill** appears: `Level 1 → Level 2` with badge: `High accuracy (100%) and steady response latency triggered difficulty increase.` |
| **10** | **Turn Off Network** | "We will now simulate an auditorium network blackout or remote rural village scenario where connectivity is completely absent." | Any Screen (SIH Demo Bar) | Tap the floating **SIH DEMO** badge at the bottom right to expand the panel. Tap **Turn Off Network**. The bar turns red: **OFFLINE SIMULATION**. |
| **11** | **Complete Another Game (Offline)** | "The patient can continue their daily cognitive therapy without interruption even while completely disconnected." | Face Match or Pattern Completion | Play another round or tap **Face Match** again. The game plays smoothly with instant local feedback. |
| **12** | **Show Data Is Saved Offline** | "Rather than failing or dropping data, the session is committed to local SQLite and queued in an idempotent, persistent Sync Queue." | SIH Demo Bar Overlay | The SIH floating badge immediately updates to reflect: **OFFLINE (Queue: 1 Pending)**. |
| **13** | **Reconnect Network** | "When the device re-enters cellular coverage or Wi-Fi range, the network monitor automatically detects connectivity restoration." | SIH Demo Bar Overlay | In the expanded SIH Demo Bar, tap **Reconnect Network**. The bar status transitions to green: **ONLINE MODE**. |
| **14** | **Synchronize** | "The background sync engine pushes pending records to the caregiver cloud server using unique operation IDs to prevent duplicate entries." | SIH Demo Bar Overlay | Tap **Sync (1 Pending)**. The queue count flushes to `Sync (0 Pending)`, and a green confirmation banner confirms successful synchronization. |
| **15** | **Login as Caregiver** | "Authorized family caregivers or clinical aides can monitor their loved one's engagement trends remotely." | Caregiver Dashboard (`/caregiver`) | Tap the **4. Caregiver** quick shortcut on the demo bar or navigate via menu. Login loads **Dr. Ananya Sharma** caring for **Deka Da (দাদা)**. |
| **16** | **Show Patient Activity** | "Caregivers immediately see recent session timestamps, games played today, and engagement consistency without intrusive surveillance." | Caregiver Dashboard (`/caregiver`) | The **Recent Cognitive Activity** list shows today's completed Face Match and Pattern Completion sessions alongside historical entries. |
| **17** | **Show Performance Graph** | "Visual longitudinal trends illustrate accuracy, response latency, and difficulty progression over 7-day, 14-day, and 30-day windows." | Caregiver Dashboard (`/caregiver`) | Scroll to **Performance Trend**: view the **Accuracy Trend Chart** (steady ~86%), **Response Time Chart** (2.1s avg), and **Difficulty Progression Chart** (Level 1 → Level 2). |
| **18** | **Show Medication Adherence** | "Cognitive health is deeply tied to routine medication. SmritiSetu logs scheduled dosages (e.g., Donepezil & Memantine) with voice reminders." | Caregiver Dashboard (`/caregiver`) & Medication (`/medication`) | View the **Medication Adherence** card: **94.2% Adherence Rate** (13 of 14 doses taken on time). Tap **5. Medication** to view active pill reminders. |
| **19** | **Change Language** | "Language preference can be changed at any time by either patient or caregiver without losing session state or requiring an app restart." | Settings (`/settings`) or Language (`/language`) | Tap **Change Language**, select **Bengali (বাংলা)** or **Hindi (हिन्दी)**. The entire interface transitions seamlessly. |
| **20** | **Demonstrate Regional Voice** | "We demonstrate our multi-lingual speech engine with regional phrases and clearly illustrate our automatic offline TTS fallback." | Voice Settings (`/voice_settings`) | Tap **6. Voice Settings**. In the **Live Regional Voice Demo** card, tap the sample phrase buttons for **Assamese**, **Bengali**, **Manipuri**, **Hindi**, and **English**. |

---

## 3. Presenter Controls: The Floating SIH Demo Bar

The application includes an overlay control bar (`SihDemoBar`) accessible throughout the app:

### Collapsed State
- Positioned in the bottom-right corner.
- Shows current network status: `SIH DEMO` (Blue = Online) or `OFFLINE (Queue: X)` (Red = Offline).
- Tap to expand.

### Expanded State
1. **Network Simulation Toggle (`Turn Off Network` / `Reconnect Network`)**:
   - Toggles `NetworkInfo.setMockConnectionStatus(false/true)`.
   - Simulates physical network disruption safely without disconnecting your presentation screencast or laptop hotspot.
2. **Idempotent Sync Trigger (`Sync (X Pending)`)**:
   - Triggers `SyncManager.processSyncQueue()`.
   - Uploads pending records with exponential retry and deduplication guards.
   - Shows live snackbar confirmation upon successful upload.
3. **Reset Demo Baseline (`Reset Demo Baseline`)**:
   - Calls `DemoDataManager.seedDemoData(resetExisting: true)`.
   - Restores 2 synthetic patients, 1 caregiver, 2 medications, 14 days of adherence logs, and 6 baseline game sessions in <300ms.
   - Resets offline simulation back to normal.
4. **Quick Navigation Chips (`1. Splash`, `2. Elderly Home`, `3. Face Match`, `4. Caregiver`, `5. Medication`, `6. Voice Settings`)**:
   - Jump directly to any phase of the demonstration without manual menu traversal.

---

## 4. Voice Fallback Architecture: Cloud AI vs. On-Device TTS

SmritiSetu utilizes a dual-tier voice engine configured for maximum reliability:

```
                  ┌─────────────────────────────────────────┐
                  │          Text to Speak (TTS)            │
                  └────────────────────┬────────────────────┘
                                       │
                        Is Network Connected &
                        Bhashini Provider OK?
                                      / \
                                Yes  /   \  No (Offline or API Error)
                                    /     \
                                   ▼       ▼
                        ┌──────────────┐ ┌───────────────────────────┐
                        │ Bhashini AI  │ │ Native Platform TTS       │
                        │ Cloud Engine │ │ (On-Device Offline Engine)│
                        └──────────────┘ └───────────────────────────┘
```

### Explaining the Fallback to Judges:
- **Primary Tier**: When online, synthesis leverages **Bhashini AI Cloud TTS** to provide natural-sounding regional Indian accents and intonations.
- **Fallback Tier**: If internet is lost, network latency exceeds 3 seconds, or the remote API returns an error, the system automatically falls back to the native operating system TTS engine (Android TTS / iOS AVSpeechSynthesizer / Windows SAPI).
- **Zero Interruption**: The elderly patient is never presented with an error dialog or silence; voice instructions continue to speak seamlessly.

---

## 5. Synthetic Demo Dataset Reference

| Entity | Synthetic Identifier | Display Name / Description | Details |
| :--- | :--- | :--- | :--- |
| **Patient 1** | `patient_1` | **Deka Da (দাদা)** | Age: 78 • Dialect: Assamese (`as_IN`) • Emergency Contact: `+91 98765 43210` |
| **Patient 2** | `patient_2` | **Baruah Baideo (বাইদেউ)** | Age: 74 • Dialect: Assamese (`as_IN`) • Linked to same Caregiver |
| **Caregiver** | `caregiver_demo_1` | **Dr. Ananya Sharma** | Relationship: Primary Family Physician / Authorized Caregiver |
| **Medication 1** | `med_demo_1` | **Donepezil 5mg** | Schedule: Once daily at 08:00 AM • Routine reminder |
| **Medication 2** | `med_demo_2` | **Memantine 10mg** | Schedule: Once daily at 08:00 PM (Evening dose) |
| **Adherence History** | 28 logged entries | 14-day chronological logs | 100% adherence over last 7 days; 94.2% overall adherence rate |
| **Cognitive History** | 6 baseline sessions | 4 game types | Face Match, Pattern Completion, Activity Sequence, Object Sorting |

---

## 6. Ethical Guardrails & Medical Disclaimer

In compliance with healthcare technology ethics and AI safety standards:
- **No Clinical Diagnostics**: SmritiSetu is explicitly designed as an assistive engagement and routine adherence support system. It **does NOT diagnose** Alzheimer's disease, dementia, or any neurological condition.
- **Explainable Metrics Only**: All performance metrics presented to caregivers reflect observable behavioral telemetry (accuracy percentages, response latency in seconds, and completion counts). We do **NOT** display arbitrary "AI Brain Health Scores" or synthetic diagnostic labels.
- **Caregiver Collaboration**: Trends are presented as talking points for families and consulting physicians, not clinical verdicts.

---

## 7. Judge Verification & Automated Testing Commands

Judges or technical evaluators wishing to audit code quality, test coverage, and database integrity can execute the following commands in the workspace:

### 1. Static Analysis Verification (Zero Errors)
```powershell
cd mobile
& "D:\flutter\bin\flutter.bat" analyze lib/
```
*Expected Result:* `No issues found!`

### 2. Run Complete Automated Test Suite (366 Tests)
```powershell
cd mobile
& "D:\flutter\bin\flutter.bat" test
```
*Expected Result:* `All 366 tests passed!`

### 3. Run Dedicated SIH Demo Suite
```powershell
cd mobile
& "D:\flutter\bin\flutter.bat" test test/sih_demo_mode_test.dart
```
*Expected Result:* `All 5 tests passed!` (Verifies synthetic seeding, 1-click purge/reset, offline toggles, and widget interaction).

### 4. Run Backend Test Suite
```bash
cd backend
npm test
```
*Expected Result:* `33 passing`
