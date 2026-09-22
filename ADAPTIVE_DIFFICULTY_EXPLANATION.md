# SmritiSetu — Adaptive Difficulty & Cognitive Gaming Engine

> **Document:** SIH Grand Finale Technical Deep Dive  
> **Topic:** Adaptive Difficulty Progression & Cognitive Game Design  
> **Philosophy:** Compassionate Accessibility • Explainable Determinism • Zero Medical Diagnostic Claims  

---

## 1. Why These Four Cognitive Games?

Commercial brain-training apps (Lumosity, Peak, Elevate) are built for young, healthy tech users seeking high-speed competitive stimulation. In elderly individuals experiencing mild cognitive decline or dementia, high-speed games trigger **catastrophic cognitive anxiety, disorientation, and abandonment**.

SmritiSetu replaces arbitrary puzzles with **4 targeted, daily-routine anchored cognitive domains**:

| Game Type | Cognitive Domain Stimulated | Everyday Real-World Equivalent | Elderly Pacing Guardrail |
| :--- | :--- | :--- | :--- |
| **1. Family Face Match** | **Facial Recognition & Associative Memory** (Fusiform face area, anterior temporal lobe) | Recognizing daughters, sons, grandchildren, and spouses in family photographs. | No timer; friendly family relation prompts (*"Son - Rahul"*); familiar photos. |
| **2. Pattern Completion** | **Visual Processing & Inductive Reasoning** (Parietal-frontal network) | Predicting daily sequence patterns, calendar days, or household arrangement. | High-contrast shapes and symbols; 1 missing element; clear distinctive options. |
| **3. Activity Sequence** | **Executive Function & Procedural Memory** (Prefrontal cortex, basal ganglia) | Ordering daily personal care routines (e.g., Making Tea: Boil water → Add tea leaves → Add milk). | Visual step cards with drag/tap sequencing; familiar domestic rituals. |
| **4. Object Sorting** | **Semantic Categorization & Long-Term Memory** (Left inferior prefrontal cortex) | Sorting household items (kitchen utensils vs. gardening tools vs. winter clothing). | Binary or ternary accessible bins; culturally contextual items (e.g. *Gamusa*, *Kettle*). |

---

## 2. How Game Performance is Measured

Rather than relying on arbitrary "points", SmritiSetu records **objective behavioral telemetry** across every single trial:

1. **Trial Accuracy ($A \in [0.0, 1.0]$)**:
   $$\text{Accuracy} = \frac{\text{Correct Trials}}{\text{Total Trials}}$$
2. **Mean Response Latency ($\overline{T}_{\text{resp}}$ in ms)**:
   The elapsed time from stimulus rendering to user touch.
3. **Hesitation Pause ($T_{\text{hesit}}$ in ms)**:
   Initial latency before the user's first touch exploration or option hover. Measures cognitive processing hesitation before motor initiation.
4. **Error Count ($E$)**:
   Number of incorrect attempts made during the session.

---

## 3. The Adaptive Difficulty Algorithm: Explainable Heuristic

