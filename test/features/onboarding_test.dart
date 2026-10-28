import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/app.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:mind_keeper/features/discover/discovery_catalog.dart';
import 'package:mind_keeper/features/onboarding/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<({AppServices services, FakeNotificationService fake})> _build({
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  sqfliteFfiInit();
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences sp = await SharedPreferences.getInstance();
  final AppDatabase app = AppDatabase(
    factory: databaseFactoryFfi,
    name: inMemoryDatabasePath,
  );
  await app.open();
  final FakeNotificationService fake = FakeNotificationService();
  return (
    services: AppServices.build(database: app, prefs: sp, notifications: fake),
    fake: fake,
  );
}

OnboardingService _service(AppServices s) =>
    OnboardingService(topics: s.topics, discovery: s.discovery, prefs: s.prefs);

void main() {
  group('OnboardingService', () {
    test('cài mới: cần onboarding; đã hoàn tất: không', () async {
      final r = await _build();
      expect(await _service(r.services).shouldShow(), isTrue);
      await r.services.prefs.setOnboardingCompleted(true);
      expect(await _service(r.services).shouldShow(), isFalse);
    });

    test(
      'người dùng cũ (DB có dữ liệu): không chặn, tự đánh dấu hoàn tất',
      () async {
        final r = await _build();
        await r.services.topics.create(name: 'Chủ đề cũ');
        expect(r.services.prefs.onboardingCompleted, isFalse);
        expect(await _service(r.services).shouldShow(), isFalse);
        expect(r.services.prefs.onboardingCompleted, isTrue);
      },
    );

    test(
      'seedFor: mỗi chủ đề 1 entry offline + kiến thức + thẻ due ngay',
      () async {
        final r = await _build();
        final List<Topic> created = await _service(
          r.services,
        ).seedFor(<String>['Khoa học', 'Lịch sử']);
        expect(created, hasLength(2));
        for (final Topic t in created) {
          expect(t.description, startsWith('catalog:'));
          final List<KnowledgeItem> items = await r.services.knowledge
              .listByTopic(t.id);
          expect(items, isNotEmpty);
          final List<ReviewCard> cards = await r.services.cards
              .listAllByKnowledgeItem(items.first.id);
          expect(cards, isNotEmpty);
          expect(
            cards.first.dueAt.isAfter(
              DateTime.now().add(const Duration(minutes: 1)),
            ),
            isFalse,
            reason: 'thẻ mẫu phải due ngay',
          );
        }
      },
    );

    test('gọi lại không nhân bản; tối đa 3 chủ đề; bỏ qua chủ đề lạ', () async {
      final r = await _build();
      final OnboardingService s = _service(r.services);
      await s.seedFor(<String>['Khoa học']);
      final List<Topic> again = await s.seedFor(<String>[
        'Khoa học',
        'Không có',
      ]);
      expect(again, hasLength(1), reason: 'entry kế tiếp của Khoa học');
      final List<Topic> all = await r.services.topics.list(activeOnly: false);
      expect(
        all.map((Topic t) => t.description).toSet(),
        hasLength(all.length),
        reason: 'mỗi entry catalog chỉ lưu một lần',
      );
      final List<Topic> many = await _service(
        (await _build()).services,
      ).seedFor(DiscoveryCatalog.categories);
      expect(many.length, lessThanOrEqualTo(OnboardingService.maxCategories));
    });

    test('savePreferences lưu cấp độ, giờ nhắc, cờ thông báo', () async {
      final r = await _build();
      await _service(r.services).savePreferences(
        courseLevelId: 'pro',
        reminderHour: 6,
        reminderMinute: 30,
        notificationsEnabled: false,
      );
      expect(r.services.prefs.defaultCourseLevel, 'pro');
      expect(r.services.prefs.reminderHour, 6);
      expect(r.services.prefs.reminderMinute, 30);
      expect(r.services.prefs.notificationsEnabled, isFalse);
    });
  });

  group('HomeGate + OnboardingScreen', () {
    Future<void> pumpApp(WidgetTester tester, AppServices services) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MindKeeperApp(services: services, showSplash: false),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
    }

    Future<void> settle(WidgetTester tester) async {
      // Hai vòng: (1) ghi DB của onboarding, (2) AppShell mới mount tải dữ liệu
      // các tab bằng DB thật (ngoài FakeAsync).
      for (int i = 0; i < 2; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    testWidgets('cài mới → onboarding; chọn 2 chủ đề → Xong → có dữ liệu mẫu', (
      WidgetTester tester,
    ) async {
      final r = (await tester.runAsync(_build))!;
      await pumpApp(tester, r.services);
      expect(find.text('Bắt đầu'), findsOneWidget);

      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      // Chưa đủ 2 chủ đề → nút tiếp tục bị khóa.
      expect(find.text('Chọn 2–3 chủ đề'), findsOneWidget);
      await tester.tap(find.text('Khoa học'));
      await tester.tap(find.text('Lịch sử'));
      await tester.tap(find.text('Nâng cao'));
      await tester.pump();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      expect(find.text('Nhắc học mỗi ngày'), findsOneWidget);
      await tester.tap(find.text('Xong'));
      await settle(tester);

      expect(r.services.prefs.onboardingCompleted, isTrue);
      expect(r.services.prefs.defaultCourseLevel, 'advanced');
      expect(r.services.prefs.notificationsEnabled, isTrue);
      expect(r.fake.calls, contains('requestPermissions'));
      final List<Topic>? topics = await tester.runAsync(
        () => r.services.topics.list(activeOnly: false),
      );
      expect(topics, hasLength(2));
      expect(find.textContaining('Bước '), findsNothing, reason: 'đã vào app');
      await tester.runAsync(r.services.dispose);
    });

    testWidgets('thiếu quyền thông báo: không chặn, tắt cờ, báo rõ', (
      WidgetTester tester,
    ) async {
      final r = (await tester.runAsync(_build))!;
      r.fake.permissionsGranted = false;
      await pumpApp(tester, r.services);
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      await tester.tap(find.text('Khoa học'));
      await tester.tap(find.text('Đời sống'));
      await tester.pump();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      await tester.tap(find.text('Cho phép thông báo'));
      await settle(tester);
      expect(find.textContaining('chưa được cấp'), findsOneWidget);
      await tester.tap(find.text('Xong'));
      await settle(tester);

      expect(
        r.services.prefs.onboardingCompleted,
        isTrue,
        reason: 'không bị chặn',
      );
      expect(r.services.prefs.notificationsEnabled, isFalse);
      expect(find.textContaining('Bước '), findsNothing);
      await tester.runAsync(r.services.dispose);
    });

    testWidgets('Bỏ qua: hoàn tất, không tạo dữ liệu', (
      WidgetTester tester,
    ) async {
      final r = (await tester.runAsync(_build))!;
      await pumpApp(tester, r.services);
      await tester.tap(find.text('Bỏ qua'));
      await settle(tester);
      expect(r.services.prefs.onboardingCompleted, isTrue);
      final List<Topic>? topics = await tester.runAsync(
        () => r.services.topics.list(activeOnly: false),
      );
      expect(topics, isEmpty);
      expect(find.textContaining('Bước '), findsNothing);
      await tester.runAsync(r.services.dispose);
    });

    testWidgets(
      'người dùng cũ (đã có dữ liệu) vào thẳng app, không onboarding',
      (WidgetTester tester) async {
        final r = (await tester.runAsync(_build))!;
        await tester.runAsync(() => r.services.topics.create(name: 'Cũ'));
        await pumpApp(tester, r.services);
        await settle(tester);
        expect(find.textContaining('Bước '), findsNothing);
        expect(r.services.prefs.onboardingCompleted, isTrue);
        await tester.runAsync(r.services.dispose);
      },
    );
  });
}
