import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smriti_setu/core/database/database_helper.dart';
import 'package:smriti_setu/core/demo/demo_data_manager.dart';
import 'package:smriti_setu/data/datasources/local/sync_queue_local_data_source.dart';
import 'package:smriti_setu/domain/models/caregiver_dashboard_models.dart';
import 'package:smriti_setu/domain/models/system_models.dart';
import 'package:smriti_setu/features/caregiver/data/repositories/caregiver_dashboard_repository_impl.dart';
import 'package:smriti_setu/features/caregiver/data/services/caregiver_authorization_service_impl.dart';
import 'package:smriti_setu/features/offline_sync/data/repositories/sync_repository_impl.dart';
import 'package:smriti_setu/presentation/screens/caregiver/widgets/simple_accessible_charts.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper.forCustomPath(inMemoryDatabasePath);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('Performance Audit Benchmarks', () {
    test('1. Benchmark Startup Seeding: Cold vs Warm', () async {
      final coldStopwatch = Stopwatch()..start();
      await DemoDataManager.seedDemoData(dbHelper: dbHelper, resetExisting: true);
      coldStopwatch.stop();
      final coldTimeMs = coldStopwatch.elapsedMilliseconds;

      final warmStopwatch = Stopwatch()..start();
      await DemoDataManager.seedDemoData(dbHelper: dbHelper, resetExisting: false);
      warmStopwatch.stop();
      final warmTimeMs = warmStopwatch.elapsedMilliseconds;

      debugPrint('PERF: Cold Seed Duration: ${coldTimeMs}ms');
      debugPrint('PERF: Warm Seed Duration: ${warmTimeMs}ms');

      expect(coldTimeMs, greaterThan(0));
      expect(warmTimeMs, greaterThanOrEqualTo(0));
    });

    test('2. Benchmark Database Query Latency: Dashboard and Patients', () async {
      await DemoDataManager.seedDemoData(dbHelper: dbHelper, resetExisting: true);

      final authService = CaregiverAuthorizationServiceImpl(dbHelper: dbHelper);
      final dashboardRepo = CaregiverDashboardRepositoryImpl(
        authService: authService,
        dbHelper: dbHelper,
      );

      // Connected patients query
      final patientsWatch = Stopwatch()..start();
      final patients = await dashboardRepo.getConnectedPatients(DemoDataManager.demoCaregiverId);
      patientsWatch.stop();
      final patientsTimeUs = patientsWatch.elapsedMicroseconds;

      expect(patients.isNotEmpty, isTrue);

      // Full 3-table join dashboard query
      final dashWatch = Stopwatch()..start();
      final data = await dashboardRepo.getDashboardData(
        requestingCaregiverId: DemoDataManager.demoCaregiverId,
        patientId: DemoDataManager.demoPatientId,
        dateFilter: DateRangeFilter.last14Days,
      );
      dashWatch.stop();
      final dashTimeUs = dashWatch.elapsedMicroseconds;

      expect(data.recentSessions.isNotEmpty, isTrue);
      expect(data.performanceSummary.totalGamesCompleted, greaterThan(0));

      debugPrint('PERF: getConnectedPatients query: ${patientsTimeUs}μs (${(patientsTimeUs / 1000).toStringAsFixed(2)}ms)');
      debugPrint('PERF: getDashboardData complex query: ${dashTimeUs}μs (${(dashTimeUs / 1000).toStringAsFixed(2)}ms)');
    });

    test('3. Benchmark Sync Queue Throughput (100 operations enqueue)', () async {
      final syncDataSource = SyncQueueLocalDataSourceImpl(dbHelper: dbHelper);
      final syncRepo = SyncRepositoryImpl(localDataSource: syncDataSource);

      final enqueueWatch = Stopwatch()..start();
      const opCount = 100;
      for (int i = 0; i < opCount; i++) {
        final item = SyncItem(
          operationId: 'bench_op_$i',
          entityId: 'game_session_$i',
          entityType: 'GAME_SESSION',
          operationType: SyncOperationType.insert,
          payloadJson: '{"session_id":"bench_$i","score":100,"accuracy":1.0}',
          timestamp: DateTime.now(),
          retryCount: 0,
          syncStatus: SyncStatus.pending,
        );
        await syncRepo.enqueueOperation(item);
      }
      enqueueWatch.stop();

      final totalMs = enqueueWatch.elapsedMilliseconds;
      final opsPerSec = (opCount / (totalMs / 1000.0)).round();

      debugPrint('PERF: Enqueued $opCount sync items in ${totalMs}ms ($opsPerSec ops/sec)');
      expect(totalMs, greaterThan(0));
    });

    testWidgets('4. Benchmark Chart Widget Layout & Render Timing', (WidgetTester tester) async {
      final List<TrendDataPoint<double>> points = List.generate(
        14,
        (i) => TrendDataPoint<double>(
          timestamp: DateTime.now().subtract(Duration(days: 14 - i)),
          value: 70.0 + (i * 2.0),
          label: 'Day $i',
        ),
      );

      final renderWatch = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccuracyTrendChart(trendPoints: points),
          ),
        ),
      );
      renderWatch.stop();

      debugPrint('PERF: AccuracyTrendChart pump time: ${renderWatch.elapsedMicroseconds}μs');
      expect(find.byType(AccuracyTrendChart), findsOneWidget);
    });
  });
}