SmritiSetu uses a **transparent, clinically explainable mathematical heuristic** implemented on-device in [`AdaptiveDifficultyEngine`](file:///d:/SIH%20hackathon/mobile/lib/data/adaptive/adaptive_difficulty_engine.dart). 

### Why NOT a Black-Box Deep Neural Network for Difficulty?
In healthcare-adjacent accessibility applications, **black-box models are dangerous**. If a deep learning model abruptly demotes a user without explainability, it causes emotional distress. If it over-promotes, it induces anxiety. 

Our algorithm calculates a normalized **Single-Session Performance Score ($S \in [0.0, 1.0]$)**:

$$S = 0.50 \cdot A + 0.25 \cdot \max\left(0, 1 - \frac{\overline{T}_{\text{resp}}}{8000}\right) + 0.15 \cdot \max\left(0, 1 - \frac{T_{\text{hesit}}}{4000}\right) + 0.10 \cdot \max\left(0, 1 - \frac{E}{3}\right)$$

### Difficulty Transition Thresholds

```
                      Single Session Score (S)
  0.0                                0.60              0.80               1.0
  ├────────────────────────────────────┼─────────────────┼──────────────────┤
  │       DEMOTION ZONE                │  MAINTAIN ZONE  │  PROMOTION ZONE  │
  │      (Next Level: L - 1)           │ (Next Level: L) │ (Next Level: L + 1)
  │  Accuracy < 60% OR Error Count >= 2│  Steady Comfort │ High Accuracy & Latency
  └────────────────────────────────────┴─────────────────┴──────────────────┘
```

1. **Promotion Rule ($L \to L+1$)**:
   - Condition: Accuracy $\ge 80\%$ **AND** Mean Latency $\le 3500\text{ms}$ **AND** Score $S \ge 0.75$.
   - Max Level: Level 5.
   - Code: `PROMOTED_HIGH_PERFORMANCE`.
   - Reason Displayed: *"High accuracy and comfortable response latency triggered difficulty increase."*
2. **Demotion Rule ($L \to L-1$)**:
   - Condition: Accuracy $< 60\%$ **OR** Error Count $\ge 2$ **OR** Score $S < 0.45$.
   - Min Level: Level 1.
   - Code: `DEMOTED_SUPPORT_NEEDED`.
   - Reason Displayed: *"Lower trial accuracy or hesitation triggered gentle difficulty reduction to maintain comfort."*
3. **Maintain Rule ($L \to L$)**:
   - Condition: Performance within steady zone ($0.45 \le S < 0.75$).
   - Code: `MAINTAINED_STEADY`.
   - Reason Displayed: *"Comfortable steady engagement maintained."*

---

## 4. Difficulty Levels 1 through 5 in Action

| Level | Family Face Match | Pattern Completion | Activity Sequence | Object Sorting |
| :---: | :--- | :--- | :--- | :--- |
| **Level 1** | 2 candidate photos (1 prompt, 1 distractor); clear relation badge. | 3-item repeating binary sequence (A-B-A-?). | 3 routine steps to order. | 2 obvious categories (Kitchen vs Clothes). |
| **Level 2** | 3 candidate photos (1 prompt, 2 distractors); relation hint. | 4-item alternating sequence (A-B-C-A-B-?). | 4 routine steps to order. | 2 categories with subtle distractors. |
| **Level 3** | 4 candidate photos (close family resemblance). | Geometric transformation sequence (Rotation/Size). | 5 daily routine steps. | 3 categories (Kitchen, Tools, Nature). |
| **Level 4** | 4 candidate photos with slight temporal age progression. | Multi-attribute sequence (Color + Shape). | 5 steps with branching domestic tasks. | 3 categories with higher item count. |
| **Level 5** | 6 candidate photos; subtle distinguishing features. | Abstract logical progression. | 6 sequential procedural steps. | 4 complex categories. |

---

## 5. What Makes SmritiSetu Fundamentally Different from Normal Games?

```
┌───────────────────────────────────────┬───────────────────────────────────────┐
│          COMMERCIAL GAMES             │              SMRITISETU               │
├───────────────────────────────────────┼───────────────────────────────────────┤
│ Countdown timers induce time pressure │ ZERO timers — patient takes all time  │
│ Harsh buzzers on wrong answers        │ Gentle, non-judgmental guidance       │
│ Micro-transactions and paywalls       │ 100% Free, open-source, local-first   │
│ Distracting ads and popups            │ Clutter-free WCAG AAA accessibility   │
│ Competitive global leaderboards       │ Private longitudinal caregiver trends │
│ Abstract fantasy puzzles              │ Daily-life anchors (family, tea, meds)│
└───────────────────────────────────────┴───────────────────────────────────────┘
```

---

## 6. Scientific Boundary & Disclaimer

> **Crucial Clarification for Judges:**  
> The Adaptive Difficulty Engine is **NOT a clinical cognitive assessment score** (such as MoCA or MMSE). It is an **ergonomic calibration mechanism** designed solely to keep the elderly player in a state of comfortable, stress-free flow. Performance trends are provided to family caregivers to observe behavioral consistency over time, not to render medical diagnoses.
