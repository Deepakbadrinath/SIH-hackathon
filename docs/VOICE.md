# SmritiSetu Regional Voice Service (Phase 11)

**SIH26003: AI-Based Cognitive Gaming & Assistive System for Elderly Dementia Patients**

---

## 1. Architectural Overview

SmritiSetu implements a fully decoupled, multi-tier voice architecture designed specifically for elderly accessibility, low-cognitive-load interactions, and regional language inclusion across India (with special emphasis on North Eastern languages).

```
┌────────────────────────────────────────────────────────────────────────┐
│                               UI Layer                                 │
│  (Screens, VoiceInstructionButton, VoiceConfirmationWidget, Dialogs)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                            VoiceController                             │
│       (ChangeNotifier: state management, repeat caching, UI bindings)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              VoiceService                              │
│   (Orchestrator: 5 Voice Features, PHI sanitization, keyword parsing)   │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
                    ▼                                ▼
┌──────────────────────────────────────┐ ┌───────────────────────────────┐
│         TextToSpeechService          │ │      SpeechToTextService      │
│  (TTS contract, routing & fallback)  │ │ (STT contract, permissions)   │
└───────────────────┬──────────────────┘ └───────────────┬───────────────┘
                    │                                    │
                    └─────────────────┬──────────────────┘
                                      ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         IVoiceProvider Layer                           │
│  ┌──────────────────────────────┐    ┌──────────────────────────────┐  │
│  │    BhashiniVoiceProvider     │    │  NativePlatformVoiceProvider │  │
│  │   (Cloud AI - 14 Languages)  │    │ (On-Device Platform Offline) │  │
│  └──────────────────────────────┘    └──────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

### Strict Decoupling Principle
- **No Direct Cloud Calls in Widgets**: UI widgets interact solely with `VoiceController` or `VoiceService`. Under no circumstances are Bhashini REST endpoints, API keys, HTTP payload structures, or audio encoding details placed inside UI widgets.
- **Provider Abstraction**: All synthesis (TTS) and recognition (STT) tasks route through the `IVoiceProvider` interface, allowing swap-in of Bhashini, Azure Speech, Google Cloud Speech, or offline on-device engines without modifying business logic.

---

## 2. Supported Regional Languages (14 Languages)

SmritiSetu architects full voice support for at least 14 Indian languages, covering the North East (Assamese, Manipuri, Bengali) and major national regions:

| Language | Code | Script | Bhashini Cloud TTS/ASR | Platform Offline TTS | Platform Offline STT |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **English** | `en` | Latin | ✅ Supported | ✅ Supported | ✅ Supported (Default OS) |
| **Hindi** | `hi` | Devanagari | ✅ Supported | ✅ Supported | ⚠️ Requires OS Pack |
| **Assamese** | `as` | Bengali-Assamese | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Manipuri** | `mni` | Meitei Mayek / Bengali | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Bengali** | `bn` | Bengali | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Odia** | `or` | Odia | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Telugu** | `te` | Telugu | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Tamil** | `ta` | Tamil | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Kannada** | `kn` | Kannada | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Malayalam** | `ml` | Malayalam | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Marathi** | `mr` | Devanagari | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Gujarati** | `gu` | Gujarati | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Punjabi** | `pa` | Gurmukhi | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |
| **Urdu** | `ur` | Perso-Arabic (RTL) | ✅ Supported | ❌ Cloud-only | ❌ Cloud-only |

---

## 3. The 5 Core Voice Features

### Feature 1: Read Instructions Aloud
- Invoked automatically or via `VoiceInstructionButton`.
- Reads screen directions, cognitive game rules, and navigation cues in the elder's configured regional language.
- Automatically stores the spoken instruction in memory for instant replay.

### Feature 2: Read Reminders Aloud
- Invoked when a medication schedule or cognitive activity reminder triggers.
- Protected by `PatientDataSanitizer` to ensure clinical diagnostic notes are stripped before speech synthesis.
- Clear audible formulation: *"Reminder: Afternoon Medicine. 1 tablet after food with water. Scheduled for 2:00 PM."*

### Feature 3: Voice Input Where Supported
- Allows the user to answer questions or navigate via speech recognition.
- Enforces strict microphone permission checks and timeout guards (default 10s).
- Streams audio in memory without storing recording files.

### Feature 4: Voice Confirmation
- Allows elderly patients to confirm actions hands-free (e.g. saying *"I took it"* or *"Snooze"* for medication alerts).
- Employs multi-lingual keyword dictionaries across all 14 languages:
  - **English**: "yes", "taken", "took it", "done", "confirm" / "no", "snooze", "later"
  - **Hindi**: "हाँ", "ले ली", "खा ली", "लिया" / "नहीं", "बाद में", "अलार्म"
  - **Assamese**: "হৈ", "খালোঁ", "ললোঁ", "ঠিক আছে" / "নহয়", "পিছত", "পাছত"
  - **Manipuri**: "হৈ", "য়ারে", "চাবা লোইরে" / "নত্তে", "তুংদা", "য়াদে"
  - **Bengali**: "হ্যাঁ", "খেয়েছি", "নিয়েছি" / "না", "পরে", "স্নুজ"
  - Equivalent dictionaries for Telugu, Tamil, Kannada, Malayalam, Marathi, Gujarati, Odia, Punjabi, and Urdu.
- Returns explicit `VoiceConfirmationResult` (`confirmed`, `declined`, `unrecognized`, `cancelled`, `error`).

### Feature 5: Repeat Instruction Button
- Provided via `VoiceInstructionButton(showRepeatButton: true)` or `VoiceInstructionButton(isRepeatOnly: true)`.
- Replays the last spoken instruction with a single tap, minimizing cognitive anxiety for dementia patients who forgot the previous instruction.

---

## 4. Offline & Platform Fallback Strategy

Network connectivity in rural or North Eastern regions can be intermittent. The service employs an intelligent fallback hierarchy:

```
[Speech Request]
       │
       ▼
