# SIH Grand Finale: Live Demonstration Script

> **Project Name:** CogniCare / Smriti Setu (Dementia Care & Cognitive Rehabilitation System)  
> **Target Audience:** SIH Grand Finale Evaluation Panel & Domain Experts  
> **Live Demo Controls:** Utilizing the built-in floating `SihDemoBar` for deterministic presentation.

---

## 1. Demo Formats Overview

This script is structured in two synchronized tracks:
- **Track A (5-Minute Compressed Pitch):** High-speed presentation focusing strictly on the unique technological differentiators (Offline-First, Regional Voice, Deterministic Adaptive Difficulty, and Caregiver Analytics).
- **Track B (8-Minute Extended Pitch):** Comprehensive walk-through including security architecture, edge-case network dropouts, and clinical research roadmap.

---

## 2. Pre-Demo Setup Checklist (Presenter Preparation)

Before the jury sits down:
1. **Launch Flutter Web or Emulator:** Ensure the application is open at the starting state.
2. **Reset Demo Data:** Click `Reset Data` on the floating `SihDemoBar` at the bottom of the screen. This seeds known synthetic baseline metrics (Patient: "Dharanidhar Barman", Stage: Moderate, 7-day adherence: 85%).
3. **Verify Audio Output:** Ensure device speaker volume is at 80% so the regional voice guidance (Bhashini AI / OS TTS) is audible to the evaluators.
4. **Network Toggle Ready:** Verify that the `Turn Off Network` button in `SihDemoBar` is visible.

---

## 3. Minute-by-Minute Live Demo Script (Track A: 5-Minute Standard)

### [00:00 - 00:45] Minute 1: Problem Context & Regional Accessibility

#### Presenter Action:
- Start on the **Language Selection / Welcome Screen**.
- Select **Assamese (অসমীয়া)** or **Hindi (हिन्दी)**.
- Tap the Speaker Icon / Trigger Voice Prompts.

#### Speaker Dialogue:
> *"Respected judges, in India, over 8.8 million seniors live with dementia, particularly in rural and tier-2/3 regions like the North-East where internet connectivity is erratic and English interfaces fail completely.*  
> *Notice our interface: Designed strictly according to WCAG AAA standards for seniors—zero visual clutter, high contrast, 56-pixel touch targets, and natural voice guidance in 14 regional languages including Assamese and Manipuri.*  
> *Our speech layer utilizes Digital India’s Bhashini ULCA API with a zero-latency native OS TTS fallback for when the internet drops. The elder never sees a loading spinner or an error code."*

#### Screen Cue:
- Screen reads out greeting in the selected regional language.
- Navigation transitions smoothly (<100ms) to the **Elder Home Dashboard**.

---

### [00:45 - 01:45] Minute 2: Dementia-Specific Cognitive Game & Telemetry

#### Presenter Action:
- On Elder Home, point out the 4 clinically anchored cognitive games.
- Tap **Family Face Match** (Personalized Memory & Facial Recognition).
- Complete Trial 1: Tap the correct relationship card (*"Daughter / Ananya"*).
- Complete Trial 2 & 3 with prompt, intentional taps.

#### Speaker Dialogue:
> *"Notice these are not generic puzzle games. Every game targets a specific neuro-cognitive domain. Family Face Match uses familiar family portraits to stimulate episodic memory retrieval.*  
> *Notice also what is NOT here: There are NO countdown timers and NO harsh buzzer noises. Dementia patients experience catastrophic agitation when rushed or penalized.*  
> *Instead, behind every interaction, our engine captures micro-telemetry: Trial accuracy, millisecond response latency, hesitation pauses, and error repetitions. In this session, the patient scored 100% with under 2.2-second latency."*

#### Screen Cue:
- Game Completes. **Result Dialog** displays warm congratulatory feedback.
- Telemetry badge shows: *Accuracy: 100% | Latency: 2180ms | Difficulty Adjusted: Level 1 $\to$ Level 2*.

---

### [01:45 - 02:45] Minute 3: Real-Time Adaptive Difficulty Engine

#### Presenter Action:
- Tap **Play Again** or proceed to **Pattern Recall** / **Daily Routine Sequence**.
- Demonstrate that the challenge difficulty has seamlessly scaled up (e.g., 3-item sequence $\to$ 4-item sequence).

#### Speaker Dialogue:
> *"How does the system adapt? We reject black-box AI that guesses randomly. We implemented a deterministic, explainable heuristic scoring function.*  
> *It weights accuracy at 50%, latency at 30%, hesitation pauses at 10%, and error penalties at 10%.*  
> *Because performance exceeded our promotion threshold of 0.80 across trials, the engine promoted the user from Level 1 to Level 2.*  
> *If the elder shows signs of confusion or fatigue and drops below 0.60, the engine automatically steps down to prevent frustration and preserve self-efficacy."*

#### Screen Cue:
- Show the visual game grid displaying the new Level 2 layout.

---

### [02:45 - 03:45] Minute 4: The Core Differentiator — Offline Resilience & Sync

#### Presenter Action:
- **PHYSICAL ACTION:** Tap `Turn Off Network` on the floating `SihDemoBar`. (A red banner indicates `Offline Mode Active`).
- Launch and play another quick session or record a medication checkmark.
- Point out the floating `SihDemoBar` badge: `Queue: 1 pending`.
- **PHYSICAL ACTION:** Tap `Reconnect Network` on `SihDemoBar`.
- Watch the pending count transition from `1` to `0` automatically.

