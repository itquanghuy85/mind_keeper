/// Trạng thái sinh thư viện kiến thức cho một chủ đề.
enum KnowledgeGenerationStatus {
  pending('pending', 'Đang chờ'),
  generating('generating', 'Đang sinh'),
  completed('completed', 'Hoàn tất'),
  failed('failed', 'Thất bại');

  const KnowledgeGenerationStatus(this.id, this.label);

  final String id;
  final String label;

  static KnowledgeGenerationStatus fromDb(String? value) {
    switch (value) {
      case 'generating':
        return KnowledgeGenerationStatus.generating;
      case 'completed':
        return KnowledgeGenerationStatus.completed;
      case 'failed':
        return KnowledgeGenerationStatus.failed;
      case 'pending':
      default:
        return KnowledgeGenerationStatus.pending;
    }
  }
}

/// Theo dõi tiến độ sinh kiến thức cho một chủ đề.
class KnowledgeGenerationTask {
  const KnowledgeGenerationTask({
    required this.topicId,
    required this.status,
    required this.totalPlanned,
    required this.completedCount,
    required this.failedCount,
    required this.currentBatch,
    required this.lastError,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String topicId;
  final KnowledgeGenerationStatus status;
  final int totalPlanned;
  final int completedCount;
  final int failedCount;
  final int currentBatch;
  final String? lastError;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool get isFinished =>
      status == KnowledgeGenerationStatus.completed ||
      status == KnowledgeGenerationStatus.failed;
  bool get isGenerating => status == KnowledgeGenerationStatus.generating;
  bool get canRetry => status == KnowledgeGenerationStatus.failed;
  int get remainingCount => totalPlanned - completedCount - failedCount;
  double get progress =>
      totalPlanned > 0 ? (completedCount + failedCount) / totalPlanned : 0;

  KnowledgeGenerationTask copyWith({
    KnowledgeGenerationStatus? status,
    int? totalPlanned,
    int? completedCount,
    int? failedCount,
    int? currentBatch,
    String? lastError,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return KnowledgeGenerationTask(
      topicId: topicId,
      status: status ?? this.status,
      totalPlanned: totalPlanned ?? this.totalPlanned,
      completedCount: completedCount ?? this.completedCount,
      failedCount: failedCount ?? this.failedCount,
      currentBatch: currentBatch ?? this.currentBatch,
      lastError: lastError ?? this.lastError,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'topic_id': topicId,
    'status': status.id,
    'total_planned': totalPlanned,
    'completed_count': completedCount,
    'failed_count': failedCount,
    'current_batch': currentBatch,
    'last_error': lastError,
    'started_at': startedAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
    'completed_at': completedAt?.toUtc().millisecondsSinceEpoch,
  };

  factory KnowledgeGenerationTask.fromMap(Map<String, Object?> map) {
    return KnowledgeGenerationTask(
      topicId: map['topic_id']! as String,
      status: KnowledgeGenerationStatus.fromDb(map['status'] as String?),
      totalPlanned: (map['total_planned'] ?? 0) as int,
      completedCount: (map['completed_count'] ?? 0) as int,
      failedCount: (map['failed_count'] ?? 0) as int,
      currentBatch: (map['current_batch'] ?? 0) as int,
      lastError: map['last_error'] as String?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['started_at']! as num).toInt(),
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at']! as num).toInt(),
        isUtc: true,
      ),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['completed_at']! as num).toInt(),
              isUtc: true,
            )
          : null,
    );
  }
}

/// Cấu hình mặc định cho việc sinh kiến thức.
class KnowledgeGenerationConfig {
  const KnowledgeGenerationConfig({
    this.defaultLessonCount = 5,
    this.defaultWordMin = 500,
    this.defaultWordMax = 800,
    this.maxRetries = 3,
    this.batchSize = 2,
  });

  /// Số bài học mặc định cho chủ đề mới.
  final int defaultLessonCount;

  /// Số từ tối thiểu mỗi bài.
  final int defaultWordMin;

  /// Số từ tối đa mỗi bài.
  final int defaultWordMax;

  /// Số lần thử lại tối đa cho một bài thất bại.
  final int maxRetries;

  /// Số bài sinh song song trong một batch.
  final int batchSize;

  static const KnowledgeGenerationConfig defaultConfig =
      KnowledgeGenerationConfig();
}
