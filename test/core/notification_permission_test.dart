import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/app_bootstrap.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/services/preferences_service.dart';
import 'package:mind_keeper/features/profile/notification_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

Future<AppServices> buildServices(FakeNotificationService fake) async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return AppServices.build(
    database: await openMemoryDb(),
    prefs: prefs,
    notifications: fake,
  );
}

Widget buildScreen(AppServices services) {
  return MultiProvider(
    providers: <SingleChildWidget>[
      Provider<AppServices>.value(value: services),
      ChangeNotifierProvider<PreferencesService>.value(value: services.prefs),
    ],
    child: const MaterialApp(home: NotificationSettingsScreen()),
  );
}

void main() {
  group('GĐ15.1 — trạng thái quyền (Fake)', () {
    test('areNotificationsEnabled phản ánh cấu hình true/false/null', () async {
      final FakeNotificationService fake = FakeNotificationService();
      expect(await fake.areNotificationsEnabled(), true);
      fake.notificationsEnabledStatus = false;
      expect(await fake.areNotificationsEnabled(), false);
      fake.notificationsEnabledStatus = null;
      expect(await fake.areNotificationsEnabled(), isNull);
      expect(
        fake.calls.where((String c) => c == 'areNotificationsEnabled'),
        hasLength(3),
      );
    });

    test('openNotificationSettings ghi nhận lệnh gọi', () async {
      final FakeNotificationService fake = FakeNotificationService();
      expect(fake.openSettingsCalled, isFalse);
      expect(await fake.openNotificationSettings(), isTrue);
      expect(fake.openSettingsCalled, isTrue);
      expect(fake.calls, contains('openNotificationSettings'));
    });
  });

  group('GĐ15.1 — payload không hợp lệ', () {
    test('parse payload lạ/rỗng không ném lỗi', () {
      const List<String?> inputs = <String?>[
        null,
        '',
        'card:',
        'CARD:rc_1',
        'card',
        'review',
        'noti:xyz',
        'card::',
      ];
      for (final String? raw in inputs) {
        final NotificationPayload p = NotificationPayload.parse(raw);
        expect(
          p.type,
          anyOf(NotificationPayload.kindCard, NotificationPayload.kindReview),
        );
      }
    });

    test("card: (thiếu id) → review; card:: → id ':' — không crash", () {
      // Payload thiếu cardId rơi về review thay vì mở thẻ rỗng.
      final NotificationPayload empty = NotificationPayload.parse('card:');
      expect(empty.type, NotificationPayload.kindReview);
      expect(empty.cardId, isNull);

      // 'card::' → cardId ':' — hợp lệ theo format, TodayScreen chỉ cần
      // id khác null; ReviewScreen hiển thị "không tồn tại" nếu id lạ.
      final NotificationPayload doubled = NotificationPayload.parse('card::');
      expect(doubled.type, NotificationPayload.kindCard);
      expect(doubled.cardId, ':');
    });
  });

  group('GĐ15.1 — gate lên lịch theo quyền (AppBootstrap)', () {
    late AppServices services;
    late FakeNotificationService fake;

    setUp(() async {
      AppBootstrap.instance.resetForTest();
      fake = FakeNotificationService();
      services = await buildServices(fake);
      await AppBootstrap.instance.initialize(override: services);
    });

    tearDown(() async {
      AppBootstrap.instance.resetForTest();
      await services.dispose();
    });

    test('bị chặn → refreshReminderSchedule KHÔNG lên lịch', () async {
      fake.notificationsEnabledStatus = false;
      await AppBootstrap.instance.refreshReminderSchedule();
      expect(
        fake.calls.where((String c) => c.startsWith('scheduleDailyReminder')),
        isEmpty,
      );
    });

    test('được cấp → refreshReminderSchedule có lên lịch', () async {
      fake.notificationsEnabledStatus = true;
      await AppBootstrap.instance.refreshReminderSchedule();
      expect(
        fake.calls.where((String c) => c.startsWith('scheduleDailyReminder')),
        isNotEmpty,
      );
    });

    test('trạng thái null (nền tảng không đọc được) → vẫn lên lịch', () async {
      fake.notificationsEnabledStatus = null;
      await AppBootstrap.instance.refreshReminderSchedule();
      expect(
        fake.calls.where((String c) => c.startsWith('scheduleDailyReminder')),
        isNotEmpty,
      );
    });
  });

  group('GĐ15.1 — NotificationSettingsScreen widget', () {
    testWidgets('bị từ chối → hiển thị "Bị từ chối" + nút Mở cài đặt', (
      WidgetTester tester,
    ) async {
      final FakeNotificationService fake = FakeNotificationService()
        ..notificationsEnabledStatus = false;
      final AppServices services = (await tester.runAsync(
        () => buildServices(fake),
      ))!;
      await tester.pumpWidget(buildScreen(services));
      await tester.pumpAndSettle();

      expect(find.text('Bị từ chối'), findsOneWidget);
      expect(find.text('Mở cài đặt hệ thống'), findsOneWidget);

      await tester.runAsync(services.dispose);
    });

    testWidgets('đã cấp → "Đã cho phép", không hiện nút Mở cài đặt', (
      WidgetTester tester,
    ) async {
      final FakeNotificationService fake = FakeNotificationService();
      final AppServices services = (await tester.runAsync(
        () => buildServices(fake),
      ))!;
      await tester.pumpWidget(buildScreen(services));
      await tester.pumpAndSettle();

      expect(find.text('Đã cho phép'), findsOneWidget);
      expect(find.text('Mở cài đặt hệ thống'), findsNothing);

      await tester.runAsync(services.dispose);
    });

    testWidgets(
      'bấm Yêu cầu quyền khi bị từ chối → requestPermissions, KHÔNG lên lịch, '
      'trạng thái vẫn "Bị từ chối"',
      (WidgetTester tester) async {
        AppBootstrap.instance.resetForTest();
        final FakeNotificationService fake = FakeNotificationService()
          ..permissionsGranted = false
          ..notificationsEnabledStatus = false;
        final AppServices services = (await tester.runAsync(
          () => buildServices(fake),
        ))!;
        AppBootstrap.instance.resetForTest();
        await AppBootstrap.instance.initialize(override: services);

        await tester.pumpWidget(buildScreen(services));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Yêu cầu quyền thông báo'));
        await tester.pumpAndSettle();

        expect(fake.calls, contains('requestPermissions'));
        expect(
          fake.calls.where((String c) => c.startsWith('scheduleDailyReminder')),
          isEmpty,
          reason: 'Không được lên lịch khi quyền bị từ chối',
        );
        expect(find.text('Bị từ chối'), findsOneWidget);
        expect(
          find.textContaining('Quyền thông báo bị từ chối'),
          findsOneWidget,
        );

        AppBootstrap.instance.resetForTest();
        await tester.runAsync(services.dispose);
      },
    );

    testWidgets(
      'bấm Yêu cầu quyền khi được cấp → requestPermissions + lên lịch nhắc',
      (WidgetTester tester) async {
        AppBootstrap.instance.resetForTest();
        final FakeNotificationService fake = FakeNotificationService()
          ..permissionsGranted = true
          ..notificationsEnabledStatus = true;
        final AppServices services = (await tester.runAsync(
          () => buildServices(fake),
        ))!;
        AppBootstrap.instance.resetForTest();
        await AppBootstrap.instance.initialize(override: services);

        await tester.pumpWidget(buildScreen(services));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Yêu cầu quyền thông báo'));
        await tester.pumpAndSettle();

        expect(fake.calls, contains('requestPermissions'));
        expect(
          fake.calls.where((String c) => c.startsWith('scheduleDailyReminder')),
          isNotEmpty,
          reason: 'Được cấp quyền → lịch nhắc hằng ngày được lập',
        );
        expect(find.text('Đã cho phép'), findsOneWidget);

        AppBootstrap.instance.resetForTest();
        await tester.runAsync(services.dispose);
      },
    );

    testWidgets('tắt switch nhắc ôn → cancelAll, không còn lịch', (
      WidgetTester tester,
    ) async {
      final FakeNotificationService fake = FakeNotificationService();
      final AppServices services = (await tester.runAsync(
        () => buildServices(fake),
      ))!;
      await tester.pumpWidget(buildScreen(services));
      await tester.pumpAndSettle();

      // prefs.notificationsEnabled mặc định true → switch nhắc ôn đang bật.
      final Finder reviewSwitch = find
          .ancestor(
            of: find.text('Bật thông báo nhắc ôn'),
            matching: find.byType(SwitchListTile),
          )
          .first;
      expect(tester.widget<SwitchListTile>(reviewSwitch).value, isTrue);
      await tester.tap(reviewSwitch);
      await tester.pumpAndSettle();

      expect(fake.calls, contains('cancelDailyReminder'));
      expect(services.prefs.notificationsEnabled, isFalse);
      expect(tester.widget<SwitchListTile>(reviewSwitch).value, isFalse);

      await tester.runAsync(services.dispose);
    });
  });
}
