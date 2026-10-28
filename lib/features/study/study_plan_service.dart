import 'package:flutter/foundation.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/notification_text.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/lesson.dart';
import '../../data/models/study_feed_item.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/study_feed_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../discover/domain_catalog.dart';
import '../knowledge/knowledge_generation_service.dart';

/// Kết quả một lần đối soát kế hoạch học.
class StudyPlanSyncResult {
  const StudyPlanSyncResult({
    this.paused = false,
    this.skipped = false,
    this.planned = 0,
    this.generated = 0,
    this.scheduled = 0,
    this.failures = 0,
    this.summary,
  });

  /// Kế hoạch đang tạm dừng — không phát hành thêm, không xóa gì.
  final bool paused;

  /// Bị bỏ qua vì đã có một lần sync đang chạy (single-flight).
  final bool skipped;

  final int planned;
  final int generated;
  final int scheduled;
  final int failures;
  final StudyPlanSummary? summary;

  static const StudyPlanSyncResult notRunning = StudyPlanSyncResult(
    skipped: true,
  );
}

/// Ảnh chụp trạng thái hàng đợi để UI hiển thị.
class StudyPlanSummary {
  const StudyPlanSummary({
    required this.paused,
    required this.notificationsEnabled,
    required this.aiReady,
    required this.todayPlanned,
    required this.todayReady,
    required this.todayDelivered,
    required this.queued,
    this.ready = 0,
    required this.errors,
    required this.activeTopics,
    this.errorMessages = const <String>[],
  });

  final bool paused;
  final bool notificationsEnabled;
  final bool aiReady;

  /// Số khung giờ đang chiếm trong hôm nay (2 loại gộp).
  final int todayPlanned;

  /// Số nội dung hôm nay ĐÃ lưu xong (tính quota hoàn thành).
  final int todayReady;

  /// Số nội dung hôm nay đã tới giờ phát hành.
  final int todayDelivered;

  /// Chờ sinh nội dung (cả vùng tạo trước).
  final int queued;

  /// Đã lưu xong nhưng chưa tới/không tới khung giờ.
  final int ready;

  /// Lỗi cần thử lại.
  final int errors;

  /// Mô tả lỗi gần nhất (đã khử trùng lặp) để UI hiển thị cho người dùng
  /// biết VÌ SAO nội dung không tạo được — trước đây chỉ hiện đếm số lỗi.
  final List<String> errorMessages;

  final int activeTopics;

  int get todayPending => todayPlanned - todayDelivered;
}

/// Hệ thống học chủ động (GĐ17):
/// 1. Lập lịch nội dung mới theo quota/ngày + khung giờ của người dùng.
/// 2. Luân phiên công bằng giữa các chủ đề (con trỏ persist qua restart).
/// 3. Tạo trước nội dung bằng AI khi có mạng, LƯU SQLite trước khi thông báo.
/// 4. Lập lịch thông báo bài mới theo khung giờ (payload `quick:`/`lesson:`).
///
/// HOÀN TOÀN ĐỘC LẬP với FSRS: không đọc/ghi `review_cards`, `review_logs`,
/// không gọi `ReviewSchedulerService`, không đổi `dueAt`.
class StudyPlanService {
  StudyPlanService({
    required this.prefs,
    required this.feed,
    required this.topics,
    required this.knowledge,
    required this.lessons,
    required this.ai,
    required this.notifications,
    this.allowMockContent = false,
    this.maxGenerationsPerSync = 12,
  });

  final PreferencesService prefs;
  final StudyFeedRepository feed;
  final TopicRepository topics;
  final KnowledgeRepository knowledge;
  final LessonRepository lessons;
  final AiService ai;
  final NotificationService notifications;

  /// Chỉ dùng trong test: cho phép sinh nội dung từ provider mock.
  /// Bản thật CHỈ sinh khi `ai.isRealProvider` — không bao giờ coi nội dung
  /// mock là bài mới thật.
  final bool allowMockContent;

  /// Giới hạn số lần gọi AI mỗi lần sync (không lặp request gây tốn chi phí).
  final int maxGenerationsPerSync;

  bool _syncing = false;

  bool get isSyncing => _syncing;

  bool get _canGenerate => allowMockContent || ai.isRealProvider;

  // ----------------------------------------------------------------------
  // ID thông báo — ÂM để không bao giờ trùng ID thẻ FSRS
  // (`cardId.hashCode & 0x7fffffff` luôn >= 0), 1001/1002 (nhắc ôn/đọc)
  // và 700000+ (knowledge reminder) — tất cả đều >= 0.
  // ----------------------------------------------------------------------
  @visibleForTesting
  static int notificationIdFor(StudyFeedItem row) {
    final DateTime day = _parseDayKey(row.dayKey);
    final int dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays + 1;
    final int kindOffset = row.kind == StudyFeedKind.quick ? 0 : 32;
    // 64 mã/ngày (32 khung giờ × 2 loại) → duy nhất theo (ngày, loại, slot).
    return -8000000 - (dayOfYear * 64 + row.slotIndex + kindOffset);
  }

