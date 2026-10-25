import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mind_keeper/core/di/app_providers.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/features/knowledge/knowledge_library_screen.dart';
import 'package:mind_keeper/features/knowledge/learned_library_screen.dart';
import 'package:mind_keeper/features/profile/profile_screen.dart';
import 'package:mind_keeper/features/profile/study_plan_screen.dart';
import 'package:mind_keeper/features/topics/topic_detail_screen.dart';

/// Harness giống layout_overflow_test.dart: DB FFI phải chạy trong runAsync.
Future<AppServices> _buildServices(WidgetTester tester) async {
  final AppServices? services = await tester.runAsync(() async {
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
  });
  return services!;
}

Future<T> _db<T>(
  WidgetTester tester,
  Future<T> Function(AppServices services) op, {
  required AppServices services,
}) async {
  final T? result = await tester.runAsync(() => op(services));
  return result as T;
}

Future<void> _dispose(WidgetTester tester, AppServices services) async {
  await tester.runAsync(services.dispose);
}

Widget _wrap(AppServices services, Widget child) => MultiProvider(
  providers: buildAppProviders(services),
  child: MaterialApp(
    theme: ThemeData.light(),
    locale: const Locale('vi'),
    home: child,
  ),
);

Future<void> _settleReal(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (!tester.binding.hasScheduledFrame) {
      break;
    }
  }
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await _settleReal(tester);
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Entry point điều hướng (GĐ20)', () {
    testWidgets('TopicDetail → Kho kiến thức (KnowledgeLibraryScreen)', (
      WidgetTester tester,
    ) async {
      final AppServices services = await _buildServices(tester);
      final String topicId = await _db<String>(
        tester,
        (AppServices s) async => (await s.topics.create(name: 'Toán')).id,
        services: services,
      );

      await _pump(tester, _wrap(services, TopicDetailScreen(topicId: topicId)));

      expect(find.byTooltip('Kho kiến thức'), findsOneWidget);

      await tester.tap(find.byTooltip('Kho kiến thức'));
      await _settleReal(tester);

      expect(find.byType(KnowledgeLibraryScreen), findsOneWidget);

      await _dispose(tester, services);
    });

    testWidgets('Profile → Kho đã học (LearnedLibraryScreen)', (
      WidgetTester tester,
    ) async {
      final AppServices services = await _buildServices(tester);

      await _pump(tester, _wrap(services, const ProfileScreen()));

      final Finder entry = find.text('Kho đã học');
      expect(entry, findsWidgets);

      // Tile nằm ngoài khung nhìn của màn hình test — cuộn tới trước khi bấm.
      await tester.scrollUntilVisible(
        entry.first,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(entry.first);
      await _settleReal(tester);

      expect(find.byType(LearnedLibraryScreen), findsOneWidget);

      await _dispose(tester, services);
    });

    testWidgets('Profile → Kế hoạch học (StudyPlanScreen)', (
      WidgetTester tester,
    ) async {
      final AppServices services = await _buildServices(tester);

      await _pump(tester, _wrap(services, const ProfileScreen()));

      final Finder entry = find.text('Kế hoạch học');
      expect(entry, findsOneWidget);

      // Tile may be outside the viewport, scroll into view before tapping (GD20 entry point).
      await tester.scrollUntilVisible(
        entry.first,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(entry.first);
      await _settleReal(tester);

      expect(find.byType(StudyPlanScreen), findsOneWidget);

      await _dispose(tester, services);
    });
  });
}
