import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mind_keeper/core/di/app_providers.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/widgets/app_card.dart';
import 'package:mind_keeper/core/widgets/app_text_field.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/features/home/today_screen.dart';
import 'package:mind_keeper/features/lessons/lesson_discover_screen.dart';
import 'package:mind_keeper/features/topics/topic_detail_screen.dart';

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

Widget _withTextScale(double factor, Widget child) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(factor)),
  child: child,
);

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<void> _settleReal(WidgetTester tester) async {
  await tester.binding.delayed(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void _smallScreen(WidgetTester tester) {
  tester.binding.window.physicalSizeTestValue = const Size(360, 640);
  tester.binding.window.devicePixelRatioTestValue = 1.0;
}

Exception? _exception(WidgetTester tester) => null;

void main() {
  group('TodayScreen — layout overflow', () {
    testWidgets('màn hình nhỏ, dữ liệu bình thường không overflow', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      _smallScreen(tester);

      await _pump(tester, _wrap(services, const TodayScreen()));
      expect(_exception(tester), isNull);

      await _settleReal(tester);
      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });

    testWidgets('cỡ chữ 1,5× không overflow', (WidgetTester tester) async {
      final services = await _buildServices(tester);
      _smallScreen(tester);

      await _pump(
        tester,
        _withTextScale(1.5, _wrap(services, const TodayScreen())),
      );
      expect(_exception(tester), isNull);

      await _settleReal(tester);
      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });

    testWidgets('trạng thái rỗng không overflow', (WidgetTester tester) async {
      final services = await _buildServices(tester);
      _smallScreen(tester);

      await _pump(tester, _wrap(services, const TodayScreen()));
      expect(_exception(tester), isNull);

      await _settleReal(tester);
      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });
  });
}
