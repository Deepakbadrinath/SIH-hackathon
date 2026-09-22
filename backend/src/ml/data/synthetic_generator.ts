/**
 * SmritiSetu ML Pipeline: Synthetic Data Generator
 *
 * IMPORTANT CLINICAL & ETHICAL DISCLAIMER:
 * This generator produces synthetic, simulated patient session data purely for
 * training and validating explainable behavioral models (game recommendation and
 * session completion prediction). It does NOT represent clinically validated
 * diagnostic datasets and must NEVER be used for medical diagnosis.
 */

export interface SyntheticPatientSession {
  sessionId: string;
  patientId: string;
  archetype: 'MORNING_ENGAGED' | 'AFTERNOON_FATIGUED' | 'EVENING_CONSISTENT' | 'HIGH_VARIABILITY';
  
  // Input Features
  hourOfDay: number;                 // 0-23
  dayOfWeek: number;                 // 0 (Sun) - 6 (Sat)
  recentAccuracy: number;            // 0.0 - 1.0 (rolling average of previous 3 sessions)
  recentAvgResponseTimeMs: number;   // 800 - 6000 ms
  consecutiveErrorStreak: number;    // 0 - 5
  fatigueIndex: number;              // 0.0 (fresh) - 1.0 (exhausted)
  sessionDurationTargetSeconds: number; // e.g. 180, 300, 600
  gameType: 'PATTERN_RECALL' | 'WORD_ASSOCIATION' | 'VISUAL_RECOGNITION' | 'MENTAL_MATH';

  // Ground Truth Targets (for supervised learning)
  completed: boolean;                // 1 = completed session, 0 = abandoned prematurely
  engagementScore: number;           // 0.0 - 1.0
  completionRatio: number;           // 0.0 - 1.0

  // Provenance metadata
  isSynthetic: true;
  generatorSeed: number;
  generatedAt: string;
}

/**
 * Deterministic pseudo-random number generator (LCG) to guarantee 100% reproducibility.
 */
export class DeterministicRNG {
  private state: number;

  constructor(seed: number = 42) {
    this.state = seed % 2147483647;
    if (this.state <= 0) this.state += 2147483646;
  }

  next(): number {
    this.state = (this.state * 16807) % 2147483647;
    return (this.state - 1) / 2147483646;
  }

  nextInt(min: number, max: number): number {
    return Math.floor(this.next() * (max - min + 1)) + min;
  }

  nextGaussian(mean = 0, stdDev = 1): number {
    const u1 = Math.max(1e-10, this.next());
    const u2 = this.next();
    const randStdNormal = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);
    return mean + stdDev * randStdNormal;
  }
}

export interface GeneratorOptions {
  sampleCount?: number;
  seed?: number;
}

