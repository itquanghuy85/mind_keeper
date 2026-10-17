import 'enums.dart';

class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.topicId,
    this.sourceId,
    required this.title,
    required this.content,
    this.details = '',
    this.origin = KnowledgeOrigin.userConfirmed,
    this.isFavorite = false,
    this.isPaused = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String topicId;
  final String? sourceId;
  final String title;
  final String content;
  final String details;
  final KnowledgeOrigin origin;
  final bool isFavorite;
  final bool isPaused;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeItem copyWith({
    String? title,
    String? content,
    String? details,
    String? sourceId,
    KnowledgeOrigin? origin,
    bool? isFavorite,
    bool? isPaused,
    DateTime? updatedAt,
  }) {
    return KnowledgeItem(
      id: id,
      topicId: topicId,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      content: content ?? this.content,
      details: details ?? this.details,
      origin: origin ?? this.origin,
      isFavorite: isFavorite ?? this.isFavorite,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'topic_id': topicId,
        'source_id': sourceId,
        'title': title,
        'content': content,
        'details': details,
        'origin': origin.dbValue,
        'is_favorite': isFavorite ? 1 : 0,
        'is_paused': isPaused ? 1 : 0,
        'created_at': createdAt.toUtc().millisecondsSinceEpoch,
        'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
      };

  factory KnowledgeItem.fromMap(Map<String, Object?> map) => KnowledgeItem(
        id: map['id']! as String,
        topicId: map['topic_id']! as String,
        sourceId: map['source_id'] as String?,
        title: map['title']! as String,
        content: map['content']! as String,
        details: (map['details'] ?? '') as String,
        origin: KnowledgeOrigin.fromDb(map['origin'] as String?),
        isFavorite: ((map['is_favorite'] ?? 0) as int) == 1,
        isPaused: ((map['is_paused'] ?? 0) as int) == 1,
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
