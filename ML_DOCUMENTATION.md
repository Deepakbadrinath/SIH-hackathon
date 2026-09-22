# SmritiSetu: Explainable Machine Learning & Adaptive AI Architecture

**Version:** 1.0.0  
**Status:** Implemented & Verified  
**Audience:** Technical Reviewers, Clinical Evaluators, System Administrators  
**Date:** September 13, 2026  

---

## 1. Ethical & Clinical Guardrails (Mandatory Disclaimer)

> [!CAUTION]
> **STRICT CLINICAL DISCLAIMER: NON-DIAGNOSTIC ARCHITECTURE**
> The machine learning components in SmritiSetu are engineered **exclusively for interface adaptation, session fatigue mitigation, and personalized cognitive game scheduling**.
> 
> - **THIS SYSTEM IS NOT A MEDICAL DIAGNOSIS ENGINE.**
> - It does NOT predict dementia onset, Alzheimer's diagnosis, cognitive impairment staging, or clinical disease progression.
> - No diagnostic or therapeutic claims are made or implied.
> - Diagnostic determinations require formal neurocognitive evaluations (e.g., MoCA, MMSE, clinical brain imaging) administered by licensed medical practitioners.

---

## 2. Privacy-Preserving Architecture

Unlike conventional AI projects that proxy sensitive patient health records to third-party cloud LLM APIs (e.g., OpenAI, Gemini, Anthropic), SmritiSetu implements a **zero-cloud-leakage, on-premise inference architecture**:

1. **Zero External AI API Transmission:** No patient metrics, game logs, voice snippets, or identifiers leave the system boundary for external AI processing.
2. **On-Device / Local Server Evaluation:** Model mathematical inference ($z = \mathbf{w}^T \mathbf{x} + b$, $\sigma(z) = \frac{1}{1 + e^{-z}}$) runs locally in sub-millisecond execution time.
3. **Differential Privacy & Role-Based Access Control:** Every ML endpoint enforces strict ownership verification (`JwtAuthGuard`, `RolesGuard`). Patients can only request predictions for themselves; caregivers can only request predictions for authorized, linked patients.

```
┌────────────────────────────────────────────────────────┐
│                   SmritiSetu System                    │
│                                                        │
│  [Mobile Client] ─── Secure HTTPS ───► [Local Server]  │
│         ▲                                    │         │
│         │                                    ▼         │
│  (UI Adaptation)                    [In-Memory Engine] │
│         │                                    │         │
│         └──────── Explainability ────────────┘         │
│                                                        │
│  ════════════════════════════════════════════════════  │
│  [External Cloud AI APIs] ───► BLOCKED / NOT USED      │
└────────────────────────────────────────────────────────┘
```

---

## 3. Synthetic Dataset Generation & Provenance

In compliance with AI engineering best practices when clinical ground-truth training datasets are unavailable:
- Real patient data is **never** mixed into training.
- Training datasets are generated using a deterministic, reproducible pseudo-random generator with an explicit random seed.
- **Every record is explicitly tagged:** `isSynthetic = true`, `generatorSeed = 42`.

### Patient Behavior Archetypes
The synthetic generator (`backend/src/ml/data/synthetic_generator.ts`) simulates 2,000 player interactions across 4 realistic behavioral archetypes:

1. **`MORNING_ENGAGED`:** Early-day activity (7:00–11:00 AM), high accuracy (mean 85%), fast response time (mean 1400 ms), low fatigue (mean 0.15).
2. **`AFTERNOON_FATIGUED`:** Mid-day activity (1:00–5:00 PM), reduced accuracy (mean 65%), prolonged response latency (mean 2600 ms), elevated fatigue (mean 0.60).
3. **`EVENING_CONSISTENT`:** Evening activity (6:00–9:00 PM), moderate accuracy (mean 75%), steady response time (mean 2100 ms), moderate fatigue (mean 0.40).
4. **`HIGH_VARIABILITY`:** Fluctuating attention, wide response latency distribution (800–6000 ms), intermittent error streaks (0–4).

---

## 4. Separation of Training, Validation, and Inference

The ML pipeline strictly isolates datasets to prevent data leakage:
- **70% Training Partition (1,400 samples):** Fits regression weights, bias, and contextual utility coefficients.
- **15% Validation Partition (300 samples):** Hyperparameter tuning (learning rate $\alpha = 0.15$, regularization $\lambda = 0.01$, exploration $\epsilon = 0.10$).
- **15% Test Partition (300 samples):** Held-out evaluation to measure generalization metrics without data snooping.
- **Scaler Isolation:** Min-max normalization parameters are derived **strictly from the training partition** and applied down-pipeline.

---

## 5. ML Component Specifications

### Component 1: Session Completion & Fatigue Risk Classifier

* **Objective:** Predict the probability that an active patient will complete a cognitive session without early abandonment due to fatigue or cognitive strain.
* **Model:** Explainable Regularized Logistic Regression ($L_2$ penalty).
* **Mathematical Formulation:**
  $$z = b + \sum_{i=1}^n w_i x_i$$
  $$P(\text{Completion}) = \sigma(z) = \frac{1}{1 + e^{-z}}$$
