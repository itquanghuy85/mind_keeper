import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/knowledge_generation.dart';

class KnowledgeGenerationRepository {
  KnowledgeGenerationRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  /// Tạo hoặc cập nhật task sinh kiến thức.
  Future<KnowledgeGenerationTask> upsert({
    required String topicId,
    required KnowledgeGenerationStatus status,
    int? totalPlanned,
    int? completedCount,
    int? failedCount,
    int? currentBatch,
    String? lastError,
    DateTime? now,
  }) async {
    final DateTime timestamp = (now ?? DateTime.now()).toUtc();

    final KnowledgeGenerationTask? existing = await getByTopicId(topicId);

    final KnowledgeGenerationTask task =
        existing?.copyWith(
          status: status,
          totalPlanned: totalPlanned ?? existing.totalPlanned,
          completedCount: completedCount ?? existing.completedCount,
          failedCount: failedCount ?? existing.failedCount,
          currentBatch: currentBatch ?? existing.currentBatch,
          lastError: lastError ?? existing.lastError,
          updatedAt: timestamp,
          completedAt:
              (status == KnowledgeGenerationStatus.completed ||
                  status == KnowledgeGenerationStatus.failed)
              ? timestamp
              : existing.completedAt,
        ) ??
        KnowledgeGenerationTask(
          topicId: topicId,
          status: status,
          totalPlanned: totalPlanned ?? 0,
          completedCount: completedCount ?? 0,
          failedCount: failedCount ?? 0,
          currentBatch: currentBatch ?? 0,
          lastError: lastError,
          startedAt: timestamp,
          updatedAt: timestamp,
          completedAt:
              (status == KnowledgeGenerationStatus.completed ||
                  status == KnowledgeGenerationStatus.failed)
              ? timestamp
              : null,
        );

    await _db.insert(
      'knowledge_generation_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return task;
  }

  /// Lấy task theo topicId.
  Future<KnowledgeGenerationTask?> getByTopicId(String topicId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_generation_tasks',
      where: 'topic_id = ?',
      whereArgs: <Object>[topicId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KnowledgeGenerationTask.fromMap(rows.first);
  }

  /// Tăng số bài hoàn thành.
  Future<void> incrementCompleted(String topicId) async {
    final KnowledgeGenerationTask? task = await getByTopicId(topicId);
    if (task == null) return;
    await upsert(
      topicId: topicId,
      status: task.status,
      completedCount: task.completedCount + 1,
      currentBatch: task.currentBatch + 1,
    );
  }

  /// Tăng số bài thất bại.
  Future<void> incrementFailed(String topicId, String error) async {
    final KnowledgeGenerationTask? task = await getByTopicId(topicId);
    if (task == null) return;
    await upsert(
      topicId: topicId,
      status: KnowledgeGenerationStatus.generating,
      failedCount: task.failedCount + 1,
      currentBatch: task.currentBatch + 1,
      lastError: error,
    );
  }

  /// Đánh dấu hoàn tất.
  Future<void> markCompleted(String topicId) async {
    await upsert(topicId: topicId, status: KnowledgeGenerationStatus.completed);
  }

  /// Đánh dấu thất bại.
  Future<void> markFailed(String topicId, String error) async {
    await upsert(
      topicId: topicId,
      status: KnowledgeGenerationStatus.failed,
      lastError: error,
    );
  }

  /// Xóa task (khi xóa chủ đề).
  Future<void> delete(String topicId) async {
    await _db.delete(
      'knowledge_generation_tasks',
      where: 'topic_id = ?',
      whereArgs: <Object>[topicId],
    );
  }

  /// Lấy tất cả task đang chạy.
  Future<List<KnowledgeGenerationTask>> getActiveTasks() async {
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_generation_tasks',
      where: 'status IN (?, ?)',
      whereArgs: <Object>[
        KnowledgeGenerationStatus.pending.id,
        KnowledgeGenerationStatus.generating.id,
      ],
    );
    return rows.map(KnowledgeGenerationTask.fromMap).toList(growable: false);
  }
}
