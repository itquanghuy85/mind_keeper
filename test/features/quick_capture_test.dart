import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/services/share_intake.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/data/models/source.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:mind_keeper/features/capture/quick_capture_screen.dart';
import 'package:mind_keeper/features/capture/quick_capture_service.dart';
import 'package:mind_keeper/features/import/link_import_screen.dart';
import 'package:mind_keeper/features/import/text_import_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<AppServices> _build() async {
  sqfliteFfiInit();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences sp = await SharedPreferences.getInstance();
  final AppDatabase app = AppDatabase(
    factory: databaseFactoryFfi,
    name: inMemoryDatabasePath,
  );
  await app.open();
  return AppServices.build(
    database: app,
    prefs: sp,
    notifications: FakeNotificationService(),
  );
}

QuickCaptureService _service(AppServices s) => QuickCaptureService(
  topics: s.topics,
  knowledge: s.knowledge,
  cards: s.cards,
  sources: s.sources,
);

const SharedPayload _link = SharedPayload(
  text: 'Bài hay về giấc ngủ https://example.com/giac-ngu?id=7.',
  subject: 'Giấc ngủ và trí nhớ',
);
const SharedPayload _plain = SharedPayload(
  text: 'Ti thể là nhà máy năng lượng của tế bào.\nNó có DNA riêng.',
);

