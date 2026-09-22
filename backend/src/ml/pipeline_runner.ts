import { generateSyntheticDataset } from './data/synthetic_generator';
import { splitAndNormalize } from './data/data_splitter';
import { trainLogisticRegression } from './training/train_session_completion';
import { trainRecommenderModel } from './training/train_recommender';
import {
  TrainedCompletionModel,
  TrainedRecommenderModel,
} from './models/model_registry';

export interface PipelineArtifacts {
  completionModel: TrainedCompletionModel;
  recommenderModel: TrainedRecommenderModel;
  datasetStats: {
    totalSyntheticSamples: number;
    trainSamples: number;
    valSamples: number;
    testSamples: number;
    generatedAt: string;
  };
}

/**
 * Executes the entire training, validation, and testing pipeline deterministically.
 */
export function runMlPipeline(seed: number = 42, sampleCount: number = 2000): PipelineArtifacts {
  // 1. Generate Synthetic Patient Interactions with explicit synthetic labeling
  const dataset = generateSyntheticDataset({ sampleCount, seed });

  // 2. Separate Training, Validation, and Testing sets
  const splits = splitAndNormalize(dataset, 0.7, 0.15);

  // 3. Train Session Completion Classifier (Logistic Regression)
  const completionModel = trainLogisticRegression(splits, {
    learningRate: 0.15,
    epochs: 250,
    l2Lambda: 0.01,
  });

  // 4. Train Contextual Game Recommender
  const recommenderModel = trainRecommenderModel(dataset.slice(0, Math.floor(sampleCount * 0.7)));

  return {
    completionModel,
    recommenderModel,
    datasetStats: {
      totalSyntheticSamples: dataset.length,
      trainSamples: splits.train.length,
      valSamples: splits.validation.length,
      testSamples: splits.test.length,
      generatedAt: dataset[0]?.generatedAt || new Date().toISOString(),
    },
  };
}