export function generateSyntheticDataset(options: GeneratorOptions = {}): SyntheticPatientSession[] {
  const sampleCount = options.sampleCount || 2000;
  const seed = options.seed || 42;
  const rng = new DeterministicRNG(seed);
  const records: SyntheticPatientSession[] = [];

  const archetypes: Array<SyntheticPatientSession['archetype']> = [
    'MORNING_ENGAGED',
    'AFTERNOON_FATIGUED',
    'EVENING_CONSISTENT',
    'HIGH_VARIABILITY',
  ];

  const gameTypes: Array<SyntheticPatientSession['gameType']> = [
    'PATTERN_RECALL',
    'WORD_ASSOCIATION',
    'VISUAL_RECOGNITION',
    'MENTAL_MATH',
  ];

  const now = new Date().toISOString();

  for (let i = 0; i < sampleCount; i++) {
    const archetype = archetypes[rng.nextInt(0, archetypes.length - 1)];
    const patientId = `patient_syn_${rng.nextInt(1, 100)}`;
    const sessionId = `syn_sess_${seed}_${i + 1}`;
    const dayOfWeek = rng.nextInt(0, 6);
    const gameType = gameTypes[rng.nextInt(0, gameTypes.length - 1)];

    let hourOfDay = 10;
    let baseAccuracy = 0.8;
    let baseResponseTime = 1800;
    let fatigueIndex = 0.2;
    let errorStreak = 0;

    switch (archetype) {
      case 'MORNING_ENGAGED':
        hourOfDay = rng.nextInt(7, 11);
        baseAccuracy = 0.85 + rng.nextGaussian(0, 0.08);
        baseResponseTime = 1400 + rng.nextGaussian(0, 300);
        fatigueIndex = Math.max(0.05, 0.15 + rng.nextGaussian(0, 0.05));
        errorStreak = rng.next() < 0.8 ? 0 : rng.nextInt(1, 2);
        break;

      case 'AFTERNOON_FATIGUED':
        hourOfDay = rng.nextInt(13, 17);
        baseAccuracy = 0.65 + rng.nextGaussian(0, 0.1);
        baseResponseTime = 2600 + rng.nextGaussian(0, 500);
        fatigueIndex = Math.min(0.95, 0.60 + rng.nextGaussian(0, 0.12));
        errorStreak = rng.next() < 0.5 ? rng.nextInt(1, 3) : 0;
        break;

      case 'EVENING_CONSISTENT':
        hourOfDay = rng.nextInt(18, 21);
        baseAccuracy = 0.75 + rng.nextGaussian(0, 0.07);
        baseResponseTime = 2100 + rng.nextGaussian(0, 400);
        fatigueIndex = 0.40 + rng.nextGaussian(0, 0.1);
        errorStreak = rng.next() < 0.7 ? 0 : rng.nextInt(1, 2);
        break;

      case 'HIGH_VARIABILITY':
        hourOfDay = rng.nextInt(6, 22);
        baseAccuracy = 0.55 + rng.nextGaussian(0, 0.18);
        baseResponseTime = 3200 + rng.nextGaussian(0, 900);
        fatigueIndex = Math.max(0.1, Math.min(0.95, rng.next()));
        errorStreak = rng.nextInt(0, 4);
        break;
    }

    // Clamp features to realistic bounds
    const recentAccuracy = Math.max(0.1, Math.min(1.0, baseAccuracy));
    const recentAvgResponseTimeMs = Math.max(800, Math.min(6000, baseResponseTime));
    const clampedFatigue = Math.max(0.0, Math.min(1.0, fatigueIndex));
    const sessionDurationTarget = [180, 300, 600][rng.nextInt(0, 2)];

    // Realistic behavior model for completion target:
    // Higher fatigue, longer duration, high response time, error streak reduce completion odds
    const logit =
      1.8 +
      2.2 * (recentAccuracy - 0.7) -
      2.8 * (clampedFatigue - 0.4) -
      1.4 * ((recentAvgResponseTimeMs - 2000) / 1000) -
      0.6 * errorStreak -
      0.8 * ((sessionDurationTarget - 300) / 300) +
      rng.nextGaussian(0, 0.35);

    const completionProb = 1.0 / (1.0 + Math.exp(-logit));
    const completed = rng.next() < completionProb;
    const completionRatio = completed
      ? 1.0
      : Math.max(0.1, Math.min(0.9, completionProb * 0.9 + rng.nextGaussian(0, 0.1)));

    // Engagement score utility
    const engagementScore = Math.max(
      0.05,
      Math.min(0.99, recentAccuracy * 0.6 + (1.0 - clampedFatigue) * 0.4 + (completed ? 0.1 : -0.15)),
    );

    records.push({
      sessionId,
      patientId,
      archetype,
      hourOfDay,
      dayOfWeek,
      recentAccuracy: Number(recentAccuracy.toFixed(4)),
      recentAvgResponseTimeMs: Math.round(recentAvgResponseTimeMs),
      consecutiveErrorStreak: errorStreak,
      fatigueIndex: Number(clampedFatigue.toFixed(4)),
      sessionDurationTargetSeconds: sessionDurationTarget,
      gameType,
      completed,
      engagementScore: Number(engagementScore.toFixed(4)),
      completionRatio: Number(completionRatio.toFixed(4)),
      isSynthetic: true,
      generatorSeed: seed,
      generatedAt: now,
    });
  }

  return records;
}
