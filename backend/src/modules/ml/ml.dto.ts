import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class RecommendGameDto {
  @IsString()
  @MaxLength(64)
  patientId: string;

  @IsNumber()
  @Min(0.0)
  @Max(1.0)
  @IsOptional()
  recentAccuracy?: number = 0.75;

  @IsNumber()
  @Min(0.0)
  @Max(1.0)
  @IsOptional()
  fatigueIndex?: number = 0.2;

  @IsNumber()
  @Min(200)
  @Max(10000)
  @IsOptional()
  averageResponseTimeMs?: number = 2000;

  @IsNumber()
  @Min(0)
  @Max(23)
  @IsOptional()
  hourOfDay?: number = 10;

  @IsString()
  @IsOptional()
  lastPlayedGame?: string;
}

export class PredictCompletionDto {
  @IsString()
  @MaxLength(64)
  patientId: string;

  @IsNumber()
  @Min(0)
  @Max(23)
  hourOfDay: number;

  @IsNumber()
  @Min(0)
  @Max(6)
  dayOfWeek: number;

  @IsNumber()
  @Min(0.0)
  @Max(1.0)
  recentAccuracy: number;

  @IsNumber()
  @Min(200)
  @Max(15000)
  recentAvgResponseTimeMs: number;

  @IsNumber()
  @Min(0)
  @Max(10)
  consecutiveErrorStreak: number;

  @IsNumber()
  @Min(0.0)
  @Max(1.0)
  fatigueIndex: number;

  @IsNumber()
  @Min(60)
  @Max(1800)
  sessionDurationTargetSeconds: number;
}

export interface ExplainabilityFactor {
  featureName: string;
  impact: 'POSITIVE' | 'NEGATIVE' | 'NEUTRAL';
  importanceWeight: number;
  explanation: string;
}

export interface RecommendGameResponseDto {
  recommendedGame: string;
  confidenceScore: number;
  rankedAlternatives: Array<{ gameType: string; score: number }>;
  explainability: {
    primaryReason: string;
    factorWeights: {
      fatigueAdaptation: number;
      cognitiveChallenge: number;
      speedBonus: number;
    };
  };
  isSyntheticModel: boolean;
  clinicalDisclaimer: string;
}

export interface PredictCompletionResponseDto {
  completionProbability: number;
  riskTier: 'LOW' | 'MEDIUM' | 'HIGH';
  recommendedIntervention: 'CONTINUE_NORMAL' | 'SIMPLIFY_PROMPTS' | 'ENCOURAGE_BREAK';
  contributingFactors: ExplainabilityFactor[];
  isSyntheticModel: boolean;
  clinicalDisclaimer: string;
}

export interface TrendForecastPoint {
  sessionIndex: number;
  projectedAccuracy: number;
  confidenceIntervalLower: number;
  confidenceIntervalUpper: number;
}

export interface PerformanceTrendResponseDto {
  patientId: string;
  sampleCount: number;
  historicalMeanAccuracy: number;
  trendSlope: number;
  trendDirection: 'IMPROVING' | 'STABLE' | 'DECLINING';
  forecastNext3Sessions: TrendForecastPoint[];
  r2Score: number;
  explainability: string;
  clinicalDisclaimer: string;
}
