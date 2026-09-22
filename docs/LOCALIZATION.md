# SmritiSetu — Multilingual Localization Architecture

## 1. Zero Hard-Coded String Architecture

SmritiSetu enforces a strict architectural rule: **Zero visible strings in UI widgets**.  
Every button label, modal prompt, game instruction, error dialog, and caregiver metric header is retrieved via a strongly-typed or key-based localization system.

```dart
// Prohibited:
Text('Start Game');

// Mandatory:
Text(context.l10n.translate('game.common.start'));
```

---

## 2. Hierarchical Semantic Key Schema

Localization keys follow a dot-separated domain hierarchy:

```
[module].[submodule/screen].[element_type]
```

### Key Catalog Examples:
| Semantic Key | English (`en`) | Assamese (`as`) | Manipuri (`mni`) | Hindi (`hi`) |
|---|---|---|---|---|
| `app.name` | SmritiSetu | স্মৃতি সেতু | স্মৃতী সেতু | स्मृति सेतु |
| `app.disclaimer.banner` | Non-clinical cognitive support only | কেৱল অ-চিকিৎসাজনিত স্মৃতি সহায় | অনাক-লাইশঙগী ওইদবা মতেংখক্তনি | केवल गैर-चिकित्सीय संज्ञानात्मक सहायता |
| `game.face_match.title` | Family Face Match | পৰিয়ালৰ চিনাকি | ইমুংগী মশক খঙদোকপা | परिवार पहचान |
| `game.face_match.instruction` | Tap the person who matches this photo | ফটোখনৰ লগত মিল থকা জনক বাচক | ফোতোগা চুনবা মীওইদু খল্লু | इस तस्वीर से मेल खाने वाले व्यक्ति को चुनें |
| `game.pattern.title` | Pattern Completion | আৰ্হি সম্পূৰ্ণ কৰক | পেতর্ন মপুং ফাহনবা | पैटर्न पूरा करें |
| `game.sequence.title` | Daily Activity Sequence | দৈনন্দিন কামৰ ক্ৰম | নোংমগী থবকগী পরিং | दैनिक कार्य क्रम |
| `game.sorting.title` | Object Sorting | বস্তু শ্ৰেণীবিভাজন | পোত্থাক কাইথোকপা | वस्तु छांटना |
| `caregiver.dashboard.title` | Caregiver Activity Summary | পৰিচৰ্যাকাৰীৰ ডেশ্ববৰ্ড | য়েংশিনবীরিবগী দেশবোর্দ | देखभालकर्ता डैशबोर्ड |
| `medication.reminder.take_now` | Time to take medication | ঔষধ খোৱাৰ সময় হৈছে | হিদাক চাবগী মতম ওইরে | दवाई लेने का समय |

---

## 3. Language Matrix & Tier Categorization

### Tier 1: North Eastern Regional Languages (Primary Focus)
1. **Assamese (`as`)**: Spoken across Assam and Brahmaputra valley.
2. **Manipuri / Meitei (`mni`)**: Spoken in Manipur (Bengali & Meitei Mayek scripts).
3. **Bengali (`bn`)**: Spoken extensively in Tripura, Barak Valley (Assam).
4. **Bodo (`brx`)**: Bodoland Territorial Region (Devanagari script).
5. **Khasi (`kha`)**: Meghalaya (Latin script).
6. **Mizo (`lus`)**: Mizoram (Latin script).
7. **Garo (`grt`)**: Meghalaya (Latin script).

### Tier 2: Pan-Indian Languages
- Hindi (`hi`)
- Odia (`or`)
- Telugu (`te`)
- Tamil (`ta`)
- Kannada (`kn`)
- Malayalam (`ml`)
- Marathi (`mr`)
- Gujarati (`gu`)
- Punjabi (`pa`)
- Urdu (`ur` - Right-To-Left)

### Tier 3: International Languages
- English (`en`) — Universal fallback locale
- Spanish (`es`)
- French (`fr`)
- German (`de`)
- Arabic (`ar` — Right-To-Left bidirectional layout)
- Chinese (`zh-CN` / `zh-TW`)
- Japanese (`ja`)
- Korean (`ko`)

---

## 4. Right-To-Left (RTL) Layout Adaptation

For Arabic (`ar`) and Urdu (`ur`), the layout engine automatically mirrors:
1. `TextDirection.rtl` is injected into the root `Directionality` widget.
2. Horizontal layout paddings utilize `EdgeInsetsDirectional.start` / `EdgeInsetsDirectional.end` instead of hardcoded `left` / `right`.
3. Progression indicators and sequence arrows invert automatically without code duplication.

---

## 5. Adding New Languages Without Modifying UI Code

New languages are loaded via JSON/ARB translation bundles in the client's asset catalog:
```
assets/i18n/
├── en.json
├── as.json
├── mni.json
├── bn.json
├── hi.json
├── ar.json
└── ...
```

The `AppLocalizationDelegate` dynamically detects available language files, verifies fallback keys against `en.json`, and allows run-time switching with immediate UI re-rendering.
