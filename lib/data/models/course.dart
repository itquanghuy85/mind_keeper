/// Cấp độ nội dung của một khóa học.
enum CourseLevel {
  basic('basic', 'Cơ bản'),
  advanced('advanced', 'Nâng cao'),
  pro('pro', 'Pro'),
  master('master', 'Master');

  const CourseLevel(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static CourseLevel fromDb(String? value) => CourseLevel.values.firstWhere(
    (CourseLevel e) => e.dbValue == value,
    orElse: () => CourseLevel.basic,
  );

  /// Mô tả cấp độ cho người dùng.
  String get hint => switch (this) {
    CourseLevel.basic => 'Kiến thức đời thường ai cũng nên biết',
    CourseLevel.advanced => 'Nguyên lý hoạt động, vì sao lại như vậy',
    CourseLevel.pro => 'Chi tiết kỹ thuật, ngoại lệ, so sánh, nhầm lẫn',
    CourseLevel.master => 'Giới hạn, tranh luận, vận dụng tình huống mới',
  };

  /// Chỉ dẫn độ khó đưa vào prompt AI.
  String get promptGuide => switch (this) {
    CourseLevel.basic =>
      'CƠ BẢN: kiến thức đời thường, dễ hiểu, ví dụ gần gũi, không thuật ngữ khó.',
    CourseLevel.advanced =>
      'NÂNG CAO: nguyên lý hoạt động, giải thích "vì sao", điều ít người biết.',
    CourseLevel.pro =>
      'PRO: chi tiết kỹ thuật, điều kiện biên và ngoại lệ, so sánh, nhầm lẫn thường gặp.',
    CourseLevel.master =>
      'MASTER: giới hạn của kiến thức, tranh luận giữa chuyên gia, nghịch lý, cách vận dụng vào tình huống mới.',
  };
}

enum CourseStatus {
  active('active'),
  paused('paused'),
  done('done');

  const CourseStatus(this.dbValue);

  final String dbValue;

  static CourseStatus fromDb(String? value) => CourseStatus.values.firstWhere(
    (CourseStatus e) => e.dbValue == value,
    orElse: () => CourseStatus.active,
  );
}

/// pending: mới có tiêu đề trong đề cương · ready: đã sinh nội dung (chưa đọc)
/// · read: người dùng đã bấm "Đã hiểu".
enum CourseItemStatus {
  pending('pending'),
  ready('ready'),
  read('read');

  const CourseItemStatus(this.dbValue);

  final String dbValue;

  static CourseItemStatus fromDb(String? value) =>
      CourseItemStatus.values.firstWhere(
        (CourseItemStatus e) => e.dbValue == value,
        orElse: () => CourseItemStatus.pending,
      );
}

DateTime? _ms(Object? value) => value is num
    ? DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true)
    : null;

