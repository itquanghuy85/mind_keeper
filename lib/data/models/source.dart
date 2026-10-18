import 'enums.dart';

class Source {
  const Source({
    required this.id,
    this.topicId,
    required this.type,
    this.title = '',
    this.storagePath,
    this.contentText = '',
    this.status = SourceStatus.ready,
    this.referenceUrl,
    this.referenceLocation,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? topicId;
  final SourceType type;
  final String title;
  final String? storagePath;
  final String contentText;
  final SourceStatus status;
  final String? referenceUrl;
  final String? referenceLocation;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReady => status == SourceStatus.ready;

  Source copyWith({
    String? topicId,
    SourceType? type,
    String? title,
    String? storagePath,
    String? contentText,
    SourceStatus? status,
    String? referenceUrl,
    String? referenceLocation,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    return Source(
      id: id,
      topicId: topicId ?? this.topicId,
      type: type ?? this.type,
      title: title ?? this.title,
      storagePath: storagePath ?? this.storagePath,
      contentText: contentText ?? this.contentText,
      status: status ?? this.status,
      referenceUrl: referenceUrl ?? this.referenceUrl,
      referenceLocation: referenceLocation ?? this.referenceLocation,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'topic_id': topicId,
    'type': type.dbValue,
    'title': title,
    'storage_path': storagePath,
    'content_text': contentText,
    'status': status.dbValue,
    'reference_url': referenceUrl,
    'reference_location': referenceLocation,
    'error_message': errorMessage,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory Source.fromMap(Map<String, Object?> map) => Source(
    id: map['id']! as String,
    topicId: map['topic_id'] as String?,
    type: SourceType.fromDb(map['type'] as String?),
    title: (map['title'] ?? '') as String,
    storagePath: map['storage_path'] as String?,
    contentText: (map['content_text'] ?? '') as String,
    status: SourceStatus.fromDb(map['status'] as String?),
    referenceUrl: map['reference_url'] as String?,
    referenceLocation: map['reference_location'] as String?,
    errorMessage: map['error_message'] as String?,
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