Is Network Available? ─── YES ───► Route to Bhashini Cloud API
       │
       NO (or Network Failure / API 500)
       ▼
Does Platform support Offline TTS/STT for this language?
       │
      YES ──► Fall back to NativePlatformVoiceProvider (on-device)
       │
       NO  ──► Graceful Degradation:
               • STT: Return VoiceResult.failure(VoiceErrorType.offlineNotSupported)
               • UI: Display accessible visual guidance & large manual buttons
```

### Truthful Offline Capability Reporting
> [!IMPORTANT]
> **Zero False Claims Policy**: SmritiSetu will **never** claim offline speech recognition if the installed device does not support it.
> - While cloud Bhashini supports Assamese and Manipuri, standard mobile operating systems do not ship with offline on-device ASR models for these languages.
> - If an offline STT request is received for a language lacking a verified on-device pack, the service explicitly returns `VoiceErrorType.offlineNotSupported` rather than faking support or failing silently.

---

## 5. Privacy, Security & Data Protection

### Zero-Storage Audio Policy
- Audio captured from the device microphone is streamed purely in-memory.
- Buffers are discarded immediately upon transcription completion, timeout, or cancellation.
- **No voice recording files are written to internal storage, SD cards, cache directories, or remote buckets** unless explicitly authorized for clinical research under informed consent.

### Non-Sensitive Patient Data Policy
- Before any text is dispatched to external cloud voice services (e.g. Bhashini), it passes through `PatientDataSanitizer`.
- Strips:
  - Medical Record Numbers (MRN / UHID / PID)
  - Diagnostic ICD codes (e.g. `ICD-10 F03`)
  - National IDs (Aadhaar numbers, SSNs)
  - Phone numbers and email addresses
  - Patient surnames or clinical history notes
- Cloud voice services receive only the clinical minimum required for voice synthesis (e.g. medicine brand and dosage instructions).

### API Credential Isolation
- API keys and cloud endpoints are **never** hardcoded into Dart source files.
- Loaded at runtime via `AppConfig`, environment variables, or encrypted secure storage (`SecureStorageService`).

---

## 6. Comprehensive Error Handling Matrix

All voice interactions return strongly-typed `VoiceResult<T>` or `VoiceConfirmationResult` handling 8 distinct failure modes:

| Error Type | Trigger Cause | System Response |
| :--- | :--- | :--- |
| `microphonePermissionDenied` | User denied microphone permission prompt | Shows accessible dialog explaining why mic is needed |
| `microphonePermissionPermanentlyDenied` | User tapped "Don't ask again" | Prompts user to open Device Settings |
| `networkFailure` | No internet or DNS failure to Bhashini | Automatically triggers platform offline fallback |
| `unsupportedLanguage` | Language code not registered | Falls back to system locale or displays text instructions |
| `timeout` | Elder did not speak within allotted window (8-10s) | Gracefully ends session; shows repeat/retry prompt |
| `apiError` | Bhashini 500 or upstream pipeline error | Seamlessly falls back to on-device TTS/STT |
| `noSpeechDetected` | Audio stream detected only silence or background noise | Friendly prompt: *"Didn't catch that, please try again"* |
| `userCancelled` | User tapped Cancel or navigated away | Immediately halts microphone stream and frees buffers |
| `offlineNotSupported` | Offline STT requested without local model pack | Truthfully informs user; provides manual on-screen buttons |
| `hardwareUnavailable` | Microphone or audio speaker in use by another app | Displays hardware busy notice |

---

## 7. Testing & Quality Assurance

All automated unit and widget tests use mocked providers (`MockBhashiniProvider`, `MockNativePlatformVoiceProvider`).
- **No live external network calls** are made during testing.
- Tests verify:
  - 14 regional languages configuration
  - 5 voice features (instructions, reminders, voice input, confirmation, repeat)
  - PHI sanitization prior to external synthesis
  - Zero audio file persistence
  - Offline fallback behavior
  - Truthful capability reporting for unsupported offline models
  - All 8 error conditions