/// Một khóa học = một chủ đề + cấp độ + đề cương gồm [totalItems] mẩu.
class Course {
  const Course({
    required this.id,
    required this.topicId,
    required this.name,
    required this.level,
    required this.totalItems,
    this.perDay = 1,
    this.status = CourseStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String topicId;
  final String name;
  final CourseLevel level;
  final int totalItems;
  final int perDay;
  final CourseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course copyWith({
    CourseLevel? level,
    int? totalItems,
    int? perDay,
    CourseStatus? status,
    DateTime? updatedAt,
  }) => Course(
    id: id,
    topicId: topicId,
    name: name,
    level: level ?? this.level,
    totalItems: totalItems ?? this.totalItems,
    perDay: perDay ?? this.perDay,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'topic_id': topicId,
    'name': name,
    'level': level.dbValue,
    'total_items': totalItems,
    'per_day': perDay,
    'status': status.dbValue,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory Course.fromMap(Map<String, Object?> map) => Course(
    id: map['id']! as String,
    topicId: map['topic_id']! as String,
    name: map['name']! as String,
    level: CourseLevel.fromDb(map['level'] as String?),
    totalItems: ((map['total_items'] ?? 0) as num).toInt(),
    perDay: ((map['per_day'] ?? 1) as num).toInt(),
    status: CourseStatus.fromDb(map['status'] as String?),
    createdAt: _ms(map['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: _ms(map['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Một mẩu kiến thức trong đề cương.
class CourseItem {
  const CourseItem({
    required this.id,
    required this.courseId,
    required this.position,
    required this.title,
    this.status = CourseItemStatus.pending,
    this.knowledgeItemId,
    this.summary = '',
    this.sourcesNote = '',
    this.releaseAt,
    this.readAt,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String courseId;
  final int position;
  final String title;
  final CourseItemStatus status;
  final String? knowledgeItemId;

  /// Bản tóm tắt 2–3 câu dùng cho thông báo (đọc nhanh không cần mở app).
  final String summary;

  /// Nguồn tham khảo do AI tự ghi — luôn là "chưa kiểm chứng".
  final String sourcesNote;
  final DateTime? releaseAt;
  final DateTime? readAt;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasContent => knowledgeItemId != null;

  CourseItem copyWith({
    String? title,
    CourseItemStatus? status,
    String? knowledgeItemId,
    String? summary,
    String? sourcesNote,
    DateTime? releaseAt,
    bool clearReleaseAt = false,
    DateTime? readAt,
    String? error,
    bool clearError = false,
    DateTime? updatedAt,
  }) => CourseItem(
    id: id,
    courseId: courseId,
    position: position,
    title: title ?? this.title,
    status: status ?? this.status,
    knowledgeItemId: knowledgeItemId ?? this.knowledgeItemId,
    summary: summary ?? this.summary,
    sourcesNote: sourcesNote ?? this.sourcesNote,
    releaseAt: clearReleaseAt ? null : (releaseAt ?? this.releaseAt),
    readAt: readAt ?? this.readAt,
    error: clearError ? null : (error ?? this.error),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'course_id': courseId,
    'position': position,
    'title': title,
    'status': status.dbValue,
    'knowledge_item_id': knowledgeItemId,
    'summary': summary,
    'sources_note': sourcesNote,
    'release_at': releaseAt?.toUtc().millisecondsSinceEpoch,
    'read_at': readAt?.toUtc().millisecondsSinceEpoch,
    'error': error,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory CourseItem.fromMap(Map<String, Object?> map) => CourseItem(
    id: map['id']! as String,
    courseId: map['course_id']! as String,
    position: ((map['position'] ?? 0) as num).toInt(),
    title: map['title']! as String,
    status: CourseItemStatus.fromDb(map['status'] as String?),
    knowledgeItemId: map['knowledge_item_id'] as String?,
    summary: (map['summary'] ?? '') as String,
    sourcesNote: (map['sources_note'] ?? '') as String,
    releaseAt: _ms(map['release_at']),
    readAt: _ms(map['read_at']),
    error: map['error'] as String?,
    createdAt: _ms(map['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: _ms(map['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Một mẩu đã ghép với khóa học của nó (cho UI trang chủ).
class CourseItemEntry {
  const CourseItemEntry({required this.course, required this.item});

  final Course course;
  final CourseItem item;
}

/// Ảnh chụp tiến độ một khóa học cho UI.
class CourseProgress {
  const CourseProgress({
    required this.course,
    required this.readCount,
    required this.readyCount,
    this.nextItem,
  });

  final Course course;
  final int readCount;

  /// Số mẩu đã có nội dung nhưng chưa đọc.
  final int readyCount;

  /// Mẩu kế tiếp cần đọc (chưa đọc đầu tiên), null nếu đã xong.
  final CourseItem? nextItem;

  String? get nextTitle => nextItem?.title;
  int get total => course.totalItems;
  double get fraction => total == 0 ? 0 : (readCount / total).clamp(0.0, 1.0);
  bool get isDone => total > 0 && readCount >= total;
}
