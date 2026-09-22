import { describe, it, before, after } from 'node:test';
import * as assert from 'node:assert';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../app.module';
import { HttpExceptionFilter } from '../common/filters/http-exception.filter';
import { generateSyntheticDataset } from '../ml/data/synthetic_generator';
import { splitAndNormalize } from '../ml/data/data_splitter';
import { trainLogisticRegression } from '../ml/training/train_session_completion';
import { trainRecommenderModel } from '../ml/training/train_recommender';
import { runMlPipeline } from '../ml/pipeline_runner';

describe('Phase 17: Explainable AI/ML Architecture & Pipeline Test Suite', () => {
  let app: INestApplication;
  let jwtService: JwtService;
  let baseUrl: string;

  before(async () => {
    process.env.NODE_ENV = 'test';
    process.env.JWT_SECRET = 'test_ultra_secure_jwt_secret_key_32_characters_long';

    app = await NestFactory.create(AppModule, { logger: false });

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalFilters(new HttpExceptionFilter());

    await app.listen(0);
    const address = app.getHttpServer().address();
    const port = typeof address === 'string' ? address : address.port;
    baseUrl = `http://127.0.0.1:${port}`;

    jwtService = app.get(JwtService);
  });

  after(async () => {
    if (app) {
      await app.close();
    }
  });

  // =========================================================================
  // 1. SYNTHETIC DATASET GENERATION & PROVENANCE
  // =========================================================================
  describe('1. Synthetic Data Generator & Provenance', () => {
    it('produces deterministic, identical datasets given the identical seed', () => {
      const dataA = generateSyntheticDataset({ sampleCount: 100, seed: 12345 });
      const dataB = generateSyntheticDataset({ sampleCount: 100, seed: 12345 });

      assert.strictEqual(dataA.length, 100);
      assert.strictEqual(dataB.length, 100);
      assert.strictEqual(dataA[0].sessionId, dataB[0].sessionId);
      assert.strictEqual(dataA[0].fatigueIndex, dataB[0].fatigueIndex);
      assert.strictEqual(dataA[42].recentAccuracy, dataB[42].recentAccuracy);
    });

    it('strictly labels all records with synthetic provenance flags', () => {
      const dataset = generateSyntheticDataset({ sampleCount: 50, seed: 99 });
      for (const record of dataset) {
        assert.strictEqual(record.isSynthetic, true);
        assert.strictEqual(record.generatorSeed, 99);
        assert.ok(record.generatedAt.length > 0);
        assert.ok(record.hourOfDay >= 0 && record.hourOfDay <= 23);
        assert.ok(record.recentAccuracy >= 0.0 && record.recentAccuracy <= 1.0);
        assert.ok(record.fatigueIndex >= 0.0 && record.fatigueIndex <= 1.0);
      }
    });
  });

  // =========================================================================
  // 2. DATASET PARTITIONING & ZERO-LEAKAGE SCALING
  // =========================================================================
  describe('2. Dataset Partitioning & Normalization', () => {
    it('partitions data strictly into 70% train / 15% validation / 15% test splits', () => {
      const dataset = generateSyntheticDataset({ sampleCount: 1000, seed: 42 });
      const splits = splitAndNormalize(dataset, 0.7, 0.15);

      assert.strictEqual(splits.train.length, 700);
      assert.strictEqual(splits.validation.length, 150);
      assert.strictEqual(splits.test.length, 150);

      // Verify bounds of normalized features are within [0, 1]
      for (const sample of splits.train) {
        for (const f of sample.features) {
          assert.ok(f >= 0.0 && f <= 1.0);
        }
      }
    });
  });

  // =========================================================================
  // 3. SUPERVISED LOGISTIC REGRESSION TRAINING & METRICS
  // =========================================================================
  describe('3. Supervised Model Training (Session Completion)', () => {
    it('trains logistic regression model and achieves non-trivial test accuracy and F1 score', () => {
      const dataset = generateSyntheticDataset({ sampleCount: 1000, seed: 42 });
      const splits = splitAndNormalize(dataset, 0.7, 0.15);
      const model = trainLogisticRegression(splits, {
        learningRate: 0.15,
        epochs: 150,
        l2Lambda: 0.01,
      });

      assert.strictEqual(model.algorithm, 'LOGISTIC_REGRESSION_L2');
      assert.strictEqual(model.isSyntheticTraining, true);
      assert.ok(model.weights.length === 7);
      assert.ok(typeof model.bias === 'number');

      // Assert metrics on the held-out test split
      assert.ok(
        model.metrics.test.accuracy >= 0.70,
        `Expected test accuracy >= 0.70, got ${model.metrics.test.accuracy}`,
      );
      assert.ok(
        model.metrics.test.f1Score >= 0.65,
        `Expected test F1 score >= 0.65, got ${model.metrics.test.f1Score}`,
      );
      assert.ok(model.metrics.test.logLoss < 0.70);
    });
  });

  // =========================================================================
  // 4. CONTEXTUAL RECOMMENDER TRAINING & UTILITY
  // =========================================================================
  describe('4. Contextual Game Recommender', () => {
    it('fits game weights and validates top-1 ranking performance', () => {
      const dataset = generateSyntheticDataset({ sampleCount: 800, seed: 42 });
      const recommender = trainRecommenderModel(dataset);

      assert.strictEqual(recommender.algorithm, 'CONTEXTUAL_BANDIT_UTILITY');
      assert.ok(recommender.gameWeights['PATTERN_RECALL'] !== undefined);
      assert.ok(recommender.gameWeights['WORD_ASSOCIATION'] !== undefined);
      assert.ok(recommender.metrics.top1Accuracy >= 0.60);
    });
  });

  // =========================================================================
  // 5. SECURE REST API ENDPOINTS & EXPLAINABILITY
  // =========================================================================
  describe('5. Secure Backend REST ML Endpoints', () => {
    it('POST /api/v1/ml/recommend-game provides adaptive game recommendation and factor weights', async () => {
      const patientToken = await jwtService.signAsync({
        sub: 'patient_1',
        email: 'patient1@smritisetu.org',
        role: 'PATIENT',
      });

      const res = await fetch(`${baseUrl}/api/v1/ml/recommend-game`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${patientToken}`,
        },
        body: JSON.stringify({
          patientId: 'patient_1',
          recentAccuracy: 0.88,
          fatigueIndex: 0.15,
          averageResponseTimeMs: 1400,
          hourOfDay: 10,
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.ok(data.recommendedGame);
      assert.ok(data.rankedAlternatives.length === 4);
      assert.ok(data.explainability.primaryReason.length > 0);
      assert.strictEqual(data.isSyntheticModel, true);
      assert.match(data.clinicalDisclaimer, /NON-CLINICAL MODEL/);
    });

    it('POST /api/v1/ml/predict-completion identifies fatigue risk and attributes contributing factors', async () => {
      const patientToken = await jwtService.signAsync({
        sub: 'patient_1',
        email: 'patient1@smritisetu.org',
        role: 'PATIENT',
      });

      // Fatigued patient profile
      const res = await fetch(`${baseUrl}/api/v1/ml/predict-completion`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${patientToken}`,
        },
        body: JSON.stringify({
          patientId: 'patient_1',
          hourOfDay: 20,
          dayOfWeek: 2,
          recentAccuracy: 0.45,
          recentAvgResponseTimeMs: 4500,
          consecutiveErrorStreak: 3,
          fatigueIndex: 0.85,
          sessionDurationTargetSeconds: 600,
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.ok(data.completionProbability < 0.60, 'Completion probability must reflect high fatigue');
      assert.ok(['MEDIUM', 'HIGH'].includes(data.riskTier));
      assert.ok(data.contributingFactors.length > 0);
      assert.ok(data.contributingFactors.some((f: any) => f.featureName === 'fatigueIndex'));
    });

    it('GET /api/v1/ml/trend/:patientId forecasts future performance trajectory with slope', async () => {
      const caregiverToken = await jwtService.signAsync({
        sub: 'caregiver_1',
        email: 'caregiver1@smritisetu.org',
        role: 'CAREGIVER',
      });

      const res = await fetch(`${baseUrl}/api/v1/ml/trend/patient_1`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${caregiverToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.patientId, 'patient_1');
      assert.ok(typeof data.trendSlope === 'number');
      assert.strictEqual(data.forecastNext3Sessions.length, 3);
      assert.ok(data.explainability.length > 0);
    });

    it('GET /api/v1/ml/model-card returns full model transparency card and provenance metadata', async () => {
      const patientToken = await jwtService.signAsync({
        sub: 'patient_1',
        email: 'patient1@smritisetu.org',
        role: 'PATIENT',
      });

      const res = await fetch(`${baseUrl}/api/v1/ml/model-card`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${patientToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.project, 'SmritiSetu Explainable AI/ML Architecture');
      assert.strictEqual(data.datasetProvenance.isSynthetic, true);
      assert.strictEqual(data.privacySafeguards.externalAiApiTransmission, false);
      assert.match(data.clinicalDisclaimer, /NON-CLINICAL MODEL/);
    });

    it('strictly denies unauthorized caregiver from querying unlinked patient ML trend', async () => {
      const caregiver2Token = await jwtService.signAsync({
        sub: 'caregiver_2',
        email: 'caregiver2@smritisetu.org',
        role: 'CAREGIVER',
      });

      // Caregiver 2 is not linked to Patient 1
      const res = await fetch(`${baseUrl}/api/v1/ml/trend/patient_1`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${caregiver2Token}` },
      });

      assert.strictEqual(res.status, 403);
      const data = await res.json();
      assert.match(data.message, /Caregiver not authorized/);
    });
  });
});