  static DateTime _parseDayKey(String dayKey) {
    final List<String> parts = dayKey.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime _localDay(DateTime moment) {
    final DateTime local = moment.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  // ----------------------------------------------------------------------
  // Đồng bộ chính — idempotent: chạy bao nhiêu lần cũng không sinh trùng
  // bài mới / không lên lịch trùng thông báo.
  // ----------------------------------------------------------------------
  Future<StudyPlanSyncResult> sync({DateTime? now}) async {
    if (_syncing) return StudyPlanSyncResult.notRunning;
    _syncing = true;
    try {
      final DateTime base = now ?? DateTime.now();

      if (prefs.studyPlanPaused) {
        await _unscheduleEverything();
        return StudyPlanSyncResult(
          paused: true,
          summary: await summary(now: base),
        );
      }

      final int planned = await _planDays(base);
      final int generated = await _generatePending(base);
      final (int scheduled, bool notificationsOff) =
          await _scheduleNotifications(base);
      await _markDelivered(base);
      if (notificationsOff) {
        await _unscheduleEverything();
      }

      return StudyPlanSyncResult(
        planned: planned,
        generated: generated,
        scheduled: scheduled,
        summary: await summary(now: base),
      );
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('StudyPlan sync lỗi: $e\n$s');
      }
      return StudyPlanSyncResult(
        failures: 1,
        summary: await summary(now: now ?? DateTime.now()),
      );
    } finally {
      _syncing = false;
    }
  }

  /// Tạo/cân lại các dòng theo quota từ hôm nay → [PreferencesService.studyPlanPrefetchDays]
  /// ngày tới.
  Future<int> _planDays(DateTime base) async {
    int planned = 0;
    final DateTime today = _localDay(base);
    for (int d = 0; d <= prefs.studyPlanPrefetchDays; d++) {
      final String dayKey = studyDayKey(today.add(Duration(days: d)));
      planned += await _planDayKind(dayKey, StudyFeedKind.quick);
      planned += await _planDayKind(dayKey, StudyFeedKind.lesson);
    }
    return planned;
  }

  Future<int> _planDayKind(String dayKey, StudyFeedKind kind) async {
    final int quota = kind == StudyFeedKind.quick
        ? prefs.studyPlanQuickPerDay
        : prefs.studyPlanLessonPerDay;
    final List<StudyFeedItem> rows = await feed.listByDayKind(dayKey, kind);
    int active = rows.where((StudyFeedItem r) => r.status.isActive).length;
    int created = 0;

    // 1) Giảm quota → hủy khung giờ cao nhất chưa phát hành.
    //    GIỮ dòng (status cancelled) làm lịch sử, không xóa nội dung đã học.
    if (active > quota) {
      final List<StudyFeedItem> candidates = rows
          .where(
            (StudyFeedItem r) =>
                r.status.isActive &&
                r.status != StudyFeedStatus.delivered &&
                r.status != StudyFeedStatus.opened,
          )
          .toList()
        ..sort(
          (StudyFeedItem a, StudyFeedItem b) =>
              b.slotIndex.compareTo(a.slotIndex),
        );
      for (final StudyFeedItem row in candidates) {
        if (active <= quota) break;
        if (row.status == StudyFeedStatus.scheduled) {
          await notifications.cancelContentNotification(
            notificationIdFor(row),
          );
        }
        await feed.update(
          row.copyWith(
            status: StudyFeedStatus.cancelled,
            clearError: true,
            clearScheduledAt: true,
          ),
        );
        active--;
      }
    }

    // 2) Tăng quota → khai báo khung giờ còn trống (hoặc sống lại dòng đã
    //    hủy — dùng lại nội dung đã lưu nếu còn ref).
    if (active < quota) {
      final Map<int, StudyFeedItem> bySlot = <int, StudyFeedItem>{
        for (final StudyFeedItem r in rows) r.slotIndex: r,
      };
      for (int slot = 0; slot < quota && active < quota; slot++) {
        final StudyFeedItem? existing = bySlot[slot];
        if (existing != null) {
          if (existing.status != StudyFeedStatus.cancelled) continue;
          final bool hasContent = existing.refId != null;
          await feed.update(
            existing.copyWith(
              status: hasContent
                  ? StudyFeedStatus.ready
                  : StudyFeedStatus.queued,
              clearError: true,
              clearNextRetryAt: true,
              attempts: 0,
            ),
          );
          active++;
          continue;
        }
        final StudyFeedItem? row = await _createRow(
          kind: kind,
          dayKey: dayKey,
          slot: slot,
        );
        if (row != null) {
          created++;
          active++;
        }
      }
    }
    return created;
  }

  /// Tạo một dòng queued mới. Trả null nếu không chọn được nội dung/chủ đề
  /// (khung giờ này sẽ được thử lại ở lần sync sau).
  Future<StudyFeedItem?> _createRow({
    required StudyFeedKind kind,
    required String dayKey,
    required int slot,
  }) async {
    final List<Topic> pool = await _topicPool();
    if (pool.isEmpty) return null;

    if (kind == StudyFeedKind.quick) {
      // Khung giờ + ngày UNIQUE → không thể trùng. Nội dung chống trùng lúc
      // sinh (findSimilar trong chủ đề).
      final Topic topic = await _nextTopic(pool);
      final StudyFeedItem row = StudyFeedItem(
        id: newId('sf'),
        kind: kind,
        topicId: topic.id,
        topicName: topic.name,
        dayKey: dayKey,
        slotIndex: slot,
        status: StudyFeedStatus.queued,
        dedupKey: 'quick|$dayKey|$slot',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      final bool ok = await feed.insert(row);
      return ok ? row : null;
    }

    // Lesson: dedup_key = key bài học (domain|chủ đề|chế độ|prompt) — một bài
    // đã từng lên lịch (bất kỳ ngày nào) sẽ không được lập lại, nên mỗi khung
    // giờ là một bài MỚI. Thử tối đa 3 chủ đề theo con trỏ luân phiên.
    final LessonMode mode = _currentLessonMode();
    for (int attempt = 0; attempt < pool.length && attempt < 3; attempt++) {
      final Topic topic = await _nextTopic(pool);
      for (final String variant in _lessonVariants(topic.name)) {
        final String dedupKey = _lessonKey(
          category: topic.category,
          variant: variant,
          mode: mode,
        );
        if (await feed.existsDedupKey(dedupKey)) continue;
        final StudyFeedItem row = StudyFeedItem(
          id: newId('sf'),
          kind: kind,
          topicId: topic.id,
          topicName: variant,
          dayKey: dayKey,
          slotIndex: slot,
          status: StudyFeedStatus.queued,
          dedupKey: dedupKey,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        final bool ok = await feed.insert(row);
        if (ok) return row;
        // Trùng race (khung giờ) → dừng, lần sync sau thử lại.
        return null;
      }
    }
    return null;
  }

  LessonMode _currentLessonMode() =>
      LessonMode.tryParse(prefs.lessonDefaultMode) ?? LessonMode.defaultMode;

  String _lessonKey({
    required String category,
    required String variant,
    required LessonMode mode,
  }) {
    final String domainId = KnowledgeGenerationService.inferDomainForTopic(
      category,
      variant,
    );
    return Lesson.buildDedupKey(
      domainId: domainId,
      topic: variant,
      mode: mode,
      promptVersion: AiService.lessonPromptVersion,
    );
  }

  /// Các biến thể tên bài cho một chủ đề — mỗi biến thể một dedup_key riêng,
  /// nên vẫn tạo được bài mới khi bài trước đã dùng.
  static List<String> _lessonVariants(String topicName) => <String>[
    topicName,
    'Cơ bản về $topicName',
    'Ứng dụng thực tế của $topicName',
    'Kỹ năng nâng cao về $topicName',
    'Tổng kết và mở rộng về $topicName',
    'Ví dụ minh họa cho $topicName',
    'Câu hỏi quanh $topicName',
    'Những sai lầm thường gặp về $topicName',
  ];

  /// Chủ đề đang theo dõi: active, không bị loại, thứ tự ổn định (created_at).
  Future<List<Topic>> _topicPool() async {
    final List<Topic> all = await topics.list();
    final Set<String> excluded = prefs.studyPlanExcludedTopics.toSet();
    return all.where((Topic t) => !excluded.contains(t.id)).toList();
  }

  /// Lấy chủ đề kế theo và CẬP NHẬT con trỏ (persist — sống sót restart).
  Future<Topic> _nextTopic(List<Topic> pool) async {
    final int cursor = prefs.studyPlanRotation;
    final Topic topic = pool[cursor % pool.length];
    await prefs.setStudyPlanRotation(cursor + 1);
    return topic;
  }

  // ----------------------------------------------------------------------
  // Sinh nội dung trước (tạo khi app đang chạy, LƯU SQLite trước — không
  // gọi AI khi phát thông báo, không cần mạng để đọc bài đã lưu)
  // ----------------------------------------------------------------------
  Future<int> _generatePending(DateTime base) async {
    if (!_canGenerate) return 0;
    final List<StudyFeedItem> pending = await feed.listByStatus(
      <StudyFeedStatus>[StudyFeedStatus.queued, StudyFeedStatus.error],
    );
    final DateTime nowUtc = base.toUtc();
    int generated = 0;
    int attempts = 0;
    for (final StudyFeedItem row in pending) {
      if (attempts >= maxGenerationsPerSync) break;
      // Không sinh nội dung cho khung giờ đã qua — không bao giờ lùi lịch
      // thông báo về quá khứ.
      if (!slotTimeFor(row).toUtc().isAfter(nowUtc)) continue;
      if (row.status == StudyFeedStatus.error) {
        final DateTime? retryAt = row.nextRetryAt;
        if (retryAt != null && retryAt.toUtc().isAfter(nowUtc)) {
          continue; // chờ hết backoff — không lặp request liên tục
        }
        if (!row.retryable) {
          continue; // lỗi permanent — chỉ retry khi người dùng bấm "Thử lại"
        }
      }
      attempts++;
      if (await _generateRow(row, base)) generated++;
    }
    return generated;
  }

  Future<bool> _generateRow(StudyFeedItem row, DateTime base) async {
    // Đã lưu rồi (retry sau lỗi ở khâu sau, hoặc sống lại dòng cũ) → chỉ
    // cần gắn lại trạng thái ready, không sinh trùng.
    if (row.refId != null) {
      await feed.update(_asReady(row, refId: row.refId!));
      return true;
    }

    final List<Topic> pool = await _topicPool();
    if (pool.isEmpty) {
      await _failRow(
        row,
        'Không có chủ đề theo dõi nào.',
        permanent: true,
        base: base,
      );
      return false;
    }

    // Thứ tự thử: chủ đề của dòng trước, rồi tối đa 2 chủ đề khác.
    final List<Topic> candidates = <Topic>[];
    if (row.topicId != null) {
      for (final Topic t in pool) {
        if (t.id == row.topicId) {
          candidates.add(t);
          break;
        }
      }
    }
    for (final Topic t in pool) {
      if (candidates.length >= 3) break;
      if (candidates.any((Topic c) => c.id == t.id)) continue;
      candidates.add(t);
    }

    String lastMessage = 'Không tạo được nội dung.';
    bool contentIssue = false;
    for (final Topic topic in candidates) {
      if (row.kind == StudyFeedKind.quick) {
        try {
          final String refId = await _createQuick(topic);
          await feed.update(
            _asReady(row, refId: refId, topic: topic, topicName: topic.name),
          );
          return true;
        } on AiConfigurationException catch (e) {
          await _failRow(row, e.toString(), permanent: true, base: base);
          return false;
        } on _ContentExhaustedException catch (e) {
          contentIssue = true;
          lastMessage = e.toString();
          continue; // sang chủ đề khác
        } on FormatException catch (e) {
          contentIssue = true;
          lastMessage = e.message;
          continue;
        } catch (e) {
          // Lỗi mạng/khác → dừng, đợi lần sync sau (không đốt request).
          await _failRow(row, e.toString(), permanent: false, base: base);
          return false;
        }
      } else {
        final bool? done = await _generateLessonRow(
          row,
          topic,
          base,
          onContentIssue: (String message) {
            contentIssue = true;
            lastMessage = message;
          },
        );
        if (done == true) return true;
        if (done == null) return false; // đã fail (permanent/retryable)
        // done == false → nội dung không sinh được, thử chủ đề tiếp.
      }
    }

    await _failRow(
      row,
      lastMessage,
      permanent: !contentIssue,
      base: base,
    );
    return false;
  }

  /// Trả về true = đã lưu xong; false = thử chủ đề khác; null = đã ghi lỗi.
  Future<bool?> _generateLessonRow(
    StudyFeedItem row,
    Topic topic,
    DateTime base, {
    required void Function(String message) onContentIssue,
  }) async {
    // Ưu tiên key đã cấp phát lúc lập lịch (đúng chủ đề/ràng buộc đã chọn).
    final List<String> variants = <String>[
      if (row.topicName.isNotEmpty) row.topicName,
      ..._lessonVariants(topic.name),
    ];
    final LessonMode mode = _currentLessonMode();
    final Set<String> tried = <String>{};

    for (final String variant in variants) {
      if (!tried.add(variant)) continue;
      String dedupKey = row.dedupKey;
      if (variant != row.topicName || row.kind != StudyFeedKind.lesson) {
        dedupKey = _lessonKey(
          category: topic.category,
          variant: variant,
          mode: mode,
        );
      }
      // Key này (kể cả ngoài feed) đã được dùng cho một dòng KHÁC chưa?
      if (variant != row.topicName &&
          await feed.existsDedupKey(dedupKey, excludeId: row.id)) {
        continue;
      }

      // Bài đã tồn tại (sinh bởi tính năng khác hoặc vòng trước) → gắn lại,
      // không sinh trùng, không tốn request AI.
      final Lesson? existing = await lessons.findByDedupKey(dedupKey);
      if (existing != null) {
        if (existing.linkedTopicId != topic.id) {
          await lessons.setLinkedTopic(existing.id, topicId: topic.id);
        }
        await feed.update(
          _asReady(
            row,
            refId: existing.id,
            topic: topic,
            topicName: variant,
            dedupKey: dedupKey,
          ),
        );
        return true;
      }

      try {
        final String refId = await _generateLesson(
          dedupKey: dedupKey,
          variant: variant,
          mode: mode,
        );
        await feed.update(
          _asReady(
            row,
            refId: refId,
            topic: topic,
            topicName: variant,
            dedupKey: dedupKey,
          ),
        );
        return true;
      } on AiConfigurationException catch (e) {
        await _failRow(row, e.toString(), permanent: true, base: base);
        return null;
      } on _ContentExhaustedException catch (e) {
        onContentIssue(e.toString());
        continue; // biến thể khác
      } on FormatException catch (e) {
        onContentIssue(e.message);
        continue; // biến thể khác
      } catch (e) {
        // Lỗi mạng/khác → dừng hẳn, backoff rồi thử lại sau.
        await _failRow(row, e.toString(), permanent: false, base: base);
        return null;
      }
    }
    return false;
  }

  StudyFeedItem _asReady(
    StudyFeedItem row, {
    required String refId,
    Topic? topic,
    String? topicName,
    String? dedupKey,
  }) => row.copyWith(
    status: StudyFeedStatus.ready,
    refId: refId,
    topicId: topic?.id,
    topicName: topicName,
    dedupKey: dedupKey,
    clearError: true,
    retryable: false,
    clearNextRetryAt: true,
    attempts: 0,
    clearScheduledAt: false,
  );

  Future<void> _failRow(
    StudyFeedItem row,
    String message, {
    required bool permanent,
    required DateTime base,
  }) async {
    final int attempts = row.attempts + 1;
    await feed.update(
      row.copyWith(
        status: StudyFeedStatus.error,
        error: message,
        retryable: !permanent,
        nextRetryAt: permanent ? null : base.toUtc().add(_backoff(attempts, message)),
        clearNextRetryAt: permanent,
        attempts: attempts,
        clearScheduledAt: true,
      ),
    );
  }

  static Duration _backoff(int attempts, String message) {
    final bool quota = message.toLowerCase().contains('quota');
    final int exponent = (attempts - 1).clamp(0, 8);
    Duration backoff = Duration(minutes: 5 * (1 << exponent));
    if (quota && backoff < const Duration(hours: 1)) {
      backoff = const Duration(hours: 1);
    }
    if (backoff > const Duration(hours: 6)) {
      backoff = const Duration(hours: 6);
    }
    return backoff;
  }

  /// Tạo một thông tin nhanh — lưu `knowledge_items` (chống trùng theo nội
  /// dung trong chủ đề). Trả về knowledge_item.id.
  Future<String> _createQuick(Topic topic) async {
    final String source =
        'Chủ đề: ${topic.name}.'
        '${topic.description.isEmpty ? '' : ' Mô tả: ${topic.description}'}';
    final List<AiKnowledgeDraft> drafts = await ai.draftKnowledge(
      sourceText: source,
      maxItems: 5,
    );
    for (final AiKnowledgeDraft draft in drafts) {
      if (draft.title.trim().isEmpty || draft.content.trim().length < 40) {
        continue;
      }
      final KnowledgeItem? similar = await knowledge.findSimilar(
        topic.id,
        draft.content,
      );
      if (similar != null) continue; // đã có → không trùng lặp
      try {
        final KnowledgeItem item = await knowledge.create(
          topicId: topic.id,
          title: draft.title,
          content: draft.content,
          details: draft.details,
          origin: KnowledgeOrigin.aiSuggested,
          now: DateTime.now(),
        );
        return item.id;
      } on Exception {
        continue; // trùng do race → thử bản khác
      }
    }
    throw const _ContentExhaustedException(
      'Chủ đề chưa có thông tin mới để phát hành.',
    );
  }

  /// Sinh và lưu một bài viết theo [dedupKey] đã cấp phát.
  /// Trả về lesson.id.
  Future<String> _generateLesson({
    required String dedupKey,
    required String variant,
    required LessonMode mode,
  }) async {
    final List<String> parts = dedupKey.split('|');
    final String domainId = parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0]
        : KnowledgeGenerationService.inferDomainForTopic('', variant);
    final LearningDomain domain =
        LearningDomains.byId(domainId) ?? LearningDomains.all.first;

    final AiLessonDraft draft = await ai.generateLesson(
      domain: domain.name,
      topic: variant,
      mode: mode.id,
      wordMin: mode.wordMin,
      wordMax: mode.wordMax,
      questionCount: mode.questions,
    );
    if (draft.title.trim().isEmpty || draft.sections.isEmpty) {
      throw const FormatException('Bài viết trả về thiếu cấu trúc.');
    }
    if (draft.wordCount < 80) {
      throw const FormatException('Bài viết quá ngắn so với yêu cầu.');
    }

    final DateTime timestamp = DateTime.now().toUtc();
    final List<LessonSource> sources = <LessonSource>[
      for (final AiLessonSource s in draft.sources)
        LessonSource(title: s.title, url: s.url),
    ];
    final Lesson lesson = Lesson(
      id: newId('ls'),
      domainId: domain.id,
      domainName: domain.name,
      topic: variant,
      mode: mode,
      promptVersion: AiService.lessonPromptVersion,
      dedupKey: dedupKey,
      title: draft.title,
      content: LessonContent(
        learningObjectives: draft.learningObjectives,
        introduction: draft.introduction,
        concepts: <LessonConcept>[
          for (final AiLessonConcept c in draft.concepts)
            LessonConcept(name: c.name, explanation: c.explanation),
        ],
        sections: <LessonSection>[
          for (final AiLessonSection s in draft.sections)
            LessonSection(heading: s.heading, body: s.body),
        ],
        keyPoints: draft.keyPoints,
        examples: draft.examples,
        commonMistakes: draft.commonMistakes,
        summary: draft.summary,
        memoryTip: draft.memoryTip,
      ),
      questions: <LessonQuestion>[
        for (final AiQuestionDraft q in draft.questions)
          LessonQuestion(
            question: q.question,
            answer: q.answer,
            explanation: q.explanation,
          ),
      ],
      sources: sources,
      verification: sources.isEmpty
          ? LessonVerification.unverified
          : LessonVerification.sourced,
      medical: domain.isHealth || draft.medical,
      wordCount: draft.wordCount,
      isFavorite: false,
      isRead: false,
      linkedTopicId: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final Lesson saved = await lessons.create(lesson);
    return saved.id;
  }

  // ----------------------------------------------------------------------
  // Thông báo bài mới theo khung giờ
  // ----------------------------------------------------------------------

  /// Lên lịch lại TOÀN BỘ nội dung ready trong vùng kế hoạch.
  /// Idempotent: cùng notification id → plugin ghi đè, không nhân bản.
  /// Trả về (số lịch đã đặt, có phải tắt toàn bộ không).
  Future<(int, bool)> _scheduleNotifications(DateTime base) async {
    if (!prefs.studyPlanNewContentNotifications) return (0, true);
    final bool? allowed = await notifications.areNotificationsEnabled();
    if (allowed == false) return (0, true);

    final DateTime today = _localDay(base);
    final String todayKey = studyDayKey(today);
    final String endKey = studyDayKey(
      today.add(Duration(days: prefs.studyPlanPrefetchDays)),
    );
    final List<StudyFeedItem> rows = await feed.listActiveRange(
      todayKey,
      endKey,
    );
    int scheduled = 0;
    for (final StudyFeedItem row in rows) {
      if (row.status != StudyFeedStatus.ready &&
          row.status != StudyFeedStatus.scheduled) {
        continue;
      }
      if (row.refId == null) continue; // chưa lưu xong → KHÔNG thông báo
      final DateTime at = slotTimeFor(row);
      if (!at.toUtc().isAfter(base.toUtc())) continue; // không lùi lịch quá khứ

      final StudyNotificationText text = await _notificationText(row);
      await notifications.scheduleContentNotification(
        id: notificationIdFor(row),
        title: text.title,
        body: text.body,
        bigText: text.bigText,
        subText: text.subText,
        at: at,
        payload: _payloadFor(row),
      );
      final bool needsUpdate =
          row.status != StudyFeedStatus.scheduled ||
          row.scheduledAt?.toUtc().millisecondsSinceEpoch !=
              at.toUtc().millisecondsSinceEpoch;
      if (needsUpdate) {
        await feed.update(
          row.copyWith(
            status: StudyFeedStatus.scheduled,
            scheduledAt: at.toUtc(),
            clearError: true,
          ),
        );
      }
      scheduled++;
    }
    return (scheduled, false);
  }

  String _payloadFor(StudyFeedItem row) => row.kind == StudyFeedKind.quick
      ? '${NotificationPayload.kindQuick}:${row.refId}'
      : '${NotificationPayload.kindLesson}:${row.refId}';

  /// Nội dung thông báo bài mới:
  /// - Thông tin nhanh: title = tên mẩu; body = 1–2 câu ý chính (≤180 ký tự);
  ///   subText = chủ đề.
  /// - Bài học: title = tên bài; body = tóm tắt; bigText = tóm tắt + mẹo nhớ;
  ///   subText = chủ đề.
  Future<StudyNotificationText> _notificationText(StudyFeedItem row) async {
    if (row.kind == StudyFeedKind.quick) {
      final KnowledgeItem? item = row.refId == null
          ? null
          : await knowledge.getById(row.refId!);
      if (item == null) {
        return StudyNotificationText(
          title: 'Thông tin nhanh mới',
          body: row.topicName,
          subText: row.topicName,
        );
      }
      final String lead = leadSentences(item.content);
      return StudyNotificationText(
        title: item.title,
        body: lead.isEmpty ? item.title : lead,
        subText: row.topicName,
      );
    }
    final Lesson? lesson = row.refId == null
        ? null
        : await lessons.getById(row.refId!);
    if (lesson == null) {
      return StudyNotificationText(
        title: 'Bài viết mới',
        body: row.topicName,
        subText: row.topicName,
      );
    }
    final LessonContent c = lesson.content;
    final String summary = c.summary.trim().isNotEmpty
        ? c.summary
        : (c.keyPoints.isNotEmpty ? c.keyPoints.first : c.introduction);
    return StudyNotificationText(
      title: lesson.title,
      body: notificationBody(summary),
      bigText: composeBigText(summary, c.memoryTip),
      subText: lesson.topic.trim().isEmpty ? row.topicName : lesson.topic,
    );
  }

  /// Thời điểm phát hành của một dòng theo khung giờ người dùng đặt.
  ///
  /// - Có khung giờ tùy chỉnh `HH:mm`: dùng lần lượt; nội dung nhiều hơn số
  ///   khung giờ thì cộng dồn 10 phút cho lần lặp (chính sách rõ ràng).
  /// - Không có: chia đều trong khoảng bắt đầu → kết thúc.
  DateTime slotTimeFor(StudyFeedItem row) {
    final DateTime day = _parseDayKey(row.dayKey);
    final List<String> custom = prefs.studyPlanSlots;
    if (custom.isNotEmpty) {
      final int index = row.slotIndex;
      final int cycle = index ~/ custom.length;
      final String raw = custom[index % custom.length];
      final List<String> hm = raw.split(':');
      final int hour = int.tryParse(hm.first) ?? prefs.studyPlanStartHour;
      final int minute = hm.length > 1 ? (int.tryParse(hm[1]) ?? 0) : 0;
      return day
          .add(Duration(hours: hour, minutes: minute))
          .add(Duration(minutes: 10 * cycle));
    }

    final DateTime start = day.add(
      Duration(
        hours: prefs.studyPlanStartHour,
        minutes: prefs.studyPlanStartMinute,
      ),
    );
    DateTime end = day.add(
      Duration(
        hours: prefs.studyPlanEndHour,
        minutes: prefs.studyPlanEndMinute,
      ),
    );
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    final int count = row.kind == StudyFeedKind.quick
        ? prefs.studyPlanQuickPerDay
        : prefs.studyPlanLessonPerDay;
    if (count <= 1 || row.slotIndex >= count) return start;
    final int span = end.difference(start).inMinutes;
    final int offset = ((span * row.slotIndex) / (count - 1)).round();
    return start.add(Duration(minutes: offset));
  }

  /// Đánh dấu các lịch đã tới giờ là `delivered` (đối soát khi mở app).
  Future<void> _markDelivered(DateTime base) async {
    final List<StudyFeedItem> rows = await feed.listByStatus(
      <StudyFeedStatus>[StudyFeedStatus.scheduled],
    );
    for (final StudyFeedItem row in rows) {
      final DateTime? at = row.scheduledAt;
      if (at == null || at.toUtc().isAfter(base.toUtc())) continue;
      await feed.update(row.copyWith(status: StudyFeedStatus.delivered));
    }
  }

  /// Hủy lịch bài mới mà KHÔNG xóa dữ liệu (tạm dừng / tắt thông báo /
  /// quyền bị thu hồi). Nội dung `ready` vẫn ở lại SQLite.
  Future<void> _unscheduleEverything() async {
    final List<StudyFeedItem> rows = await feed.listByStatus(
      <StudyFeedStatus>[StudyFeedStatus.scheduled],
    );
    for (final StudyFeedItem row in rows) {
      await notifications.cancelContentNotification(notificationIdFor(row));
      await feed.update(
        row.copyWith(
          status: StudyFeedStatus.ready,
          clearScheduledAt: true,
          clearError: true,
        ),
      );
    }
  }

  /// Người dùng tắt/bật thông báo bài mới từ UI.
  Future<void> setNewContentNotifications(bool enabled) async {
    await prefs.setStudyPlanNewContentNotifications(enabled);
    if (!enabled) {
      await _unscheduleEverything();
    } else {
      await sync();
    }
  }

  /// Thử lại toàn bộ hàng đợi lỗi (nút ở UI) — reset backoff.
  Future<void> retryFailed() async {
    final List<StudyFeedItem> rows = await feed.listByStatus(
      <StudyFeedStatus>[StudyFeedStatus.error],
    );
    for (final StudyFeedItem row in rows) {
      await feed.update(
        row.copyWith(
          status: StudyFeedStatus.queued,
          clearError: true,
          retryable: false,
          clearNextRetryAt: true,
          attempts: 0,
        ),
      );
    }
    await sync();
  }

  /// Người dùng mở nội dung từ thông báo → ghi trạng thái `opened`.
  Future<void> markOpened(String refId) => feed.markOpened(refId);

  // ----------------------------------------------------------------------
  // Cho UI (màn Hôm nay / Kế hoạch học)
  // ----------------------------------------------------------------------

  /// Nội dung của một ngày, sắp xếp theo giờ phát hành dự kiến.
  Future<List<StudyFeedItem>> listDay(DateTime day) async {
    final String key = studyDayKey(day);
    final List<StudyFeedItem> quick = await feed.listByDayKind(
      key,
      StudyFeedKind.quick,
    );
    final List<StudyFeedItem> lessons = await feed.listByDayKind(
      key,
      StudyFeedKind.lesson,
    );
    final List<StudyFeedItem> all = <StudyFeedItem>[
      ...quick,
      ...lessons,
    ].where((StudyFeedItem r) => r.status != StudyFeedStatus.cancelled).toList();
    all.sort(
      (StudyFeedItem a, StudyFeedItem b) => a.slotIndex == b.slotIndex
          ? a.kind.dbValue.compareTo(b.kind.dbValue)
          : a.slotIndex.compareTo(b.slotIndex),
    );
    return all;
  }

  Future<StudyPlanSummary> summary({DateTime? now}) async {
    final DateTime base = now ?? DateTime.now();
    final DateTime today = _localDay(base);
    final String todayKey = studyDayKey(today);
    final String endKey = studyDayKey(
      today.add(Duration(days: prefs.studyPlanPrefetchDays)),
    );
    final List<StudyFeedItem> rows = await feed.listActiveRange(
      todayKey,
      endKey,
    );
    final List<StudyFeedItem> todayRows = rows
        .where((StudyFeedItem r) => r.dayKey == todayKey)
        .toList(growable: false);
    final List<Topic> pool = await _topicPool();

    return StudyPlanSummary(
      paused: prefs.studyPlanPaused,
      notificationsEnabled: prefs.studyPlanNewContentNotifications,
      aiReady: _canGenerate,
      todayPlanned: todayRows.length,
      todayReady: todayRows
          .where((StudyFeedItem r) => r.status.hasContent)
          .length,
      todayDelivered: todayRows
          .where(
            (StudyFeedItem r) =>
                r.status == StudyFeedStatus.delivered ||
                r.status == StudyFeedStatus.opened,
          )
          .length,
      queued: rows
          .where((StudyFeedItem r) => r.status == StudyFeedStatus.queued)
          .length,
      ready: rows
          .where((StudyFeedItem r) => r.status == StudyFeedStatus.ready)
          .length,
      errors: rows
          .where((StudyFeedItem r) => r.status == StudyFeedStatus.error)
          .length,
      errorMessages: _errorMessages(rows),
      activeTopics: pool.length,
    );
  }

  /// Thu thập mô tả lỗi (khử trùng lặp, giới hạn 3 lỗi đầu) để UI hiển thị
  /// nguyên nhân thực tế thay vì chỉ con số.
  static List<String> _errorMessages(List<StudyFeedItem> rows) {
    final List<String> messages = <String>[];
    for (final StudyFeedItem r in rows) {
      if (r.status != StudyFeedStatus.error) continue;
      final String message = (r.error ?? '').trim();
      if (message.isEmpty) continue;
      if (messages.contains(message)) continue;
      messages.add(message);
      if (messages.length >= 3) break;
    }
    return messages;
  }
}

/// Chủ đề không sinh thêm được nội dung mới (hết dữ liệu) — chuyển sang
/// chủ đề/biến thể khác, không coi là lỗi mạng.
class _ContentExhaustedException implements Exception {
  const _ContentExhaustedException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Nội dung một thông báo bài mới (title/body/bigText/subText).
class StudyNotificationText {
  const StudyNotificationText({
    required this.title,
    required this.body,
    required this.subText,
    String? bigText,
  }) : bigText = bigText ?? body;

  final String title;
  final String body;
  final String bigText;
  final String subText;
}
