import { SyntheticPatientSession } from './synthetic_generator';

export interface NormalizedSample {
  features: number[]; // Normalized numerical vector
  label: number;      // Binary completion target: 1 or 0
  rawRecord: SyntheticPatientSession;
}

export interface ScalerParams {
  featureNames: string[];
  min: number[];
  max: number[];
}

export interface DatasetSplit {
  train: NormalizedSample[];
  validation: NormalizedSample[];
  test: NormalizedSample[];
  scaler: ScalerParams;
}

export const FEATURE_NAMES = [
  'hourOfDay',
  'dayOfWeek',
  'recentAccuracy',
  'recentAvgResponseTimeMs',
  'consecutiveErrorStreak',
  'fatigueIndex',
  'sessionDurationTargetSeconds',
];

export function extractFeatureVector(record: SyntheticPatientSession): number[] {
  return [
    record.hourOfDay,
    record.dayOfWeek,
    record.recentAccuracy,
    record.recentAvgResponseTimeMs,
    record.consecutiveErrorStreak,
    record.fatigueIndex,
    record.sessionDurationTargetSeconds,
  ];
}

/**
 * Fits min-max scaler strictly on the training set and transforms splits
 * to eliminate data snooping / data leakage.
 */
export function splitAndNormalize(
  records: SyntheticPatientSession[],
  trainRatio = 0.7,
  valRatio = 0.15,
): DatasetSplit {
  const n = records.length;
  const trainEnd = Math.floor(n * trainRatio);
  const valEnd = trainEnd + Math.floor(n * valRatio);

  const trainRaw = records.slice(0, trainEnd);
  const valRaw = records.slice(trainEnd, valEnd);
  const testRaw = records.slice(valEnd);

  // Compute min and max strictly on the training set
  const numFeatures = FEATURE_NAMES.length;
  const min = new Array(numFeatures).fill(Infinity);
  const max = new Array(numFeatures).fill(-Infinity);

  for (const record of trainRaw) {
    const vec = extractFeatureVector(record);
    for (let f = 0; f < numFeatures; f++) {
      if (vec[f] < min[f]) min[f] = vec[f];
      if (vec[f] > max[f]) max[f] = vec[f];
    }
  }

  // Avoid zero division for constant features
  for (let f = 0; f < numFeatures; f++) {
    if (max[f] === min[f]) {
      max[f] += 1e-5;
    }
  }

  const scaler: ScalerParams = {
    featureNames: FEATURE_NAMES,
    min,
    max,
  };

  const normalizeVector = (vec: number[]): number[] => {
    return vec.map((val, idx) => {
      const normalized = (val - min[idx]) / (max[idx] - min[idx]);
      return Math.max(0.0, Math.min(1.0, normalized));
    });
  };

  const transform = (rawList: SyntheticPatientSession[]): NormalizedSample[] => {
    return rawList.map((rec) => ({
      features: normalizeVector(extractFeatureVector(rec)),
      label: rec.completed ? 1 : 0,
      rawRecord: rec,
    }));
  };

  return {
    train: transform(trainRaw),
    validation: transform(valRaw),
    test: transform(testRaw),
    scaler,
  };
}
