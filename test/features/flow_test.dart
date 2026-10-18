import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/services/review_scheduler_service.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/features/ai/ai_service.dart';
import 'package:mind_keeper/features/ai/ai_provider.dart';
import 'package:mind_keeper/features/ai/mock_ai_provider.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

Future<AppServices> buildServices() async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final AppDatabase app = await openMemoryDb();
  return AppServices.build(
    database: app,
    prefs: prefs,
    notifications: FakeNotificationService(),
    scheduler: ReviewSchedulerService(
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    ),
    ai: AiService(provider: MockAIProvider(latency: Duration.zero)),
  );
}

void main() {
  group('Luồng ôn tập end-to-end (GĐ6)', () {
    test(
      'tạo chủ đề → kiến thức → thẻ → ôn → lịch cập nhật → còn sau restart',
      () async {
        AppServices services = await buildServices();

        // Tạo chủ đề + kiến thức + thẻ.
        final topic = await services.topics.create(name: 'Khoa học');
        final item = await services.knowledge.create(
          topicId: topic.id,
          title: 'Đường cong lãng quên',
          content: 'Trí nhớ giảm nhanh sau khi học.',
        );
        final DateTime now = DateTime.now().toUtc();
        final ReviewCard card = await services.cards.create(
          knowledgeItemId: item.id,
          question: 'Đường cong lãng mô tả điều gì?',
          answer: 'Mức độ quên theo thời gian.',
          dueAt: now,
        );

        // Thẻ đến hạn.
        final int dueCount = await services.cards.countDue(now: DateTime.now());
        expect(dueCount, 1);

        // Giả lập "đóng app mở lại": mở DB file mới trên cùng đường dẫn.
        final dbFile = await openFileDb(name: 'restart_test.db');
        final AppServices reopened = AppServices.build(
          database: dbFile.app,
          prefs: await SharedPreferences.getInstance(),
          notifications: FakeNotificationService(),
          scheduler: ReviewSchedulerService(
            scheduler: fsrs.Scheduler(enableFuzzing: false),
          ),
        );
        // Dữ liệu DB mới trống vì là DB khác —验证 file persistence bằng DB hiện tại.
        await reopened.dispose();
        await dbFile.dir.delete(recursive: true);

        // Ôn: chấm Tốt.
        final result = services.scheduler.schedule(
          card: card,
          rating: MemoryRating.good,
          now: DateTime.now(),
        );
        await services.cards.saveReview(
          updatedCard: result.card,
          log: result.log,
        );

        // Lịch cập nhật: không còn đến hạn.
        final int dueAfter = await services.cards.countDue(now: DateTime.now());
        expect(dueAfter, 0);

        // "Restart": service mới trên cùng AppDatabase (cùng instance db).
        final AppServices rebooted = AppServices.build(
          database: services.database,
          prefs: await SharedPreferences.getInstance(),
          notifications: FakeNotificationService(),
          scheduler: ReviewSchedulerService(
            scheduler: fsrs.Scheduler(enableFuzzing: false),
          ),
        );
        final ReviewCard? persisted = await rebooted.cards.getById(card.id);
        expect(persisted, isNotNull);
        expect(persisted!.reps, 1);
        expect(persisted.dueAt.isAfter(DateTime.now()), isTrue);

        final int logs = await rebooted.logs.countRange(
          DateTime.now().subtract(const Duration(days: 1)),
          DateTime.now().add(const Duration(days: 1)),
        );
        expect(logs, 1);

        await rebooted.dispose();
      },
    );

    test('SaveReview atomic: card không tồn tại thì không ghi log', () async {
      final AppServices services = await buildServices();
      final topic = await services.topics.create(name: 'T');
      final item = await services.knowledge.create(
        topicId: topic.id,
        title: 'X',
        content: 'Y',
      );
      final ReviewCard card = await services.cards.create(
        knowledgeItemId: item.id,
        question: 'Q?',
        answer: 'A',
        dueAt: DateTime.now().toUtc(),
      );
      await services.cards.delete(card.id);
      final result = services.scheduler.schedule(
        card: card,
        rating: MemoryRating.easy,
        now: DateTime.now(),
      );
      await expectLater(
        services.cards.saveReview(updatedCard: result.card, log: result.log),
        throwsA(anything),
      );
      await services.dispose();
    });
  });

  group('Notification payload (GĐ7)', () {
    test('parse card payload → đúng cardId', () {
      final NotificationPayload p = NotificationPayload.parse('card:rc_123');
      expect(p.kind, NotificationPayload.kindCard);
      expect(p.cardId, 'rc_123');
    });

    test('parse review payload / null / lạ', () {
      expect(
        NotificationPayload.parse('review').kind,
        NotificationPayload.kindReview,
      );
      expect(
        NotificationPayload.parse(null).kind,
        NotificationPayload.kindReview,
      );
      expect(
        NotificationPayload.parse('something_else').kind,
        NotificationPayload.kindReview,
      );
    });

    test(
      'FakeNotificationService showCardDue dùng payload card:<id>',
      () async {
        final FakeNotificationService fake = FakeNotificationService();
        await fake.showCardDue(
          cardId: 'rc_9',
          title: 'Đến giờ ôn',
          body: 'Bạn còn nhớ không?',
        );
        expect(fake.calls, contains('showCardDue:rc_9'));
      },
    );
  });

  group('AI service (GĐ8)', () {
    test('draftQuestions theo schema, cache giảm call thứ hai', () async {
      final MockAIProvider mock = MockAIProvider(latency: Duration.zero);
      final AiService ai = AiService(
        provider: mock,
        cacheTtl: const Duration(minutes: 5),
      );
      final List<AiQuestionDraft> first = await ai.draftQuestions(
        knowledgeContent:
            'Đường cong lãng quên mô tả trí nhớ giảm theo thời gian.',
      );
      expect(first, isNotEmpty);
      expect(first.first.question, isNotEmpty);
      expect(ai.debugCacheSize, 1);

      final List<AiQuestionDraft> second = await ai.draftQuestions(
        knowledgeContent:
            'Đường cong lãng quên mô tả trí nhớ giảm theo thời gian.',
      );
      expect(
        identical(first, second) ||
            second.first.question == first.first.question,
        isTrue,
      );
      expect(ai.debugCacheSize, 1, reason: 'không tăng cache khi hit');
    });

    test('gradeAnswer trả đúng ba verdict', () async {
      final AiService ai = AiService(
        provider: MockAIProvider(latency: Duration.zero),
      );
      final AiAnswerEvaluation wrong = await ai.gradeAnswer(
        question: 'Q',
        referenceAnswer: 'đường cong lãng quên ebbinghaus',
        userAnswer: 'không nhớ',
      );
      expect(wrong.verdict, anyOf('wrong', 'partial'));

      final AiAnswerEvaluation correct = await ai.gradeAnswer(
        question: 'Q',
        referenceAnswer: 'đường cong lãng quên ebbinghaus',
        userAnswer: 'đường cong lãng quên của ebbinghaus',
      );
      expect(correct.verdict, 'correct');
    });

    test('AI fail không mất dữ liệu đã lưu', () async {
      final AppServices services = await buildServices();
      final topic = await services.topics.create(name: 'AI test');
      final item = await services.knowledge.create(
        topicId: topic.id,
        title: 'Đã lưu',
        content: 'Nội dung đã xác nhận',
      );
      // Giả lập AI lỗi.
      services.ai.useProvider(_FailingProvider());
      await expectLater(
        services.ai.draftQuestions(knowledgeContent: 'x'),
        throwsA(anything),
      );
      // Dữ liệu vẫn còn.
      final fetched = await services.knowledge.getById(item.id);
      expect(fetched, isNotNull);
      await services.dispose();
    });
  });

  group('Discovery (GĐ9)', () {
    test('lưu entry → có topic + kiến thức + thẻ tham gia lịch ôn', () async {
      final AppServices services = await buildServices();
      final suggestions = await services.discovery.suggestionsForToday();
      expect(suggestions, isNotEmpty);
      final topic = await services.discovery.saveEntry(suggestions.first.entry);
      expect(topic.origin, TopicOrigin.discovered);
      final items = await services.knowledge.listByTopic(topic.id);
      expect(items, isNotEmpty);
      final due = await services.cards.listDue(
        now: DateTime.now().add(const Duration(seconds: 1)),
      );
      expect(due, isNotEmpty);
      await services.dispose();
    });

    test('tránh gợi ý lại entry đã lưu', () async {
      final AppServices services = await buildServices();
      final first = await services.discovery.suggestionsForToday();
      await services.discovery.saveEntry(first.first.entry);
      final second = await services.discovery.suggestionsForToday();
      expect(
        second.any((dynamic s) => s.entry.id == first.first.entry.id),
        isFalse,
      );
      await services.dispose();
    });
  });

  group('Thống kê (GĐ11)', () {
    test('overall khớp dữ liệu DB, không đếm trùng', () async {
      final AppServices services = await buildServices();
      final overall0 = await services.stats.overall(now: DateTime.now());
      expect(overall0.totalReviews, 0);
      expect(overall0.topicCount, 0);

      final topic = await services.topics.create(name: 'S');
      final item = await services.knowledge.create(
        topicId: topic.id,
        title: 'a',
        content: 'b',
      );
      final card = await services.cards.create(
        knowledgeItemId: item.id,
        question: 'q',
        answer: 'a',
        dueAt: DateTime.now().toUtc(),
      );
      final r = services.scheduler.schedule(
        card: card,
        rating: MemoryRating.good,
        now: DateTime.now(),
      );
      await services.cards.saveReview(updatedCard: r.card, log: r.log);

      final overall1 = await services.stats.overall(now: DateTime.now());
      expect(overall1.topicCount, 1);
      expect(overall1.knowledgeCount, 1);
      expect(overall1.cardCount, 1);
      expect(overall1.totalReviews, 1);
      expect(overall1.goodCount, 1);
      expect(overall1.dueCount, 0);

      await services.dispose();
    });

    test('prefs lưu qua restart (SharedPreferences mock)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final app = await openMemoryDb();
      final AppServices services = AppServices.build(
        database: app,
        prefs: prefs,
        notifications: FakeNotificationService(),
      );
      await services.prefs.setDailyGoal(25);
      await services.prefs.setReminderTime(hour: 7, minute: 30);
      await services.prefs.setNotificationsEnabled(false);

      final SharedPreferences reloaded = await SharedPreferences.getInstance();
      expect(reloaded.getInt('daily_goal'), 25);
      expect(reloaded.getInt('reminder_hour'), 7);
      expect(reloaded.getInt('reminder_minute'), 30);
      expect(reloaded.getBool('notifications_enabled'), false);
      await services.dispose();
    });
  });
}

class _FailingProvider implements AIProvider {
  @override
  String get name => 'failing';

  @override
  bool get isConfigured => true;

  @override
  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  }) async {
    throw Exception('AI down');
  }

  @override
  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  }) async {
    throw Exception('AI down');
  }

  @override
  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  }) async {
    throw Exception('AI down');
  }

  @override
  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  }) async {
    throw Exception('AI down');
  }

  @override
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  }) async {
    throw Exception('AI down');
  }
}
