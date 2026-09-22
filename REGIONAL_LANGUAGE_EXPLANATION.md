# SmritiSetu — Regional Language & Voice Architecture

> **Document:** SIH Grand Finale Technical Deep Dive  
> **Topic:** Multilingual Localization, Bhashini Cloud Integration, and Dual-Tier Fallback  
> **Mission:** Breaking Linguistic Barriers for Elderly Dementia Care in North-Eastern India  

---

## 1. Why Focus on North-Eastern Regional Languages?

India’s North-Eastern Region (NER) contains rich linguistic diversity, with millions speaking languages from the Indo-Aryan, Tibeto-Burman, and Austroasiatic families. 

When elderly individuals develop mild cognitive impairment or dementia, their cognitive reserve shrinks, and they frequently **lose fluency in second or third languages** (such as English or Hindi), reverting strictly to their native mother tongue. If an assistive app cannot speak to an Assamese grandmother in **Assamese (*অসমীয়া*)** or a grandfather in Imphal in **Manipuri (*মৈতৈলোন্*)**, the application is completely useless.

SmritiSetu provides first-class native support for **14 Indian languages**:

| Language | Script | Region / Demographic | Voice Engine Support |
| :--- | :--- | :--- | :---: |
| **Assamese (অসমীয়া)** | Eastern Nagari | Assam, Brahmaputra Valley | Bhashini AI + Native Fallback |
| **Manipuri (মৈতৈলোন্)** | Meetei Mayek / Bengali | Manipur, Imphal Valley | Bhashini AI + Native Fallback |
| **Bengali (বাংলা)** | Bengali Script | West Bengal, Tripura, Barak Valley | Bhashini AI + Native Fallback |
| **Hindi (हिन्दी)** | Devanagari | Pan-India | Bhashini AI + Native Fallback |
| **English** | Latin | Global / Urban Centers | Platform Native + Bhashini |
| **Odia (ଓଡ଼ିଆ)** | Odia Script | Odisha, Border Districts | Bhashini AI + Native Fallback |
| **Telugu (తెలుగు)** | Telugu Script | Andhra Pradesh, Telangana | Bhashini AI + Native Fallback |
| **Tamil (தமிழ்)** | Tamil Script | Tamil Nadu, Puducherry | Bhashini AI + Native Fallback |
| **Kannada (ಕನ್ನಡ)** | Kannada Script | Karnataka | Bhashini AI + Native Fallback |
| **Malayalam (മലയാളം)**| Malayalam Script | Kerala | Bhashini AI + Native Fallback |
| **Marathi (मराठी)** | Devanagari | Maharashtra | Bhashini AI + Native Fallback |
| **Gujarati (ગુજરાતી)** | Gujarati Script | Gujarat | Bhashini AI + Native Fallback |
| **Punjabi (ਪੰਜਾਬੀ)** | Gurmukhi | Punjab | Bhashini AI + Native Fallback |
| **Urdu (اردو)** | Nastaliq / Perso-Arabic| Pan-India (RTL Layout) | Platform Native + Bhashini |

---

## 2. Dual-Tier Voice Architecture: Bhashini Cloud AI + On-Device Fallback

To ensure the voice engine never fails—even when presenting in an auditorium with dead Wi-Fi or when an elderly user is in a remote village—we implemented a **Multi-Provider Dual-Tier Voice Architecture** ([`VoiceServiceImpl`](file:///d:/SIH%20hackathon/mobile/lib/features/voice/data/services/voice_service_impl.dart)).

```
┌─────────────────────────────────────────────────────────────┐
│                 Text-to-Speech Synthesis                     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                [PatientDataSanitizer: Strip PHI]
                               │
                               ▼
                Network Connected & Bhashini OK?
                              / \
                        Yes  /   \  No (Offline, Timeout >3s, or Error)
                            /     \
                           ▼       ▼
              ┌──────────────────┐ ┌───────────────────────────┐
              │ Bhashini Cloud   │ │ On-Device Platform TTS    │
              │ Government AI    │ │ (Android / iOS / Windows) │
              │ (Natural Accents)│ │ (Zero Delay, 100% Offline)│
              └──────────────────┘ └───────────────────────────┘
```

### 2.1 Primary Tier: Digital India Bhashini Cloud AI
- Leverages the Government of India’s **Bhashini ULCA API** endpoint.
- Produces natural-sounding regional accents, dialectal inflections, and compassionate prosody tailored for Indian languages.
- Streams audio payloads directly into the client’s audio pipeline.

### 2.2 Fallback Tier: Native On-Device Platform TTS
- If the device is offline, Bhashini servers are unresponsive, or a request takes longer than 3 seconds, `TextToSpeechServiceImpl` immediately catches the exception and falls back to the host operating system's native TTS engine (Android TTS / iOS AVSpeechSynthesizer / Windows SAPI).
- **Zero Interruption**: The elderly patient is never shown a cryptic "Network Error" dialog; auditory prompts continue seamlessly.

---

## 3. Privacy-Preserving Voice Reminders: PHI Sanitization

Medical ethics and privacy laws (e.g., India's Digital Personal Data Protection Act - DPDP) mandate that Protected Health Information (PHI) must **never** be transmitted to external third-party speech synthesis APIs without strict controls.

Before sending any reminder text to Bhashini or external cloud engines, the payload passes through [`PatientDataSanitizer`](file:///d:/SIH%20hackathon/mobile/lib/features/voice/data/services/patient_data_sanitizer.dart):

```
Raw Reminder: "Good morning Deka Da, it is 8:00 AM. Please take your Donepezil 5mg for Alzheimer's Dementia."
                                  │
                                  ▼
                     [PatientDataSanitizer Filter]
     • Replaces patient full name with generic compassionate honorific ("Dada" / "Elder")
     • Strips sensitive diagnostic clinical terms ("Alzheimer's", "Dementia", "Psychosis")
     • Preserves vital dosing instruction ("Donepezil 5mg at 8:00 AM")
                                  │
                                  ▼
Sanitized Stream: "Good morning, it is 8:00 AM. Time to take your medicine: Donepezil 5mg with a glass of water."
```

---

## 4. Internationalization Architecture & RTL Support

SmritiSetu’s localization architecture is built for global extensibility beyond India:
1. **JSON Localization Catalogs**: Decoupled string resource files located in [`assets/i18n/`](file:///d:/SIH%20hackathon/mobile/assets/i18n/).
2. **Foreign Language Extensibility**: Architecture verified with demonstration catalogs in German (`de`), French (`fr`), Spanish (`es`), and Arabic (`ar`).
3. **Right-to-Left (RTL) Layout Engine**:
   - Languages such as Urdu (`ur`) and Arabic (`ar`) automatically wrap the top-level `MaterialApp` in a dynamic `Directionality(textDirection: locCtrl.isRtl ? TextDirection.rtl : TextDirection.ltr)`.
   - Layouts, back buttons, card flows, and badges mirror automatically without layout corruption.
4. **Font Expansion & Overflow Defense**:
   - Indian scripts and German compound words expand text length by **25% to 45%** compared to English.
   - All layout containers utilize `Flexible`, `Expanded`, `SingleChildScrollView`, and responsive breakpoints to guarantee zero text overflow even under **1.3× text scale** on compact viewports (360×640).
