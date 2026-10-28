import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/study_feed_item.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:mind_keeper/data/repositories/study_feed_repository.dart';
import 'package:mind_keeper/features/ai/ai_provider.dart';
import 'package:mind_keeper/features/study/study_plan_service.dart';

import '../helpers/test_db.dart';

/// Fake AI provider trả nội dung hợp lệ, không cần mạng, không cache.
class _FakeAiProvider implements AIProvider {
  @override
  String get name => 'test_fake';

  @override
  bool get isConfigured => true;

  /// 5 draft với nội dung KHÁC NHAU từng mẫu (findSimilar so sánh chuẩn hóa
  /// exact) — cho phép tạo nhiều thông tin nhanh cùng một chủ đề.
  @override
  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  }) async {
    if (sourceText.trim().isEmpty) return const <AiKnowledgeDraft>[];
    final int n = maxItems < 5 ? maxItems : 5;
    return <AiKnowledgeDraft>[
      for (int i = 0; i < n; i++)
        AiKnowledgeDraft(
          title: 'Thông tin nhanh ${i + 1}: $sourceText',
          // Độ dài ≥ 40 ký tự (điều kiện của StudyPlanService._createQuick).
          content:
              'Mẫu ${i + 1}. '
              'Nội dung giải thích chi tiết mở rộng cho người học. '
              '$sourceText',
          details: 'Chi tiết mẫu ${i + 1}',
        ),
    ];
  }

  @override
  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  }) async => const <AiQuestionDraft>[];

  @override
  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  }) async => const AiTutorExplanation(explanation: 'Giải thích mẫu.');

  @override
  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  }) async => AiAnswerEvaluation(verdict: 'correct', comment: '');

  /// wordCount phải ≥ 80 (điều kiện của StudyPlanService._generateLesson).
  @override
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  }) async {
    final String body =
        'Nội dung mở rộng chi tiết về $topic và các ví dụ thực tế '
        'minh họa trực quan cho người học. ' * 8;
    return AiLessonDraft(
      title: 'Bài: $topic',
      learningObjectives: <String>['Hiểu về $topic'],
      introduction: 'Giới thiệu về $topic. $body',
      concepts: const <AiLessonConcept>[],
      sections: <AiLessonSection>[
        AiLessonSection(heading: 'Phần 1: Tổng quan', body: body),
      ],
      keyPoints: const <String>[],
      examples: const <String>[],
      commonMistakes: const <String>[],
      summary: 'Tóm tắt về $topic. $body',
      questions: <AiQuestionDraft>[
        AiQuestionDraft(
          question: 'Câu hỏi 1 về $topic?',
          answer: 'Đáp án mẫu cho $topic.',
        ),
      ],
      sources: const <AiLessonSource>[],
      medical: false,
    );
  }

  @override
  Future<List<AiTopicSuggestion>> suggestTopics({
    required String domain,
    int count = 20,
  }) async => const <AiTopicSuggestion>[];
}

/// Tạo StudyPlanService test từ AppServices có sẵn (cùng DB/prefs/fake).
StudyPlanService _planOf(
  AppServices services, {
  required bool allowMockContent,
}) =>
    StudyPlanService(
      prefs: services.prefs,
      feed: StudyFeedRepository(services.database),
      topics: services.topics,
      knowledge: services.knowledge,
      lessons: services.lessons,
      ai: services.ai,
      notifications: services.notifications,
      allowMockContent: allowMockContent,
    );

Future<({AppServices services, StudyPlanService plan})> _buildServices({
  bool allowMockContent = true,
  int quickPerDay = 2,
  int lessonPerDay = 1,
  bool notificationsEnabled = true,
}) async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final FakeNotificationService fake = FakeNotificationService()
    ..notificationsEnabledStatus = notificationsEnabled;
  final AppServices services = AppServices.build(
    database: await openMemoryDb(),
    prefs: prefs,
    notifications: fake,
  );
  services.ai.useProvider(_FakeAiProvider());
  await services.prefs.setStudyPlanQuickPerDay(quickPerDay);
  await services.prefs.setStudyPlanLessonPerDay(lessonPerDay);
  await services.prefs.setStudyPlanPaused(false);
  await services.prefs.setStudyPlanNewContentNotifications(
    notificationsEnabled,
  );
  final StudyPlanService plan = _planOf(
    services,
    allowMockContent: allowMockContent,
  );
  return (services: services, plan: plan);
}