void main() {
  group('SharedPayload', () {
    test('tách link, bỏ dấu câu dính cuối; phân biệt link thuần / văn bản', () {
      expect(_link.url, 'https://example.com/giac-ngu?id=7');
      expect(_plain.url, isNull);
      expect(
        const SharedPayload(text: 'https://a.b/c').isLink,
        isTrue,
        reason: 'chỉ có link',
      );
      expect(
        const SharedPayload(
          text: 'Đoạn mô tả rất dài về một bài viết thú vị https://a.b/c',
        ).isLink,
        isFalse,
        reason: 'nhiều chữ → coi là văn bản có kèm link',
      );
      expect(
        SharedPayload.fromMap(<Object?, Object?>{
          'text': ' xin chào ',
          'subject': null,
        }),
        const SharedPayload(text: 'xin chào'),
      );
    });

    test(
      'ShareIntake giữ payload chờ đến khi có listener; listener nhận trực tiếp',
      () {
        final ShareIntake intake = ShareIntake.instance;
        intake.setListener(null);
        intake.pending = null;
        intake.deliver(const SharedPayload(text: 'a'));
        expect(intake.pending?.text, 'a', reason: 'chưa có listener → chờ');
        final List<String> got = <String>[];
        intake.setListener((SharedPayload p) => got.add(p.text));
        expect(got, <String>['a'], reason: 'giao ngay khi đăng ký');
        expect(intake.pending, isNull);
        intake.deliver(const SharedPayload(text: 'b'));
        intake.deliver(const SharedPayload(text: '  '));
        expect(got, <String>['a', 'b'], reason: 'warm start; rỗng bị bỏ');
        intake.setListener(null);
      },
    );
  });

  group('QuickCaptureService', () {
    test('suggestTitle: subject → dòng đầu (bỏ URL) → tên miền', () {
      expect(QuickCaptureService.suggestTitle(_link), 'Giấc ngủ và trí nhớ');
      expect(
        QuickCaptureService.suggestTitle(_plain),
        'Ti thể là nhà máy năng lượng của tế bào.',
      );
      expect(
        QuickCaptureService.suggestTitle(
          const SharedPayload(text: 'https://www.example.com/x'),
        ),
        'Liên kết từ example.com',
      );
    });

    test(
      'lưu nhanh văn bản: tự tạo "Hộp thư đến", kiến thức + thẻ due ngay',
      () async {
        final AppServices s = await _build();
        expect(
          await s.topics.findByName(QuickCaptureService.inboxName),
          isNull,
        );
        final QuickCaptureResult r = await _service(s).save(payload: _plain);

        expect(r.duplicate, isFalse);
        expect(r.topic.name, QuickCaptureService.inboxName);
        expect(
          await s.topics.findByName(QuickCaptureService.inboxName),
          isNotNull,
        );
        final KnowledgeItem item = r.item!;
        expect(item.content, contains('Ti thể'));
        expect(item.sourceId, isNull);
        final List<ReviewCard> cards = await s.cards.listAllByKnowledgeItem(
          item.id,
        );
        expect(cards, hasLength(1));
        expect(
          cards.single.dueAt.isAfter(
            DateTime.now().add(const Duration(minutes: 1)),
          ),
          isFalse,
          reason: 'due ngay',
        );
        await s.dispose();
      },
    );

    test(
      'lưu nhanh link: lưu Source link với reference_url và gắn vào kiến thức',
      () async {
        final AppServices s = await _build();
        final QuickCaptureResult r = await _service(s).save(payload: _link);
        final KnowledgeItem item = r.item!;
        expect(item.title, 'Giấc ngủ và trí nhớ');
        expect(item.sourceId, isNotNull);
        final List<Source> sources = await s.sources.listByTopic(r.topic.id);
        expect(sources, hasLength(1));
        expect(sources.single.type, SourceType.link);
        expect(
          sources.single.referenceUrl,
          'https://example.com/giac-ngu?id=7',
        );
        expect(sources.single.id, item.sourceId);
        await s.dispose();
      },
    );

    test('chống trùng: cùng nội dung hoặc cùng link → không tạo thêm', () async {
      final AppServices s = await _build();
      final QuickCaptureService svc = _service(s);
      await svc.save(payload: _plain);
      final QuickCaptureResult again = await svc.save(payload: _plain);
      expect(again.duplicate, isTrue);

      await svc.save(payload: _link);
      final QuickCaptureResult linkAgain = await svc.save(
        payload: const SharedPayload(
          text:
              'Nội dung khác nhưng cùng link https://example.com/giac-ngu?id=7',
        ),
      );
      expect(linkAgain.duplicate, isTrue);

      final Topic inbox = (await s.topics.findByName(
        QuickCaptureService.inboxName,
      ))!;
      expect(await s.knowledge.listByTopic(inbox.id), hasLength(2));
      expect(await s.sources.listByTopic(inbox.id), hasLength(1));
      await s.dispose();
    });

    test('lưu vào chủ đề đã chọn thay vì Hộp thư đến', () async {
      final AppServices s = await _build();
      final Topic topic = await s.topics.create(name: 'Sinh học');
      final QuickCaptureResult r = await _service(
        s,
      ).save(payload: _plain, topicId: topic.id);
      expect(r.topic.id, topic.id);
      expect(await s.topics.findByName(QuickCaptureService.inboxName), isNull);
      await s.dispose();
    });
  });

  group('QuickCaptureScreen', () {
    Future<void> settle(WidgetTester tester) async {
      for (int i = 0; i < 2; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Future<void> open(
      WidgetTester tester,
      AppServices services,
      SharedPayload payload,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Provider<AppServices>.value(
          value: services,
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuickCaptureScreen(payload: payload),
                      ),
                    ),
                    child: const Text('mở'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('mở'));
      await settle(tester);
    }

    testWidgets('Lưu nhanh: tạo kiến thức + thẻ, báo kết quả, đóng màn', (
      WidgetTester tester,
    ) async {
      final AppServices s = (await tester.runAsync(_build))!;
      await open(tester, s, _link);
      expect(find.text('Lưu nhanh'), findsWidgets);
      expect(
        find.text('Tóm tắt bằng AI'),
        findsNothing,
        reason: 'AI chưa cấu hình',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu nhanh').first);
      await settle(tester);

      expect(find.textContaining('Đã lưu vào "Hộp thư đến"'), findsOneWidget);
      expect(find.byType(QuickCaptureScreen), findsNothing);
      final Topic? inbox = await tester.runAsync<Topic?>(
        () => s.topics.findByName(QuickCaptureService.inboxName),
      );
      expect(inbox, isNotNull);
      final List<KnowledgeItem>? items = await tester
          .runAsync<List<KnowledgeItem>>(
            () => s.knowledge.listByTopic(inbox!.id),
          );
      expect(items, hasLength(1));
      await tester.runAsync(s.dispose);
    });

    testWidgets('Hộp thư đến đã tồn tại: màn vẫn dựng được và lưu vào đó', (
      WidgetTester tester,
    ) async {
      final AppServices s = (await tester.runAsync(_build))!;
      await tester.runAsync(() => _service(s).ensureInbox());
      await tester.runAsync(() => s.topics.create(name: 'Sinh học'));
      await open(tester, s, _plain);
      expect(tester.takeException(), isNull);
      expect(find.text('Hộp thư đến'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu nhanh').first);
      await settle(tester);
      expect(find.textContaining('Đã lưu vào "Hộp thư đến"'), findsOneWidget);
      await tester.runAsync(s.dispose);
    });

    testWidgets('Mở đầy đủ: link → LinkImportScreen điền sẵn URL', (
      WidgetTester tester,
    ) async {
      final AppServices s = (await tester.runAsync(_build))!;
      await open(tester, s, const SharedPayload(text: 'https://example.com/a'));
      await tester.tap(find.text('Mở đầy đủ'));
      await settle(tester);
      expect(find.byType(LinkImportScreen), findsOneWidget);
      expect(find.text('https://example.com/a'), findsWidgets);
      await tester.runAsync(s.dispose);
    });

    testWidgets('Mở đầy đủ: văn bản → TextImportScreen điền sẵn nội dung', (
      WidgetTester tester,
    ) async {
      final AppServices s = (await tester.runAsync(_build))!;
      await open(tester, s, _plain);
      await tester.tap(find.text('Mở đầy đủ'));
      await settle(tester);
      expect(find.byType(TextImportScreen), findsOneWidget);
      expect(find.textContaining('Ti thể là nhà máy năng lượng'), findsWidgets);
      await tester.runAsync(s.dispose);
    });
  });
}