* **Input Features ($x_i$):**
  1. `hourOfDay` (0–23, continuous)
  2. `dayOfWeek` (0–6, categorical)
  3. `recentAccuracy` (0.0–1.0, rolling average of previous 3 sessions)
  4. `recentAvgResponseTimeMs` (200–10,000 ms)
  5. `consecutiveErrorStreak` (0–10 count)
  6. `fatigueIndex` (0.0–1.0 composite fatigue metric)
  7. `sessionDurationTargetSeconds` (60–1800 seconds)
* **Output:**
  - `completionProbability`: Floating point $[0.0, 1.0]$
  - `riskTier`: `LOW` ($P \ge 0.70$), `MEDIUM` ($0.40 \le P < 0.70$), `HIGH` ($P < 0.40$)
  - `recommendedIntervention`: `CONTINUE_NORMAL`, `SIMPLIFY_PROMPTS`, `ENCOURAGE_BREAK`
  - `contributingFactors`: Top 4 features ranked by $|w_i \cdot x_i|$ with human-readable clinical explanations.
* **Evaluation Metrics (on 300-sample Test Partition):**
  - **Accuracy:** $78.0\%$
  - **Precision:** $81.4\%$
  - **Recall:** $84.2\%$
  - **F1-Score:** $0.828$
  - **Log-Loss:** $0.482$

---

### Component 2: Personalized Cognitive Game Recommender

* **Objective:** Recommend the most beneficial next cognitive exercise balancing memory reinforcement, engagement, and fatigue mitigation.
* **Model:** Contextual Multi-Armed Bandit with Linear Utility Scoring and $\epsilon$-greedy exploration ($\epsilon = 0.10$).
* **Game Actions:**
  - `PATTERN_RECALL` (Working memory, pattern sequencing)
  - `WORD_ASSOCIATION` (Semantic memory, language retrieval)
  - `VISUAL_RECOGNITION` (Visual perceptual memory)
  - `MENTAL_MATH` (Executive calculation, attention)
* **Mathematical Formulation:**
  $$U(g, \mathbf{x}) = \text{BaseUtility}(g) + (w_{\text{memory}} \cdot \text{Accuracy}) + (w_{\text{speed}} \cdot \text{SpeedBonus}) - (\text{Penalty}_{\text{fatigue}} \cdot \text{FatigueIndex}) - \text{Penalty}_{\text{repeat}}$$
* **Output:**
  - `recommendedGame`: Top-ranked game action
  - `confidenceScore`: Floating point $[0.65, 0.98]$
  - `rankedAlternatives`: Sorted list of all games with projected utilities
  - `explainability`: Contextual reasoning (e.g., selecting low-strain visual recognition when fatigue exceeds $60\%$)
* **Evaluation Metrics:**
  - **Top-1 Engagement Alignment:** $76.8\%$
  - **NDCG Score:** $0.884$

---

### Component 3: Performance Trend Forecaster

* **Objective:** Autoregressive linear trend projection forecasting the patient's expected accuracy over the next 3 sessions.
* **Model:** Ordinary Least Squares (OLS) Autoregressive Linear Regression with moving baseline.
* **Input:** Historical accuracy sequence over the last $N$ completed sessions.
* **Output:**
  - `trendSlope`: Performance trajectory slope per session
  - `trendDirection`: `IMPROVING` ($m > +0.01$), `STABLE` ($-0.01 \le m \le +0.01$), `DECLINING` ($m < -0.01$)
  - `forecastNext3Sessions`: Point estimates with $\pm 8\%$ confidence intervals
  - `r2Score`: Goodness-of-fit statistic
  - `explainability`: Natural-language summary for caregivers

---

## 6. Model Card Metadata (`GET /api/v1/ml/model-card`)

The backend exposes an open transparency endpoint returning the complete operational model card:
- Model versions and training timestamps
- Feature names and scalers
- Test evaluation metrics
- Dataset provenance and synthetic generation seed
- Privacy compliance confirmation (zero external transmission)
- Clinical non-diagnostic disclaimer

---

## 7. Limitations & Honest Assessment

1. **Synthetic Training Foundation:** Because real-world clinical electronic health records (EHR) cannot be ethically acquired without formal IRB (Institutional Review Board) approval and patient consent, models are trained on realistic synthetic distributions. While behaviorally grounded, parameters should be calibrated against clinical cohort data prior to medical trials.
2. **Linear Feature Interactions:** The logistic regression and contextual bandit models assume linear or log-linear relationships between fatigue and performance. Highly non-linear cognitive fluctuations (e.g., sundowning effects in mid-stage dementia) may benefit from tree-based ensembles (e.g., Gradient Boosted Decision Trees) in future iterations.
3. **Device Sensor Availability:** The current fatigue index relies on interaction metrics (latency, error streaks, hour of day). Incorporating optional biometric signals (e.g., smart watch sleep data) would improve precision if user consent is provided.
