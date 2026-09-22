# SmritiSetu — Adaptive Difficulty Engine (SIH26003)

## 1. Executive Summary & Non-Clinical Positioning

The **Adaptive Difficulty Engine** is an intelligent, pure domain service designed to customize the cognitive-support experience for elderly individuals in the North Eastern Region. 

> [!IMPORTANT]
> **CRITICAL NON-CLINICAL POSITIONING:**
> SmritiSetu is an assistive cognitive-support and monitoring prototype. This engine is strictly an **engagement and cognitive-stimulation adaptation mechanism**. It **MUST NOT** be construed as a medical or clinical diagnostic tool. It does not diagnose dementia, replace a physician, or prescribe medical treatments.

---

## 2. Why Adaptive Difficulty for Elderly Users?

Elderly users with early-stage memory changes or mild cognitive impairment experience natural day-to-day fluctuations in energy, alertness, and motor dexterity.
- **Fixed difficulty fails:** If games are too hard, users experience frustration, anxiety, and abandonment. If games are too simple, they provide insufficient mental stimulation.
- **Single-session volatility is dangerous:** If a user makes a single accidental tap due to hand tremor or momentary distraction, an algorithm should **never** abruptly demote them.
- **Elderly-first pacing:** The engine measures processing speed without imposing harsh, panic-inducing countdown timers.

---

## 3. The 4 Core Telemetry Signals

For every game session, the engine evaluates four raw performance signals:

| Signal | Meaning | Weight | Normalization Benchmark |
|---|---|---|---|
| **Accuracy ($A$)** | Fraction of correct choices ($0.0$ to $1.0$) | **50%** | Raw fraction correct |
| **Response Efficiency ($T$)** | Average response time per trial | **25%** | Optimal: $1,500\,\text{ms}$, Upper bound: $8,000\,\text{ms}$ |
| **Hesitation Factor ($H$)** | Idle hesitation before taking action | **15%** | Tolerable threshold: $5,000\,\text{ms}$ |
| **Error Penalty ($E$)** | Count of incorrect attempts | **-10%** | Max tolerable errors: $5$ |

### Mathematical Formula

1. **Normalized Single-Session Score ($S_{\text{session}}$):**
   $$S_{\text{session}} = \text{clamp}\Big((0.50 \times F_{\text{acc}}) + (0.25 \times F_{\text{rt}}) + (0.15 \times F_{\text{hes}}) - (0.10 \times F_{\text{err}}),\, 0.0,\, 1.0\Big)$$

2. **Multi-Session Smoothing ($S_{\text{rolling}}$):**
   To prevent erratic jumps, the engine applies exponential smoothing with a smoothing factor of $\alpha = 0.60$:
   $$S_{\text{rolling}} = 
   \begin{cases} 
   S_{\text{session}}, & \text{if first session} \\
   (0.60 \times S_{\text{session}}) + (0.40 \times S_{\text{previous}}), & \text{with history}
   \end{cases}$$

---

## 4. Decision Rules & Behavior

Difficulty is strictly bounded between **Level 1** (Introductory) and **Level 5** (Advanced).

```mermaid
graph TD
    INPUT[Telemetry: Accuracy, Response Time, Hesitation, Errors] --> SCORE[Calculate Weighted S_session & Rolling Score]
    SCORE --> PROMOTE_CHECK{Rolling Score >= 0.82 AND Consecutive High Sessions >= 2?}
    PROMOTE_CHECK -- YES --> PROMOTE[Level = min(Current + 1, 5)<br>Reason: Increase Level]
    PROMOTE_CHECK -- NO --> DEMOTE_CHECK{Persistent Struggle < 0.45 OR Severe Struggle < 0.30?}
    DEMOTE_CHECK -- YES --> DEMOTE[Level = max(Current - 1, 1)<br>Reason: Reduce Level to Prevent Fatigue]
    DEMOTE_CHECK -- NO --> MAINTAIN[Level = Current Level<br>Reason: Maintain Steady Practice]
```

### Promotion Rule (High Consistent Performance)
- **Condition:** Rolling score $\ge 0.82$, accuracy $\ge 80\%$, and at least 2 consecutive sessions with performance $\ge 0.80$.
- **Action:** `currentDifficulty + 1` (clamped at Level 5).
- **Reason:** User demonstrated consistent mastery across consecutive sessions.