Future<Topic> _seedTopic(
  AppServices services, {
  required String name,
  String category = 'Khoa học',
}) =>
    services.topics.create(
      name: name,
      category: category,
      icon: '',
      origin: TopicOrigin.personal,
    );

/// "Sáng sớm" hôm nay — mọi khung giờ 08:00–20:00 đều thuộc tương lai
/// theo base của sync để mọi dòng được sinh nội dung (không phụ thuộc giờ thật).
DateTime _earlyToday() {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 5, 0);
}

void main() {
  group('StudyPlanService — lập lịch bài mới (GĐ17)', () {
    test('sync tạo rows theo quota quick + lesson, sinh nội dung xong', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 2,
        lessonPerDay: 1,
        notificationsEnabled: false,
      );
      await _seedTopic(services, name: 'Nguyên tử và phân tử');
      await _seedTopic(services, name: 'Thuyết tiến hóa');
      await _seedTopic(services, name: 'Vũ trụ và các thiên hà');

      final DateTime base = _earlyToday();
      final StudyPlanSyncResult result = await plan.sync(now: base);
      expect(result.paused, isFalse);
      expect(result.planned, greaterThan(0));

      final String todayKey = studyDayKey(base);
      final List<StudyFeedItem> today =
          await StudyFeedRepository(services.database).listActiveRange(
            todayKey,
            todayKey,
          );
      expect(today.where((StudyFeedItem r) => r.kind == StudyFeedKind.quick).length, 2);
      expect(today.where((StudyFeedItem r) => r.kind == StudyFeedKind.lesson).length, 1);
      for (final StudyFeedItem r in today) {
        expect(r.status, StudyFeedStatus.ready,
            reason: 'base 05:00 < mọi khung giờ → đã sinh xong');
        expect(r.refId, isNotNull, reason: 'nội dung phải lưu xuống SQLite');
      }
      await services.dispose();
    });

    test('quota 0 không tạo row nào', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 0,
        lessonPerDay: 0,
      );
      await _seedTopic(services, name: 'Chủ đề duy nhất');

      final DateTime base = _earlyToday();
      await plan.sync(now: base);

      final List<StudyFeedItem> rows =
          await StudyFeedRepository(services.database).listActiveRange(
            studyDayKey(base),
            studyDayKey(base),
          );
      expect(rows, isEmpty);
      await services.dispose();
    });

    test('con trỏ luân phiên lưu bền vững qua restart', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 1,
        lessonPerDay: 0,
        allowMockContent: false,
      );
      await _seedTopic(services, name: 'A');
      await _seedTopic(services, name: 'B');
      await _seedTopic(services, name: 'C');

      // Prefetch 3 ngày → 4 ngày × 1 khung quick → 4 lần _nextTopic.
      final DateTime base = _earlyToday();
      await plan.sync(now: base);
      expect(services.prefs.studyPlanRotation, 4);

      // "Restart": plan instance MỚI đọc cùng SharedPreferences.
      await services.prefs.setStudyPlanQuickPerDay(2);
      final StudyPlanService restarted = _planOf(
        services,
        allowMockContent: false,
      );
      await restarted.sync(now: base);
      // Tăng quota → thêm khung slot1 cho 4 ngày → con trỏ tiếp tục từ 4.
      expect(services.prefs.studyPlanRotation, 8);
      await services.dispose();
    });

    test('sync idempotent: chạy lại không tạo trùng rows cùng ngày/slot', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 1,
        lessonPerDay: 0,
        allowMockContent: false,
      );
      await _seedTopic(services, name: 'T1');

      final DateTime base = _earlyToday();
      final String todayKey = studyDayKey(base);
      await plan.sync(now: base);
      final int count1 = await StudyFeedRepository(services.database)
          .countActive(todayKey, StudyFeedKind.quick);
      await plan.sync(now: base);
      final int count2 = await StudyFeedRepository(services.database)
          .countActive(todayKey, StudyFeedKind.quick);
      expect(count1, 1);
      expect(count2, count1);
      await services.dispose();
    });

    test('notification ID âm và ổn định, không trùng giữa quick và lesson', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 1,
        lessonPerDay: 1,
        notificationsEnabled: true,
      );
      await _seedTopic(services, name: 'N1');

      // Ngày mai/lần lượt luôn ở tương lai → nội dung sinh + lên lịch được.
      await plan.sync();
      await plan.sync();

      final FakeNotificationService fake =
          services.notifications as FakeNotificationService;
      expect(fake.scheduledContent, isNotEmpty);

      for (final int id in fake.scheduledContent.keys) {
        expect(id, lessThan(0), reason: 'notification ID $id phải âm (tách FSRS)');
      }
      final List<int> ids = fake.scheduledContent.keys.toList();
      expect(ids.toSet().length, ids.length, reason: 'không trùng ID');

      // Sync lại: cùng ID → Map ghi đè, không nhân bản lịch.
      final int scheduledAfterFirstSync = ids.length;
      await plan.sync();
      expect(
        fake.scheduledContent.keys.length,
        lessThanOrEqualTo(scheduledAfterFirstSync),
      );
      await services.dispose();
    });

    test('tắt thông báo bài mới hủy lịch nhưng không xóa dữ liệu', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 1,
        lessonPerDay: 1,
        notificationsEnabled: true,
      );
      await _seedTopic(services, name: 'N1');

      await plan.sync();
      await plan.sync();

      final FakeNotificationService fake =
          services.notifications as FakeNotificationService;
      expect(fake.scheduledContent, isNotEmpty);

      await plan.setNewContentNotifications(false);

      expect(fake.scheduledContent, isEmpty, reason: 'đã hủy toàn bộ lịch');
      expect(fake.cancelledContent, isNotEmpty);

      // Dữ liệu nội dung vẫn còn (scheduled → ready, refId giữ nguyên).
      final List<StudyFeedItem> ready =
          await StudyFeedRepository(services.database).listByStatus(
            <StudyFeedStatus>[StudyFeedStatus.ready],
          );
      expect(ready, isNotEmpty);
      expect(
        ready.every((StudyFeedItem r) => r.refId != null),
        isTrue,
        reason: 'nội dung đã lưu vẫn trỏ tới bài thật',
      );
      await services.dispose();
    });

    test('AI chưa cấu hình (allowMockContent=false) không sinh nội dung', () async {
      final (:services, :plan) = await _buildServices(
        allowMockContent: false,
        quickPerDay: 1,
        lessonPerDay: 0,
      );
      await _seedTopic(services, name: 'N1');

      final DateTime base = _earlyToday();
      final StudyPlanSyncResult result = await plan.sync(now: base);
      expect(result.generated, 0);

      final List<StudyFeedItem> rows =
          await StudyFeedRepository(services.database).listByStatus(
            <StudyFeedStatus>[StudyFeedStatus.ready],
          );
      expect(rows, isEmpty, reason: 'không được đánh dấu ready khi chưa lưu');
      await services.dispose();
    });

    test('payload notification đúng quick:<id> và lesson:<id>', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 1,
        lessonPerDay: 1,
        notificationsEnabled: true,
      );
      await _seedTopic(services, name: 'P1');

      await plan.sync();
      await plan.sync();

      final FakeNotificationService fake =
          services.notifications as FakeNotificationService;
      expect(fake.contentPayloads, isNotEmpty, reason: 'phải có lịch thật');
      for (final String payload in fake.contentPayloads.values) {
        expect(
          payload.startsWith('quick:') || payload.startsWith('lesson:'),
          isTrue,
          reason: 'payload $payload phải bắt đầu bằng quick: hoặc lesson:',
        );
        expect(
          payload.length,
          greaterThan('quick:'.length),
          reason: 'payload phải kèm id nội dung',
        );
      }
      await services.dispose();
    });

    test('nội dung thông báo: quick/lesson có title, body ≤180, subText', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 1,
        lessonPerDay: 1,
        notificationsEnabled: true,
      );
      await _seedTopic(services, name: 'P2');

      await plan.sync();
      await plan.sync();

      final FakeNotificationService fake =
          services.notifications as FakeNotificationService;
      expect(fake.contentPayloads, isNotEmpty);
      for (final MapEntry<int, String> e in fake.contentPayloads.entries) {
        final String title = fake.contentTitles[e.key]!;
        final String body = fake.contentBodies[e.key]!;
        expect(title, isNotEmpty);
        expect(body, isNotEmpty);
        expect(body.length, lessThanOrEqualTo(180));
        expect(fake.contentSubTexts[e.key], isNotEmpty);
        if (e.value.startsWith('lesson:')) {
          expect(fake.contentBigTexts[e.key], isNotEmpty);
        } else {
          expect(title, isNot('Thông tin nhanh mới'));
        }
      }
      await services.dispose();
    });
  });

  group('StudyPlanService — hồi quy lỗi đã sửa (GĐ17)', () {
    test('copyWith giữ lỗi và thời điểm thử lại khi không truyền mới', () {
      final DateTime retryAt = DateTime(2026, 10, 21, 9, 30);
      final StudyFeedItem row = StudyFeedItem(
        id: 'sf_1',
        kind: StudyFeedKind.quick,
        topicId: null,
        topicName: 'Chủ đề',
        dayKey: '2026-10-21',
        slotIndex: 0,
        status: StudyFeedStatus.error,
        dedupKey: 'dk_1',
        error: 'AI trả về nội dung rỗng.',
        retryable: true,
        nextRetryAt: retryAt,
        attempts: 2,
        createdAt: DateTime(2026, 10, 20),
        updatedAt: DateTime(2026, 10, 20),
      );

      // `feed.update()` gọi `copyWith(updatedAt: ...)` → không được làm mất
      // thông tin lỗi/backoff (bug: thông báo lỗi mất hoàn toàn trong DB).
      final StudyFeedItem kept = row.copyWith(
        updatedAt: DateTime(2026, 10, 21),
      );
      expect(kept.error, 'AI trả về nội dung rỗng.');
      expect(kept.nextRetryAt, retryAt);
      expect(kept.retryable, isTrue);
      expect(kept.attempts, 2);

      // Xoá lỗi phải tường minh (clearError) chứ không mặc định.
      final StudyFeedItem cleared = row.copyWith(
        status: StudyFeedStatus.queued,
        clearError: true,
        clearNextRetryAt: true,
      );
      expect(cleared.error, isNull);
      expect(cleared.nextRetryAt, isNull);
    });

    test('lỗi sinh nội dung được LƯU vào DB (không bị xoá khi update)', () async {
      final (:services, :plan) = await _buildServices(
        quickPerDay: 1,
        lessonPerDay: 0,
      );
      await _seedTopic(services, name: 'Chủ đề lỗi');

      // Provider luôn ném lỗi mạng → dòng phải ở trạng thái error KÈM message.
      services.ai.useProvider(_FailingAiProvider());
      await plan.sync(now: _earlyToday());

      final List<StudyFeedItem> errors =
          await StudyFeedRepository(services.database).listByStatus(
        <StudyFeedStatus>[StudyFeedStatus.error],
      );
      expect(errors, isNotEmpty, reason: 'lỗi AI phải được ghi nhận');
      expect(
        errors.first.error,
        isNotNull,
        reason: 'message lỗi phải còn trong DB để người dùng hiểu nguyên nhân',
      );
      expect(errors.first.error, contains('mạng'));

      // Summary phải trả về message lỗi cho UI hiển thị.
      final StudyPlanSummary summary = await plan.summary(now: _earlyToday());
      expect(summary.errors, greaterThan(0));
      expect(summary.errorMessages, isNotEmpty);
      expect(summary.errorMessages.first, contains('mạng'));
      await services.dispose();
    });
  });
}

/// Provider AI luôn lỗi mạng — dùng để kiểm tra đường lưu lỗi.
class _FailingAiProvider implements AIProvider {
  @override
  String get name => 'test_failing';

  @override
  bool get isConfigured => true;

  @override
  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  }) async => throw const _NetworkFailure();

  @override
  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  }) async => throw const _NetworkFailure();

  @override
  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  }) async => throw const _NetworkFailure();

  @override
  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  }) async => throw const _NetworkFailure();

  @override
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  }) async => throw const _NetworkFailure();

  @override
  Future<List<AiTopicSuggestion>> suggestTopics({
    required String domain,
    int count = 20,
  }) async => throw const _NetworkFailure();
}

class _NetworkFailure implements Exception {
  const _NetworkFailure();

  @override
  String toString() => 'Lỗi mạng khi gọi AI';
}