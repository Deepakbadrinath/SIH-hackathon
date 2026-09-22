import { ScalerParams } from '../data/data_splitter';

export interface EvaluationMetrics {
  accuracy: number;
  precision: number;
  recall: number;
  f1Score: number;
  logLoss: number;
  sampleCount: number;
}

export interface TrainedCompletionModel {
  modelName: string;
  version: string;
  trainedAt: string;
  algorithm: 'LOGISTIC_REGRESSION_L2';
  featureNames: string[];
  weights: number[];
  bias: number;
  scaler: ScalerParams;
  metrics: {
    train: EvaluationMetrics;
    validation: EvaluationMetrics;
    test: EvaluationMetrics;
  };
  isSyntheticTraining: true;
  clinicalDisclaimer: string;
}

export interface GamePreferenceWeight {
  gameType: string;
  baseUtility: number;
  fatigueSensitivity: number;  // Negative penalty coefficient when fatigue is high
  speedBonusCoefficient: number; // Bonus when user has low response times
  memoryReinforcementWeight: number; // Weight given to cognitive memory reinforcement
}

export interface TrainedRecommenderModel {
  modelName: string;
  version: string;
  algorithm: 'CONTEXTUAL_BANDIT_UTILITY';
  trainedAt: string;
  gameWeights: Record<string, GamePreferenceWeight>;
  explorationEpsilon: number; // For exploration-exploitation balance
  metrics: {
    top1Accuracy: number;
    ndcgScore: number;
    sampleCount: number;
  };
  isSyntheticTraining: true;
  clinicalDisclaimer: string;
}

export const CLINICAL_DISCLAIMER =
  'NON-CLINICAL MODEL: Developed for user engagement optimization and interface adaptation. ' +
  'This model has NOT been clinically validated for diagnostic purposes, disease staging, or medical prognosis.';