#### Speaker Dialogue:
> *"Now, let's test the reality of rural healthcare: The internet drops completely. I have just disconnected the network.*  
> *The patient continues playing. Every single trial, score, and timestamp is written directly to an on-device SQLite database with Write-Ahead Logging.*  
> *Notice our floating queue counter: 1 pending synchronization packet. The app never freezes; no data is lost.*  
> *Now, connectivity restores. I click 'Reconnect'.*  
> *Our background sync worker immediately wakes up, batches the record with an immutable UUIDv4 idempotency token, and pushes it to our Node.js backend. Even if network flutters mid-flight, our backend de-duplicates transactions with zero duplicate insertions."*

#### Screen Cue:
- Banner turns green: `Online`. Sync queue clears to `0`. Toast: *"Data synchronized securely"*.

---

### [03:45 - 05:00] Minute 5: Caregiver Analytics, Security, & Summary

#### Presenter Action:
- Tap `4. Caregiver Dashboard` on the `SihDemoBar` quick-navigation chips.
- Display Patient: *Dharanidhar Barman*.
- Show the **Cognitive Performance Trend Graph** and **Medication Adherence Ring** (85%).
- Scroll to the bottom showing the **Clinical Disclaimer Banner**.

#### Speaker Dialogue:
> *"Finally, here is the Caregiver and Clinician Portal. Caregivers can view longitudinal trends over 7, 30, and 90 days, monitoring for subtle cognitive slopes rather than day-to-day noise.*  
> *Data security is paramount: All endpoints implement zero-trust authorization with an `OwnershipGuard` verifying explicit caregiver-patient linkage. Even if a caregiver tampers with the patient ID in an API request, access is immediately blocked with HTTP 403.*  
> *To summarize:*
> 1. *Implemented today:* 100% offline-first architecture, 14 regional languages with dual-tier voice, 4 WCAG AAA cognitive games, deterministic heuristic progression, and encrypted caregiver sync.
> 2. *Our scientific stance:* This is a non-clinical cognitive exercise tool designed to support families and clinicians, fully prepared for future longitudinal hospital pilots.*  
> *Thank you, judges! We welcome your technical questions."*

---

## 4. Track B: 8-Minute Extended Presentation Matrix

For rounds where judges allocate 8 to 10 minutes:

| Minute | Phase | On-Screen Action | Key Talking Points |
|---|---|---|---|
| **00:00 - 01:15** | **Architecture & Tech Stack** | Show Architecture Diagram / Splash screen | Explain Flutter native compilation (ARM/x86, 60fps), SQLite WAL mode, TypeScript REST backend, and why WebViews were eliminated. |
| **01:15 - 02:30** | **Elderly Accessibility & Voice** | Switch languages to Assamese $\to$ Hindi $\to$ English | Explain dual-tier voice: Cloud Bhashini ULCA API vs local device TTS fallback. Point out dynamic text scaling and high contrast. |
| **02:30 - 04:00** | **Cognitive Gameplay & Scoring** | Play Family Face Match and Pattern Recall | Detail the 4 neuro-cognitive domains: Facial recognition, inductive reasoning, sequence memory, semantic sorting. Demonstrate telemetry extraction. |
| **04:00 - 05:30** | **Live Network Stress Test** | Disconnect network via `SihDemoBar` $\to$ play game $\to$ inspect SQLite queue $\to$ reconnect | Explain SQLite schema (14 tables), sync state machines, exponential backoff (1s, 2s, 4s, 8s, 16s), and UUIDv4 server deduplication. |
| **05:30 - 07:00** | **Caregiver Portal & Security** | Open Caregiver Dashboard $\to$ view longitudinal chart | Detail DPDP Act compliance, bcrypt password hashing, 15-min JWT access tokens, hardware Keystore storage, and IDOR prevention. |
| **07:00 - 08:00** | **Future Clinical Roadmap & Q&A** | Show Clinical Disclaimer & Audit Summary | Emphasize ethical AI boundaries, prototype vs production distinctions, and NIMHANS / AIIMS pilot proposals. Open for jury queries. |

---

## 5. Contingency Plan & Demo Backup Strategies

| Potential Glitch During Demo | Root Cause | Immediate Backup Action |
|---|---|---|
| **Audio fails to play or projector has no speakers** | Host OS audio muted or HDMI audio unlinked | Point to the on-screen real-time localized subtitle text. Explain that voice guidance is designed as a multimodal complement. |
| **Bhashini API latency >2 seconds** | Cloud API throttling / slow conference Wi-Fi | The app automatically triggers the fallback to host OS native platform TTS in <50ms without failing the screen flow. |
| **Accidental navigation or wrong button tap** | Presenter nervous misclick | Tap the quick-jump chips on the floating `SihDemoBar` (e.g. `1. Splash`, `2. Elder Home`, `4. Caregiver Dashboard`) to jump back instantly. |
| **Sync queue does not immediately decrement** | Local mock network state delay | Tap `Sync Now` on the `SihDemoBar` or trigger manual pull-to-refresh on Caregiver Dashboard. |