### Demotion Rule (Persistent Struggle or Severe Fatigue)
- **Condition:** Rolling score $< 0.45$ over consecutive sessions OR severe struggle in the current session ($S_{\text{session}} < 0.30$).
- **Action:** `currentDifficulty - 1` (clamped at Level 1).
- **Reason:** Difficulty reduced gently to relieve cognitive fatigue and maintain self-confidence.

### Maintenance Rule (Comfort Zone & Slip Protection)
- **Condition:** Stable performance between $0.45$ and $0.82$.
- **Single Mistake Protection:** If a user with a strong history ($\ge 75\%$) has an isolated off-session or single error, the rolling smoothing absorbs the dip and maintains the current level without punitive demotion.
- **Action:** `currentDifficulty` remains unchanged.

---

## 5. Walkthrough Examples for SIH Judges

### Example 1: Promotion through Demonstrated Mastery
- **Starting Level:** Level 2
- **Previous Session Score:** $0.88$ (High)
- **Current Session:**
  - Accuracy: $95\%$
  - Errors: $1$
  - Response Time: $1,600\,\text{ms}$ (Optimal)
  - Hesitation: $600\,\text{ms}$ (Low)
- **Calculated Session Score:** $0.91$
- **Rolling Score:** $(0.60 \times 0.91) + (0.40 \times 0.88) = 0.90$
- **Engine Decision:**
  - `nextDifficulty`: **Level 3** (Promoted)
  - `reason`: *"Increase from Level 2 → Level 3"*
  - `confidence`: $0.85$ (High confidence with multiple consistent observations)

---

### Example 2: Protection against an Isolated Mistake
- **Starting Level:** Level 3
- **Previous Session Score:** $0.82$ (Strong)
- **Current Session:**
  - Accuracy: $80\%$ (4 out of 5 correct)
  - Errors: $1$ (Single accidental slip)
  - Response Time: $2,500\,\text{ms}$
- **Calculated Session Score:** $0.72$
- **Rolling Score:** $(0.60 \times 0.72) + (0.40 \times 0.82) = 0.76$
- **Engine Decision:**
  - `nextDifficulty`: **Level 3** (Maintained)
  - `reason`: *"Maintain Level 3 for consistent practice"*
  - **Judge Takeaway:** The user is NOT penalized for a single misclick or tremor.

---

### Example 3: Gentle Reduction on Fatigue / Persistent Struggle
- **Starting Level:** Level 3
- **Previous Session Score:** $0.40$ (Struggling)
- **Current Session:**
  - Accuracy: $40\%$
  - Errors: $4$
  - Response Time: $7,000\,\text{ms}$ (Slow, high hesitation)
- **Calculated Session Score:** $0.32$
- **Rolling Score:** $(0.60 \times 0.32) + (0.40 \times 0.40) = 0.35$ (Below $0.45$)
- **Engine Decision:**
  - `nextDifficulty`: **Level 2** (Gently reduced)
  - `reason`: *"Reduce from Level 3 → Level 2 to maintain confidence"*
  - `configuration`: Reconfigures games with fewer choices and extra audio guidance.

---

## 6. Game Configurations Across Difficulty Levels

The engine outputs dynamic configuration blueprints for each difficulty level:

| Level | Choices | Sequence Length | Distractors | Audio Assistance | Pace Tolerance |
|---|---|---|---|---|---|
| **Level 1 (Introductory)** | 2 | 3 steps | 0 | Maximum voice repetition | Very Relaxed ($10\,\text{s}$) |
| **Level 2 (Gentle)** | 3 | 4 steps | 1 | High voice assistance | Relaxed ($8\,\text{s}$) |
| **Level 3 (Standard)** | 3 | 5 steps | 1 | Standard audio prompts | Standard ($7\,\text{s}$) |
| **Level 4 (Challenging)** | 4 | 6 steps | 2 | Standard audio prompts | Moderate ($6\,\text{s}$) |
| **Level 5 (Advanced)** | 4 | 8 steps | 2 | Minimal cues (subtle) | Active ($5\,\text{s}$) |

---

## 7. Determinism & Integrity Guarantees

1. **Pure Domain Function:** Zero side-effects. Identical telemetry inputs produce identical decisions on every execution.
2. **Offline-First:** Runs 100% locally on the user's mobile device without requiring cloud connectivity.
3. **Audit History:** Every decision, reason code, and performance metric is recorded in SQLite (`difficulty_history` table) for caregiver progress review.
