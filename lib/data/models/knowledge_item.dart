import 'enums.dart';

class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.topicId,
    this.sourceId,
    this.lessonId,
    required this.title,
    required this.content,
    this.details = '',
    this.origin = KnowledgeOrigin.userConfirmed,
    this.isFavorite = false,
    this.isPaused = false,
    this.startedAt,
    this.lastReadAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String topicId;
  final String? sourceId;
  final String? lessonId;
  final String title;
  final String content;
  final String details;
  final KnowledgeOrigin origin;
  final bool isFavorite;
  final bool isPaused;

  /// Thời điểm người dùng bắt đầu đọc/đăng ký mục tiêu ghi nhớ lần đầu.
  /// Null nếu chưa từng mở bài để đọc.
  final DateTime? startedAt;

  /// Thời điểm người dùng mở bài đọc gần nhất (cập nhật mỗi lần mở reader).
  /// Khác startedAt (không đổi) và khác updatedAt (bị mọi thao tác sửa ảnh hưởng).
  final DateTime? lastReadAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// True nếu bài đã được đăng ký vào Kho đã học (đã mở đọc lần đầu).
  bool get isEnrolled => startedAt != null;

  KnowledgeItem copyWith({
    String? title,
    String? content,
    String? details,
    String? sourceId,
    String? lessonId,
    KnowledgeOrigin? origin,
    bool? isFavorite,
    bool? isPaused,
    DateTime? startedAt,
    DateTime? lastReadAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeItem(
      id: id,
      topicId: topicId,
      sourceId: sourceId ?? this.sourceId,
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      content: content ?? this.content,
      details: details ?? this.details,
      origin: origin ?? this.origin,
      isFavorite: isFavorite ?? this.isFavorite,
      isPaused: isPaused ?? this.isPaused,
      startedAt: startedAt ?? this.startedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'topic_id': topicId,
    'source_id': sourceId,
    'lesson_id': lessonId,
    'title': title,
    'content': content,
    'details': details,
    'origin': origin.dbValue,
    'is_favorite': isFavorite ? 1 : 0,
    'is_paused': isPaused ? 1 : 0,
    'started_at': startedAt?.toUtc().millisecondsSinceEpoch,
    'last_read_at': lastReadAt?.toUtc().millisecondsSinceEpoch,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory KnowledgeItem.fromMap(Map<String, Object?> map) => KnowledgeItem(
    id: map['id']! as String,
    topicId: map['topic_id']! as String,
    sourceId: map['source_id'] as String?,
    lessonId: map['lesson_id'] as String?,
    title: map['title']! as String,
    content: map['content']! as String,
    details: (map['details'] ?? '') as String,
    origin: KnowledgeOrigin.fromDb(map['origin'] as String?),
    isFavorite: ((map['is_favorite'] ?? 0) as int) == 1,
    isPaused: ((map['is_paused'] ?? 0) as int) == 1,
    startedAt: map['started_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            (map['started_at']! as num).toInt(),
            isUtc: true,
          )
        : null,
    lastReadAt: map['last_read_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            (map['last_read_at']! as num).toInt(),
            isUtc: true,
          )
        : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['created_at']! as num).toInt(),
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['updated_at']! as num).toInt(),
      isUtc: true,
    ),
  );
}
