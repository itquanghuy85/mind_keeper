/// Loại nội dung mới trong kế hoạch học chủ động (GĐ17).
enum StudyFeedKind {
  /// Thông tin nhanh (knowledge_items).
  quick('quick'),

  /// Bài viết / bài học (lessons).
  lesson('lesson');

  const StudyFeedKind(this.dbValue);

  final String dbValue;

  static StudyFeedKind fromDb(String? value) => StudyFeedKind.values.firstWhere(
    (StudyFeedKind e) => e.dbValue == value,
    orElse: () => StudyFeedKind.quick,
  );
}

/// Trạng thái một dòng trong hàng đợi kế hoạch học.
///
/// `queued` → `ready` (nội dung đã lưu xong xuống SQLite) → `scheduled`
/// (đã lên lịch thông báo) → `delivered` (đã tới giờ) → `opened`
/// (người dùng đã mở). `error` = thử lại được/thường theo cờ `retryable`.
/// `cancelled` = kế hoạch bị thu hẹp (giảm quota/bỏ chủ đề) — GIỮ DÒNG
/// làm lịch sử, không xóa nội dung đã học.
enum StudyFeedStatus {
  queued('queued'),
  ready('ready'),
  scheduled('scheduled'),
  delivered('delivered'),
  opened('opened'),
  error('error'),
  cancelled('cancelled');

  const StudyFeedStatus(this.dbValue);

  final String dbValue;

  static StudyFeedStatus fromDb(String? value) =>
      StudyFeedStatus.values.firstWhere(
        (StudyFeedStatus e) => e.dbValue == value,
        orElse: () => StudyFeedStatus.queued,
      );

  /// Trạng thái còn nằm trong kế hoạch (chiếm khung giờ, tính quota).
  bool get isActive =>
      this == StudyFeedStatus.queued ||
      this == StudyFeedStatus.ready ||
      this == StudyFeedStatus.scheduled ||
      this == StudyFeedStatus.delivered ||
      this == StudyFeedStatus.opened ||
      this == StudyFeedStatus.error;

  /// Trạng thái nội dung ĐÃ lưu xong xuống SQLite (được phép lên lịch
  /// thông báo — không bao giờ thông báo cho nội dung chưa lưu).
  bool get hasContent =>
      this == StudyFeedStatus.ready ||
      this == StudyFeedStatus.scheduled ||
      this == StudyFeedStatus.delivered ||
      this == StudyFeedStatus.opened;
}

/// Một dòng kế hoạch: nội dung mới dự kiến phát hành tại [dayKey] (ngày
/// địa phương của thiết bị, `yyyy-MM-dd`) ở khung [slotIndex].
class StudyFeedItem {
  const StudyFeedItem({
    required this.id,
    required this.kind,
    required this.topicId,
    required this.topicName,
    required this.dayKey,
    required this.slotIndex,
    required this.status,
    required this.dedupKey,
    this.refId,
    this.scheduledAt,
    this.error,
    this.retryable = false,
    this.nextRetryAt,
    this.attempts = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final StudyFeedKind kind;
  final String? topicId;
  final String topicName;
  final String dayKey;
  final int slotIndex;
  final StudyFeedStatus status;

  /// `knowledge_item.id` (quick) hoặc `lessons.id` (lesson) sau khi lưu.
  final String? refId;

  /// Chống trùng toàn cục: với lesson bằng dedup_key của bài học, với quick
  /// bằng `quick:<topic>:<ngày>:<khung>`.
  final String dedupKey;
  final DateTime? scheduledAt;
  final String? error;
  final bool retryable;
  final DateTime? nextRetryAt;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StudyFeedItem.fromMap(Map<String, Object?> map) => StudyFeedItem(
    id: map['id']! as String,
    kind: StudyFeedKind.fromDb(map['kind'] as String?),
    topicId: map['topic_id'] as String?,
    topicName: (map['topic_name'] ?? '') as String,
    dayKey: map['day_key']! as String,
    slotIndex: ((map['slot_index'] ?? 0) as num).toInt(),
    status: StudyFeedStatus.fromDb(map['status'] as String?),
    refId: map['ref_id'] as String?,
    dedupKey: map['dedup_key']! as String,
    scheduledAt: _dateTime(map['scheduled_at']),
    error: map['error'] as String?,
    retryable: ((map['retryable'] ?? 0) as num) == 1,
    nextRetryAt: _dateTime(map['next_retry_at']),
    attempts: ((map['attempts'] ?? 0) as num).toInt(),
    createdAt: _dateTime(map['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: _dateTime(map['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'kind': kind.dbValue,
    'topic_id': topicId,
    'topic_name': topicName,
    'day_key': dayKey,
    'slot_index': slotIndex,
    'status': status.dbValue,
    'ref_id': refId,
    'dedup_key': dedupKey,
    'scheduled_at': scheduledAt?.toUtc().millisecondsSinceEpoch,
    'error': error,
    'retryable': retryable ? 1 : 0,
    'next_retry_at': nextRetryAt?.toUtc().millisecondsSinceEpoch,
    'attempts': attempts,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  StudyFeedItem copyWith({
    StudyFeedStatus? status,
    String? refId,
    String? topicId,
    String? topicName,
    String? dedupKey,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    String? error,
    bool clearError = false,
    bool? retryable,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    int? attempts,
    DateTime? updatedAt,
  }) => StudyFeedItem(
    id: id,
    kind: kind,
    topicId: topicId ?? this.topicId,
    topicName: topicName ?? this.topicName,
    dayKey: dayKey,
    slotIndex: slotIndex,
    status: status ?? this.status,
    refId: refId ?? this.refId,
    dedupKey: dedupKey ?? this.dedupKey,
    scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
    // Giữ lỗi cũ khi không truyền `error`; chỉ xoá khi `clearError` bật.
    // Trước đây `error` luôn bị ghi đè bằng null → thông báo lỗi mất hoàn toàn
    // sau lần `feed.update()` đầu tiên, người dùng không thấy vì sao fail.
    error: clearError ? null : (error ?? this.error),
    retryable: retryable ?? this.retryable,
    // Giữ thời điểm thử lại nếu không truyền mới; chỉ xoá khi `clearNextRetryAt`.
    // Nếu không, backoff bị mất sau mỗi lần `feed.update()` → app spam request.
    nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
    attempts: attempts ?? this.attempts,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static DateTime? _dateTime(Object? value) {
    if (value is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true)
        .toLocal();
  }
}

/// Chuỗi ngày địa phương `yyyy-MM-dd` — khóa quota theo ngày thiết bị.
String studyDayKey(DateTime moment) {
  final DateTime local = moment.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
