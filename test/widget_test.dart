import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/app.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<AppServices> buildTestServices() async {
  sqfliteFfiInit();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final AppDatabase app = AppDatabase(
    factory: databaseFactoryFfi,
    name: inMemoryDatabasePath,
  );
  await app.open();
  return AppServices.build(
    database: app,
    prefs: prefs,
    notifications: FakeNotificationService(),
  );
}

void main() {
  testWidgets('app mở tab Hôm nay với dữ liệu rỗng', (
    WidgetTester tester,
  ) async {
    // sqflite FFI chạy event loop thật — cần runAsync ngoài FakeAsync của widget test.
    final AppServices? services = await tester.runAsync(buildTestServices);
    expect(services, isNotNull);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MindKeeperApp(services: services!));
    // Đợi load dữ liệu DB thật (ngoài fake async).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('Học một chủ đề mới'), findsOneWidget);
    await tester.runAsync(services.dispose);
  });
}
