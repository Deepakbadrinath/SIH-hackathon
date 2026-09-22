import { DatasetSplit, NormalizedSample } from '../data/data_splitter';
import {
  CLINICAL_DISCLAIMER,
  EvaluationMetrics,
  TrainedCompletionModel,
} from '../models/model_registry';

export interface TrainHyperparameters {
  learningRate?: number;
  epochs?: number;
  l2Lambda?: number;
  batchSize?: number;
}

export function sigmoid(z: number): number {
  if (z >= 40) return 1.0;
  if (z <= -40) return 0.0;
  return 1.0 / (1.0 + Math.exp(-z));
}

export function evaluateModel(
  samples: NormalizedSample[],
  weights: number[],
  bias: number,
  threshold = 0.5,
): EvaluationMetrics {
  let tp = 0;
  let fp = 0;
  let tn = 0;
  let fn = 0;
  let totalLoss = 0;
  const n = samples.length;

  for (const sample of samples) {
    let z = bias;
    for (let i = 0; i < weights.length; i++) {
      z += weights[i] * sample.features[i];
    }
    const prob = sigmoid(z);
    const predicted = prob >= threshold ? 1 : 0;
    const actual = sample.label;

    // Cross-entropy loss (clipped for stability)
    const eps = 1e-15;
    const clippedProb = Math.max(eps, Math.min(1 - eps, prob));
    totalLoss += -(actual * Math.log(clippedProb) + (1 - actual) * Math.log(1 - clippedProb));

    if (predicted === 1 && actual === 1) tp++;
    else if (predicted === 1 && actual === 0) fp++;
    else if (predicted === 0 && actual === 0) tn++;
    else if (predicted === 0 && actual === 1) fn++;
  }

  const accuracy = (tp + tn) / n;
  const precision = tp + fp > 0 ? tp / (tp + fp) : 0;
  const recall = tp + fn > 0 ? tp / (tp + fn) : 0;
  const f1Score = precision + recall > 0 ? (2 * precision * recall) / (precision + recall) : 0;
  const logLoss = totalLoss / n;

  return {
    accuracy: Number(accuracy.toFixed(4)),
    precision: Number(precision.toFixed(4)),
    recall: Number(recall.toFixed(4)),
    f1Score: Number(f1Score.toFixed(4)),
    logLoss: Number(logLoss.toFixed(4)),
    sampleCount: n,
  };
}

export function trainLogisticRegression(
  dataset: DatasetSplit,
  hyperparams: TrainHyperparameters = {},
): TrainedCompletionModel {
  const lr = hyperparams.learningRate || 0.05;
  const epochs = hyperparams.epochs || 150;
  const l2 = hyperparams.l2Lambda || 0.001;

  const numFeatures = dataset.scaler.featureNames.length;
  const weights = new Array(numFeatures).fill(0);
  let bias = 0;

  const trainSamples = dataset.train;
  const m = trainSamples.length;

  // Gradient descent with L2 regularization
  for (let epoch = 0; epoch < epochs; epoch++) {
    const gradW = new Array(numFeatures).fill(0);
    let gradB = 0;

    for (const sample of trainSamples) {
      let z = bias;
      for (let i = 0; i < numFeatures; i++) {
        z += weights[i] * sample.features[i];
      }
      const pred = sigmoid(z);
      const error = pred - sample.label;

      gradB += error;
      for (let i = 0; i < numFeatures; i++) {
        gradW[i] += error * sample.features[i];
      }
    }

    // Apply parameter updates
    bias -= (lr * gradB) / m;
    for (let i = 0; i < numFeatures; i++) {
      weights[i] = weights[i] * (1 - (lr * l2) / m) - (lr * gradW[i]) / m;
    }
  }

  // Evaluate across all three partitions strictly
  const trainMetrics = evaluateModel(dataset.train, weights, bias);
  const valMetrics = evaluateModel(dataset.validation, weights, bias);
  const testMetrics = evaluateModel(dataset.test, weights, bias);

  return {
    modelName: 'SmritiSetu_Session_Completion_Classifier',
    version: '1.0.0',
    trainedAt: new Date().toISOString(),
    algorithm: 'LOGISTIC_REGRESSION_L2',
    featureNames: dataset.scaler.featureNames,
    weights: weights.map((w) => Number(w.toFixed(6))),
    bias: Number(bias.toFixed(6)),
    scaler: dataset.scaler,
    metrics: {
      train: trainMetrics,
      validation: valMetrics,
      test: testMetrics,
    },
    isSyntheticTraining: true,
    clinicalDisclaimer: CLINICAL_DISCLAIMER,
  };
}
