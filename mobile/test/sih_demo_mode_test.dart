import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smriti_setu/core/database/database_constants.dart';
import 'package:smriti_setu/core/database/database_helper.dart';
import 'package:smriti_setu/core/demo/demo_data_manager.dart';
import 'package:smriti_setu/core/network/network_info.dart';
import 'package:smriti_setu/features/demo/presentation/controllers/demo_controller.dart';
import 'package:smriti_setu/presentation/common_widgets/sih_demo_bar.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late NetworkInfo networkInfo;
  late DemoController demoController;

  setUp(() async {
    dbHelper = DatabaseHelper.forCustomPath(inMemoryDatabasePath);
    networkInfo = NetworkInfo();
    networkInfo.setMockConnectionStatus(true);
    demoController = DemoController(networkInfo: networkInfo, dbHelper: dbHelper);
  });

  tearDown(() async {
    networkInfo.setMockConnectionStatus(null);
    await dbHelper.close();
  });

  group('SIH Demo Data Manager & Repeatability', () {
    test('seedDemoData seeds synthetic patient, caregiver, medications, and game history', () async {
      await DemoDataManager.seedDemoData(dbHelper: dbHelper, resetExisting: true);

      final db = await dbHelper.database;
      final patients = await db.query(DatabaseConstants.tablePatients);
      final caregivers = await db.query(DatabaseConstants.tableCaregivers);
      final relationships = await db.query(DatabaseConstants.tableCaregiverPatientRelationships);
      final medications = await db.query(DatabaseConstants.tableMedications);
      final logs = await db.query(DatabaseConstants.tableMedicationLogs);
      final gameSessions = await db.query(DatabaseConstants.tableGameSessions);

      expect(patients.isNotEmpty, isTrue);
      expect(patients.first['id'], equals(DemoDataManager.demoPatientId));
      expect(caregivers.isNotEmpty, isTrue);
      expect(caregivers.first['id'], equals(DemoDataManager.demoCaregiverId));
      expect(relationships.isNotEmpty, isTrue);
      expect(medications.length, equals(2));
      expect(logs.length, equals(28));
      expect(gameSessions.length, equals(6));
    });

    test('purgeAllData clears all data cleanly', () async {
      await DemoDataManager.seedDemoData(dbHelper: dbHelper, resetExisting: false);
      await DemoDataManager.purgeAllData(dbHelper: dbHelper);

      final db = await dbHelper.database;
      final patients = await db.query(DatabaseConstants.tablePatients);
      final gameSessions = await db.query(DatabaseConstants.tableGameSessions);
      final medications = await db.query(DatabaseConstants.tableMedications);

      expect(patients.isEmpty, isTrue);
      expect(gameSessions.isEmpty, isTrue);
      expect(medications.isEmpty, isTrue);
    });

    test('resetDemoData resets demo and restores baseline repeatability', () async {
      await DemoDataManager.seedDemoData(dbHelper: dbHelper, resetExisting: false);
      await demoController.toggleSimulatedOffline();
      expect(demoController.isOfflineSimulated, isTrue);

      await demoController.resetDemoData();
      expect(demoController.isOfflineSimulated, isFalse);
      expect(networkInfo.mockConnectionStatus, isNull);

      final db = await dbHelper.database;
      final patients = await db.query(DatabaseConstants.tablePatients);
      expect(patients.length, equals(2));
    });
  });

  group('SIH Demo Bar Widget & Controls', () {
    testWidgets('Renders collapsed SIH DEMO pill and expands on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DemoController>.value(value: demoController),
            ],
            child: const Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Main App Content')),
                  SihDemoBar(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('SIH DEMO'), findsOneWidget);
      expect(find.text('Turn Off Network'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('SIH DEMO'));
      await tester.pumpAndSettle();

      expect(find.text('SIH Demo Controls'), findsOneWidget);
      expect(find.text('Turn Off Network'), findsOneWidget);
      expect(find.text('Reset Demo Baseline'), findsOneWidget);
    });

    testWidgets('Toggling network switches to OFFLINE mode badge and status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DemoController>.value(value: demoController),
            ],
            child: const Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Main App Content')),
                  SihDemoBar(),
                ],
              ),
            ),
          ),
        ),
      );

      // Expand
      await tester.tap(find.text('SIH DEMO'));
      await tester.pumpAndSettle();

      // Tap Turn Off Network
      await tester.tap(find.text('Turn Off Network'));
      await tester.pumpAndSettle();

      expect(demoController.isOfflineSimulated, isTrue);
      expect(find.text('Reconnect Network'), findsOneWidget);
      expect(find.text('OFFLINE SIMULATION'), findsOneWidget);
    });

    testWidgets('X close button minimizes panel and does not trigger any tooltip or modal overlay on hover', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DemoController>.value(value: demoController),
            ],
            child: const Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Main App Content')),
                  SihDemoBar(),
                ],
              ),
            ),
          ),
        ),
      );

      // Expand panel
      if (!demoController.isExpanded) {
        await tester.tap(find.text('SIH DEMO'));
        await tester.pumpAndSettle();
      }

      expect(find.text('SIH Demo Controls'), findsOneWidget);

      // Verify close button exists
      final closeBtnFinder = find.byIcon(Icons.close_rounded);
      expect(closeBtnFinder, findsOneWidget);

      final initialModalBarriers = tester.widgetList(find.byType(ModalBarrier)).length;

      // Hover over the X button
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(closeBtnFinder));
      await tester.pump();

      // Verify NO tooltip is shown and no new ModalBarrier is created
      expect(find.byType(Tooltip), findsNothing);
      expect(tester.widgetList(find.byType(ModalBarrier)).length, equals(initialModalBarriers));
      expect(find.text('Main App Content'), findsOneWidget);

      // Move mouse away
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump();

      // Tap the close button to minimize
      await tester.tap(closeBtnFinder);
      await tester.pumpAndSettle();

      // Panel should now be minimized
      expect(demoController.isExpanded, isFalse);
      expect(find.text('SIH DEMO'), findsOneWidget);
      expect(find.text('SIH Demo Controls'), findsNothing);
    });
  });
}
