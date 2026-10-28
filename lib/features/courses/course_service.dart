import 'package:flutter/foundation.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/notification_text.dart';
import '../../core/services/preferences_service.dart';
import '../../data/models/course.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/review_card.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../ai/course_ai.dart';

class CourseSyncResult {
  const CourseSyncResult({
    this.generated = 0,
    this.scheduled = 0,
    this.failures = 0,
    this.skipped = false,
    this.lastError,
  });

  final int generated;
  final int scheduled;
  final int failures;
  final bool skipped;
  final String? lastError;
}

/// Nhãn nguồn: AI tự ghi, chưa được đối chiếu với tài liệu thật.
const String courseUnverifiedLabel = 'Chưa kiểm chứng';

/// Khóa học: chọn chủ đề + cấp độ + số mẩu → AI dựng đề cương → mỗi ngày phát
/// hành mẩu kế tiếp theo khung giờ, thông báo đọc nhanh, "Đã hiểu" thì vào lịch
/// ôn FSRS.
///
/// Nội dung thật lưu ở `knowledge_items`; `course_items` chỉ giữ đề cương,
/// trạng thái và giờ phát hành. Sinh nội dung ở lúc app chạy (không gọi AI khi
/// thông báo nổ) nên thông báo luôn có nội dung đã lưu.
class CourseService {
  CourseService({
    required this.prefs,
    required this.courses,
    required this.topics,
    required this.knowledge,
    required this.cards,
    required this.ai,
    required this.notifications,
    this.allowMockContent = false,
    this.maxGenerationsPerSync = 8,
    this.prefetchDays = 1,
  });

  final PreferencesService prefs;
  final CourseRepository courses;
  final TopicRepository topics;
  final KnowledgeRepository knowledge;
  final ReviewRepository cards;
  final AiService ai;
  final NotificationService notifications;

  /// Chỉ test: cho phép sinh bằng provider mock.
  final bool allowMockContent;
  final int maxGenerationsPerSync;

  /// Số ngày sinh trước ngoài hôm nay (1 = hôm nay + ngày mai).
  final int prefetchDays;

  bool _syncing = false;

  bool get isSyncing => _syncing;

  bool get canGenerate => allowMockContent || ai.isRealProvider;

  // ---------------------------------------------------------------------
  // Tạo khóa học
  // ---------------------------------------------------------------------

  /// AI dựng đề cương (chưa lưu gì) để người dùng xem và chỉnh.
  Future<List<String>> draftOutline({
    required String topicName,
    required CourseLevel level,
    required int count,
  }) async {
    if (!canGenerate) {
      throw const AiConfigurationException(
        code: 'not_configured',
        message: 'AI chưa cấu hình.',
        userMessage: 'AI chưa được cấu hình nên chưa thể soạn đề cương.',
      );
    }
    final int n = count.clamp(1, 60);
    final List<String> titles = await ai.generateOutline(
      topic: topicName.trim(),
      level: level,
      count: n,
    );
    return cleanOutline(titles, n);
  }

  /// Lưu khóa học với đề cương đã duyệt, tạo chủ đề nếu chưa có.
  Future<Course> startCourse({
    required String topicName,
    required CourseLevel level,
    required List<String> titles,
    String category = '',
    int perDay = 1,
    DateTime? now,
  }) async {
    final Topic topic = await _ensureTopic(topicName, category);
    final Course course = await courses.createWithOutline(
      topicId: topic.id,
      name: topic.name,
      level: level,
      titles: titles,
      perDay: perDay,
      now: now,
    );
    return course;
  }

  Future<Topic> _ensureTopic(String name, String category) async {
    final String clean = TopicRepository.normalizeName(name);
    final Topic? existing = await topics.findByName(clean);
    if (existing != null) return existing;
    return topics.create(
      name: clean,
      category: category,
      origin: TopicOrigin.discovered,
    );
  }

  // ---------------------------------------------------------------------
  // Đồng bộ: sinh mẩu theo quota ngày + lên lịch thông báo
  // ---------------------------------------------------------------------

