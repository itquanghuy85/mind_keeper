import '../../core/services/notification_text.dart';
import '../../core/services/review_scheduler_service.dart';
import '../../core/services/share_intake.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/source.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../core/errors/app_exception.dart';

/// Kết quả "Lưu nhanh".
class QuickCaptureResult {
  const QuickCaptureResult({
    required this.topic,
    this.item,
    this.duplicate = false,
  });

  final Topic topic;

  /// Kiến thức vừa tạo; null khi [duplicate].
  final KnowledgeItem? item;

  /// Nội dung/liên kết đã có trong chủ đề → không tạo thêm.
  final bool duplicate;
}

/// Lưu nhanh nội dung chia sẻ thành KnowledgeItem + ReviewCard due ngay.
class QuickCaptureService {
  QuickCaptureService({
    required this.topics,
    required this.knowledge,
    required this.cards,
    required this.sources,
  });

  final TopicRepository topics;
  final KnowledgeRepository knowledge;
  final ReviewRepository cards;
  final SourceRepository sources;

  static const String inboxName = 'Hộp thư đến';
  static const String inboxDescription = 'Nội dung lưu nhanh từ chia sẻ';

  /// Chủ đề "Hộp thư đến" — tự tạo nếu chưa có.
  Future<Topic> ensureInbox() async {
    return await topics.findByName(inboxName) ??
        await topics.create(name: inboxName, description: inboxDescription);
  }

  /// Tiêu đề gợi ý: subject (nếu có) → dòng đầu (bỏ URL) → tên miền của link.
  static String suggestTitle(SharedPayload payload) {
    final String subject = payload.subject.trim();
    if (subject.isNotEmpty) return truncateAtWord(subject, 80);
    final String? url = payload.url;
    final String withoutUrl = url == null
        ? payload.text
        : payload.text.replaceFirst(url, ' ');
    final String firstLine = withoutUrl
        .split(RegExp(r'[\r\n]+'))
        .map((String l) => l.trim())
        .firstWhere((String l) => l.isNotEmpty, orElse: () => '');
    if (firstLine.isNotEmpty) return truncateAtWord(firstLine, 80);
    if (url != null) {
      final Uri? uri = Uri.tryParse(url);
      final String host = (uri?.host ?? '').replaceFirst(RegExp(r'^www\.'), '');
      if (host.isNotEmpty) return truncateAtWord('Liên kết từ $host', 80);
    }
    return 'Ghi chú nhanh';
  }

  /// Lưu nhanh vào [topicId] (null → "Hộp thư đến").
  ///
  /// - Chống trùng: cùng liên kết (`reference_url`) hoặc nội dung giống đã có
  ///   trong chủ đề → [QuickCaptureResult.duplicate], không tạo thêm thẻ.
  /// - Link: lưu thêm `Source(type: link, reference_url)` và gắn vào kiến thức.
  /// - Thẻ ôn: "(tiêu đề) — nhớ được điều gì?", due ngay.
  Future<QuickCaptureResult> save({
    required SharedPayload payload,
    String? topicId,
    String? title,
    String? content,
  }) async {
    final Topic topic = topicId == null
        ? await ensureInbox()
        : (await topics.getById(topicId)) ?? await ensureInbox();
    final String body = (content ?? payload.text).trim();
    final String heading = (title ?? suggestTitle(payload)).trim();
    final String? url = payload.url;

    if (url != null) {
      final List<Source> existing = await sources.listByTopic(topic.id);
      if (existing.any((Source s) => s.referenceUrl == url)) {
        return QuickCaptureResult(topic: topic, duplicate: true);
      }
    }

    final DateTime now = DateTime.now().toUtc();
    final KnowledgeItem item;
    try {
      String? sourceId;
      // Kiểm tra trùng nội dung TRƯỚC khi tạo nguồn, tránh nguồn mồ côi.
      if (await knowledge.findSimilar(topic.id, body) != null) {
        return QuickCaptureResult(topic: topic, duplicate: true);
      }
      if (url != null) {
        final Source source = await sources.create(
          topicId: topic.id,
          type: SourceType.link,
          title: heading,
          contentText: payload.text,
          referenceUrl: url,
          now: now,
        );
        sourceId = source.id;
      }
      item = await knowledge.create(
        topicId: topic.id,
        title: heading,
        content: body,
        sourceId: sourceId,
        now: now,
      );
    } on ValidationException {
      return QuickCaptureResult(topic: topic, duplicate: true);
    }
    await cards.create(
      knowledgeItemId: item.id,
      question: '$heading — nhớ được điều gì?',
      answer: body,
      dueAt: ReviewSchedulerService.initialDue(DateTime.now()),
      now: now,
    );
    return QuickCaptureResult(topic: topic, item: item);
  }
}
