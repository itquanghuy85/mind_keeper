import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mind_keeper/core/di/app_providers.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/widgets/app_text_field.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/features/knowledge/learned_library_screen.dart';

/// Regression GĐ20: Kho đã học phải hiển thị item đã đăng ký.
/// Trước khi sửa, screen dùng `search('')` → luôn rỗng trên thiết bị.
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

Future<void> _settleReal(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (!tester.binding.hasScheduledFrame) break;
  }
}

Future<void> _pump(
  WidgetTester tester,
  AppServices services,
  Widget child,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: buildAppProviders(services),
      child: MaterialApp(
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        home: child,
      ),
    ),
  );
  await _settleReal(tester);
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Kho đã học — hồi quy listEnrolled (GĐ20)', () {
    testWidgets('hiển thị bài đã đăng ký thay vì trạng thái rỗng', (
      WidgetTester tester,
    ) async {
      final AppServices services = await _buildServices(tester);
      await _db<void>(tester, (AppServices s) async {
        final String topicId = (await s.topics.create(name: 'Toan')).id;
        await s.knowledge.enroll(
          topicId: topicId,
          title: 'Bai hoc so 1',
          content: 'Noi dung bai hoc so 1',
        );
      }, services: services);

      await _pump(tester, services, const LearnedLibraryScreen());

      expect(find.text('Bai hoc so 1'), findsOneWidget);
      expect(find.text('Chưa có bài trong Kho đã học'), findsNothing);

      await tester.runAsync(services.dispose);
    });

    testWidgets(
      'ô tìm kiếm không có kết quả rồi xoá từ khóa quay lại danh sách',
      (WidgetTester tester) async {
        final AppServices services = await _buildServices(tester);
        await _db<void>(tester, (AppServices s) async {
          final String topicId = (await s.topics.create(name: 'Toan')).id;
          await s.knowledge.enroll(
            topicId: topicId,
            title: 'Bai hoc so 1',
            content: 'Noi dung bai hoc so 1',
          );
        }, services: services);

        await _pump(tester, services, const LearnedLibraryScreen());
        expect(find.text('Bai hoc so 1'), findsOneWidget);

        final Finder field = find.descendant(
          of: find.byType(AppSearchField),
          matching: find.byType(TextField),
        );
        await tester.enterText(field, 'zzz_khong_ton_tai');
        await _settleReal(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Bai hoc so 1'), findsNothing);
        expect(find.text('Không tìm thấy kết quả'), findsOneWidget);

        await tester.enterText(field, '');
        await _settleReal(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Bai hoc so 1'), findsOneWidget);

        await tester.runAsync(services.dispose);
      },
    );
  });
}