  Future<CourseSyncResult> sync({DateTime? now}) async {
    if (_syncing) return const CourseSyncResult(skipped: true);
    _syncing = true;
    try {
      final DateTime base = now ?? DateTime.now();
      if (prefs.studyPlanPaused) {
        await _cancelAllScheduled(base);
        return const CourseSyncResult();
      }
      int generated = 0;
      int failures = 0;
      String? lastError;
      if (canGenerate) {
        final List<Course> active = await courses.list(
          status: CourseStatus.active,
        );
        int budget = maxGenerationsPerSync;
        for (int d = 0; d <= prefetchDays && budget > 0; d++) {
          final DateTime dayStart = _dayStart(base).add(Duration(days: d));
          for (int ci = 0; ci < active.length && budget > 0; ci++) {
            final Course course = active[ci];
            final DateTime dayEnd = dayStart.add(const Duration(days: 1));
            int released = await courses.countReleasedBetween(
              course.id,
              dayStart,
              dayEnd,
            );
            while (released < course.perDay && budget > 0) {
              final CourseItem? next = await _nextPending(course.id);
              if (next == null) break;
              budget--;
              try {
                await _generateItem(
                  course,
                  next,
                  releaseAt: slotTime(dayStart, ci, released),
                );
                generated++;
                released++;
              } catch (e) {
                failures++;
                lastError = e is AiConfigurationException
                    ? e.userMessage
                    : e.toString();
                if (kDebugMode) debugPrint('Course sync lỗi: $e');
                break; // dừng khóa này, thử lại ở lần sync sau
              }
            }
          }
        }
        await _completeFinished(active);
      }
      final int scheduled = await _scheduleNotifications(base);
      return CourseSyncResult(
        generated: generated,
        scheduled: scheduled,
        failures: failures,
        lastError: lastError,
      );
    } finally {
      _syncing = false;
    }
  }

  static DateTime _dayStart(DateTime moment) {
    final DateTime l = moment.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  /// Giờ phát hành của mẩu thứ [j] trong ngày của khóa thứ [courseIndex].
  @visibleForTesting
  DateTime slotTime(DateTime dayStart, int courseIndex, int j) {
    final List<String> custom = prefs.studyPlanSlots;
    final int slot = courseIndex + j;
    if (custom.isNotEmpty) {
      final int cycle = slot ~/ custom.length;
      final List<String> hm = custom[slot % custom.length].split(':');
      final int hour = int.tryParse(hm.first) ?? prefs.studyPlanStartHour;
      final int minute = hm.length > 1 ? (int.tryParse(hm[1]) ?? 0) : 0;
      return dayStart.add(
        Duration(hours: hour, minutes: minute + 10 * cycle),
      );
    }
    final DateTime start = dayStart.add(
      Duration(
        hours: prefs.studyPlanStartHour,
        minutes: prefs.studyPlanStartMinute,
      ),
    );
    DateTime end = dayStart.add(
      Duration(hours: prefs.studyPlanEndHour, minutes: prefs.studyPlanEndMinute),
    );
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    final int span = end.difference(start).inMinutes;
    final int offset = (span * slot / 6).round() % (span <= 0 ? 1 : span);
    return start.add(Duration(minutes: offset));
  }

  Future<CourseItem?> _nextPending(String courseId) async {
    final List<CourseItem> items = await courses.listItems(courseId);
    for (final CourseItem item in items) {
      if (item.status == CourseItemStatus.pending) return item;
    }
    return null;
  }

  /// Sinh nội dung một mẩu và lưu SQLite (knowledge_items + thẻ ôn ẩn).
  Future<CourseItem> _generateItem(
    Course course,
    CourseItem item, {
    required DateTime releaseAt,
  }) async {
    final List<CourseItem> all = await courses.listItems(course.id);
    final AiBiteDraft draft = await ai.generateBite(
      topic: course.name,
      level: course.level,
      title: item.title,
      index: item.position + 1,
      total: course.totalItems,
      previousTitles: <String>[
        for (final CourseItem other in all)
          if (other.id != item.id) other.title,
      ],
    );
    final String content = draft.content.trim().length < 20
        ? '${draft.content.trim()} ${draft.summary}'.trim()
        : draft.content.trim();
    final KnowledgeItem saved = await knowledge.create(
      topicId: course.topicId,
      title: item.title,
      content: content,
      details: _detailsText(draft),
      origin: KnowledgeOrigin.aiSuggested,
      skipDuplicateCheck: true,
      now: DateTime.now(),
    );
    if (draft.question.trim().isNotEmpty && draft.answer.trim().isNotEmpty) {
      final ReviewCard card = await cards.create(
        knowledgeItemId: saved.id,
        question: draft.question,
        answer: draft.answer,
        dueAt: releaseAt.add(const Duration(days: 1)),
      );
      // Thẻ chỉ vào lịch ôn sau khi người dùng bấm "Đã hiểu".
      await cards.setActive(card.id, active: false);
    }
    final CourseItem updated = item.copyWith(
      status: CourseItemStatus.ready,
      knowledgeItemId: saved.id,
      summary: draft.summary.trim(),
      memoryTip: draft.memoryTip.trim(),
      sourcesNote: draft.sources.join('; '),
      releaseAt: releaseAt.toUtc(),
      clearError: true,
    );
    await courses.updateItem(updated);
    return updated;
  }

  static String _detailsText(AiBiteDraft draft) {
    final StringBuffer out = StringBuffer();
    if (draft.example.trim().isNotEmpty) {
      out.writeln('Ví dụ: ${draft.example.trim()}');
    }
    if (draft.sources.isNotEmpty) {
      if (out.isNotEmpty) out.writeln();
      out.write(
        'Nguồn tham khảo ($courseUnverifiedLabel): ${draft.sources.join('; ')}',
      );
    }
    return out.toString().trim();
  }

  /// Đọc trước: sinh ngay mẩu kế tiếp của khóa (không chờ giờ phát hành).
  Future<CourseItem?> generateNext(String courseId, {DateTime? now}) async {
    if (!canGenerate) {
      throw const AiConfigurationException(
        code: 'not_configured',
        message: 'AI chưa cấu hình.',
        userMessage: 'AI chưa được cấu hình nên chưa thể soạn mẩu mới.',
      );
    }
    final Course? course = await courses.getById(courseId);
    if (course == null) return null;
    final CourseItem? next = await _nextPending(courseId);
    if (next == null) return null;
    final CourseItem item = await _generateItem(
      course,
      next,
      releaseAt: (now ?? DateTime.now()),
    );
    await _scheduleNotifications(now ?? DateTime.now());
    return item;
  }

  Future<void> _completeFinished(List<Course> active) async {
    for (final Course course in active) {
      final List<CourseItem> items = await courses.listItems(course.id);
      if (items.isNotEmpty &&
          items.every((CourseItem i) => i.status == CourseItemStatus.read)) {
        await courses.updateCourse(course.copyWith(status: CourseStatus.done));
      }
    }
  }

  // ---------------------------------------------------------------------
  // Thông báo
  // ---------------------------------------------------------------------

  /// ID thông báo ÂM (không trùng thẻ FSRS ≥ 0 và kế hoạch học -8.0M…).
  /// FNV-1a để ổn định giữa các lần chạy.
  @visibleForTesting
  static int notificationIdFor(String itemId) {
    int hash = 0x811c9dc5;
    for (final int unit in itemId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return -9000000 - (hash & 0xfffff);
  }

  static String payloadFor(String itemId) => 'course:$itemId';

  Future<int> _scheduleNotifications(DateTime base) async {
    if (!prefs.studyPlanNewContentNotifications) {
      await _cancelAllScheduled(base);
      return 0;
    }
    final bool? allowed = await notifications.areNotificationsEnabled();
    if (allowed == false) return 0;
    final List<CourseItemEntry> upcoming = await courses.listUpcoming(
      asOf: base,
    );
    int scheduled = 0;
    for (final CourseItemEntry entry in upcoming) {
      final CourseItem item = entry.item;
      if (item.releaseAt == null || !item.hasContent) continue;
      final String summary = item.summary.isEmpty ? item.title : item.summary;
      await notifications.scheduleCourseNotification(
        id: notificationIdFor(item.id),
        title: item.title,
        body: notificationBody(summary),
        bigText: composeBigText(summary, item.memoryTip),
        subText: '${entry.course.name} · ${entry.course.level.label}',
        footer:
            'Mẩu ${item.position + 1}/${entry.course.totalItems} · '
            '$courseUnverifiedLabel',
        at: item.releaseAt!,
        payload: payloadFor(item.id),
      );
      scheduled++;
    }
    return scheduled;
  }

  Future<void> _cancelAllScheduled(DateTime base) async {
    final List<CourseItemEntry> upcoming = await courses.listUpcoming(
      asOf: base,
    );
    for (final CourseItemEntry entry in upcoming) {
      await notifications.cancelCourseNotification(
        notificationIdFor(entry.item.id),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Đọc
  // ---------------------------------------------------------------------

  /// Người dùng bấm "Đã hiểu": ghi nhận đã đọc, hủy thông báo, đưa thẻ ôn
  /// vào lịch FSRS (due sau 1 ngày). Idempotent.
  Future<CourseItem?> markRead(String itemId, {DateTime? now}) async {
    final CourseItem? item = await courses.getItem(itemId);
    if (item == null) return null;
    final DateTime moment = (now ?? DateTime.now()).toUtc();
    CourseItem current = item;
    if (item.status == CourseItemStatus.ready) {
      current = item.copyWith(status: CourseItemStatus.read, readAt: moment);
      await courses.updateItem(current);
    }
    await notifications.cancelCourseNotification(notificationIdFor(itemId));
    if (current.status == CourseItemStatus.read) {
      await finalizeRead(current, now: moment);
    }
    return current;
  }

  /// Kích hoạt thẻ ôn của mẩu đã đọc (chạy lại an toàn). Cũng xử lý mẩu
  /// được đánh dấu đã đọc từ nút "Đã hiểu" trên thông báo khi app đóng.
  Future<void> finalizeRead(CourseItem item, {DateTime? now}) async {
    final String? knowledgeId = item.knowledgeItemId;
    if (knowledgeId == null) return;
    final DateTime moment = (now ?? DateTime.now()).toUtc();
    final List<ReviewCard> existing = await cards.listAllByKnowledgeItem(
      knowledgeId,
    );
    for (final ReviewCard card in existing) {
      if (card.isActive || card.reps > 0) continue;
      await cards.updateSchedule(
        card.copyWith(
          dueAt: moment.add(const Duration(days: 1)),
          isActive: true,
          updatedAt: moment,
        ),
      );
    }
    // Vào "Kho đã học" (started_at) + ghi lần đọc gần nhất.
    final KnowledgeItem? saved = await knowledge.getById(knowledgeId);
    if (saved != null && (saved.startedAt == null || saved.lastReadAt == null)) {
      await knowledge.update(
        saved.copyWith(
          startedAt: saved.startedAt ?? moment,
          lastReadAt: saved.lastReadAt ?? moment,
          updatedAt: moment,
        ),
      );
    }
  }

  /// Đối soát khi mở app: kích hoạt thẻ ôn cho mẩu đã đọc ở nền.
  Future<int> reconcile({DateTime? now}) async {
    int fixed = 0;
    for (final Course course in await courses.list()) {
      for (final CourseItem item in await courses.listItems(course.id)) {
        if (item.status != CourseItemStatus.read) continue;
        final String? knowledgeId = item.knowledgeItemId;
        if (knowledgeId == null) continue;
        final List<ReviewCard> existing = await cards.listAllByKnowledgeItem(
          knowledgeId,
        );
        if (existing.any((ReviewCard c) => !c.isActive && c.reps == 0)) {
          await finalizeRead(item, now: now);
          fixed++;
        }
      }
    }
    return fixed;
  }

  // ---------------------------------------------------------------------
  // Cho UI
  // ---------------------------------------------------------------------

  Future<List<CourseProgress>> progress() async {
    final List<CourseProgress> result = <CourseProgress>[];
    for (final Course course in await courses.list()) {
      final List<CourseItem> items = await courses.listItems(course.id);
      int read = 0;
      int ready = 0;
      CourseItem? next;
      for (final CourseItem item in items) {
        if (item.status == CourseItemStatus.read) {
          read++;
        } else if (item.status == CourseItemStatus.ready) {
          ready++;
          next ??= item;
        } else {
          next ??= item;
        }
      }
      result.add(
        CourseProgress(
          course: course,
          readCount: read,
          readyCount: ready,
          nextItem: next,
        ),
      );
    }
    return result;
  }

  Future<List<CourseItemEntry>> unread({DateTime? now}) =>
      courses.listUnread(asOf: now ?? DateTime.now());

  /// Đổi cấp độ giữa chừng: giữ nguyên đề cương và mẩu đã đọc; các mẩu CHƯA
  /// sinh nội dung sẽ được soạn theo cấp độ mới.
  Future<void> changeLevel(String courseId, CourseLevel level) async {
    final Course? course = await courses.getById(courseId);
    if (course == null || course.level == level) return;
    await courses.updateCourse(course.copyWith(level: level));
  }

  Future<void> setStatus(String courseId, CourseStatus status) async {
    final Course? course = await courses.getById(courseId);
    if (course == null) return;
    await courses.updateCourse(course.copyWith(status: status));
    if (status != CourseStatus.active) {
      await _cancelAllScheduled(DateTime.now());
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final List<CourseItem> items = await courses.listItems(courseId);
    for (final CourseItem item in items) {
      await notifications.cancelCourseNotification(
        notificationIdFor(item.id),
      );
    }
    await courses.deleteCourse(courseId);
  }
}
