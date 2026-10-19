import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/id_generator.dart';
import '../db/app_database.dart';
import '../models/enums.dart';
import '../models/knowledge_item.dart';
import '../models/source.dart';

class KnowledgeRepository {
  KnowledgeRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  static String normalizeContent(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<KnowledgeItem> create({
    required String topicId,
    required String title,
    required String content,
    String details = '',
    String? sourceId,
    String? lessonId,
    KnowledgeOrigin origin = KnowledgeOrigin.userConfirmed,
    bool skipDuplicateCheck = false,
    DateTime? now,
    DateTime? startedAt,
  }) async {
    final String cleanTitle = title.trim();
    final String cleanContent = content.trim();
    if (cleanTitle.isEmpty) {
      throw const ValidationException(
        'Tiêu đề không được để trống.',
        field: 'title',
      );
    }
    if (cleanContent.isEmpty) {
      throw const ValidationException(
        'Nội dung không được để trống.',
        field: 'content',
      );
    }

    final TopicRef? topic = await _topicRef(topicId);
    if (topic == null) {
      throw const NotFoundException('Chủ đề không tồn tại.');
    }

    if (!skipDuplicateCheck) {
      final KnowledgeItem? existing = await findSimilar(topicId, cleanContent);
      if (existing != null) {
        throw const ValidationException(
          'Kiến thức này đã tồn tại trong chủ đề.',
          field: 'content',
        );
      }
    }

    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final KnowledgeItem item = KnowledgeItem(
      id: newId('ki'),
      topicId: topicId,
      sourceId: sourceId,
      lessonId: lessonId,
      title: cleanTitle,
      content: cleanContent,
      details: details.trim(),
      origin: origin,
      startedAt: startedAt,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _db.insert('knowledge_items', item.toMap());
    return item;
  }

  /// Tìm KnowledgeItem theo title trong một topic (để kiểm tra đã đăng ký chưa).
  /// Nếu cung cấp lessonId, ưu tiên tìm theo lessonId để tránh gộp sai bài trùng tiêu đề.
  Future<KnowledgeItem?> findByTitle(
    String topicId,
    String title, {
    String? lessonId,
  }) async {
    final String cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    // Nếu có lessonId, tìm theo lessonId trước (định danh ổn định)
    if (lessonId != null) {
      final List<Map<String, Object?>> rowsByLesson = await _db.query(
        'knowledge_items',
        where: 'topic_id = ? AND lesson_id = ?',
        whereArgs: <Object>[topicId, lessonId],
        limit: 1,
      );
      if (rowsByLesson.isNotEmpty) {
        return KnowledgeItem.fromMap(rowsByLesson.first);
      }
    }

    // Fallback: tìm theo title (tương thích ngược).
    // Nếu đã biết lessonId, CHỈ nhận row legacy chưa gắn lesson nào
    // (lesson_id IS NULL) để không gộp nhầm hai bài khác nhau cùng title.
    String where = 'topic_id = ? AND LOWER(title) = LOWER(?)';
    if (lessonId != null) {
      where += ' AND lesson_id IS NULL';
    }
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_items',
      where: where,
      whereArgs: <Object>[topicId, cleanTitle],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KnowledgeItem.fromMap(rows.first);
  }

  /// Đăng ký bài vào Kho đã học (tạo KnowledgeItem với startedAt = now).
  /// Trả về item đã có nếu đã đăng ký (không tạo mới).
  /// Sử dụng lessonId để tránh gộp sai bài trùng tiêu đề.
  Future<KnowledgeItem> enroll({
    required String topicId,
    required String title,
    required String content,
    String details = '',
    String? sourceId,
    String? lessonId,
    KnowledgeOrigin origin = KnowledgeOrigin.aiSuggested,
    DateTime? now,
  }) async {
    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final String cleanTitle = title.trim();

    // Kiểm tra đã đăng ký chưa
    KnowledgeItem? existing;

    if (lessonId != null) {
      // Nếu có lessonId: CHỈ tìm theo lessonId (KHÔNG fallback title)
      // Điều này tránh gộp sai 2 bài khác nhau cùng title nhưng khác lessonId
      final List<Map<String, Object?>> rowsByLesson = await _db.query(
        'knowledge_items',
        where: 'topic_id = ? AND lesson_id = ?',
        whereArgs: <Object>[topicId, lessonId],
        limit: 1,
      );
      if (rowsByLesson.isNotEmpty) {
        existing = KnowledgeItem.fromMap(rowsByLesson.first);
      }
    } else {
      // Không có lessonId: fallback tìm theo title (tương thích ngược)
      existing = await findByTitle(topicId, title);
    }

    if (existing != null) {
      // Nếu đã có nhưng chưa có startedAt, cập nhật startedAt
      if (existing.startedAt == null) {
        final KnowledgeItem updated = existing.copyWith(
          startedAt: timestamp,
          updatedAt: timestamp,
        );
        await _db.update(
          'knowledge_items',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: <Object>[existing.id],
        );
        return updated;
      }
      return existing;
    }

    // Tạo mới với startedAt
    final KnowledgeItem item = KnowledgeItem(
      id: newId('ki'),
      topicId: topicId,
      sourceId: sourceId,
      lessonId: lessonId,
      title: cleanTitle,
      content: content.trim(),
      details: details.trim(),
      origin: origin,
      startedAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _db.insert('knowledge_items', item.toMap());
    return item;
  }

  /// Danh sách mục tiêu đã đăng ký (started_at NOT NULL) cho Kho đã học.
  /// Khác [search]: search('') trả về rỗng, nên màn Kho đã học phải dùng
  /// hàm này để luôn hiển thị đủ dữ liệu khi không có từ khóa.
  Future<List<KnowledgeItem>> listEnrolled({String? query}) async {
    final List<String> where = <String>['started_at IS NOT NULL'];
    final List<Object> args = <Object>[];
    final String? value = query?.trim();
    if (value != null && value.isNotEmpty) {
      where.add(
        '(LOWER(title) LIKE ? OR LOWER(content) LIKE ? OR LOWER(details) LIKE ?)',
      );
      final String like = '%${value.toLowerCase()}%';
      args.addAll(<Object>[like, like, like]);
    }
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_items',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'started_at DESC',
      limit: 500,
    );
    return rows.map(KnowledgeItem.fromMap).toList(growable: false);
  }

  /// Ghi nhận thời điểm mở bài đọc gần nhất (không đổi started_at).
  Future<KnowledgeItem?> touchLastRead(String id, {DateTime? now}) async {
    final KnowledgeItem? item = await getById(id);
    if (item == null) return null;
    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final KnowledgeItem updated = item.copyWith(
      lastReadAt: timestamp,
      updatedAt: timestamp,
    );
    await _db.update(
      'knowledge_items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    return updated;
  }

  Future<KnowledgeItem?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_items',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KnowledgeItem.fromMap(rows.first);
  }

  Future<KnowledgeItem?> findSimilar(String topicId, String content) async {
    final String normalized = normalizeContent(content).toLowerCase();
    if (normalized.isEmpty) return null;
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_items',
      where: 'topic_id = ?',
      whereArgs: <Object>[topicId],
    );
    for (final Map<String, Object?> row in rows) {
      final String existing = normalizeContent(
        (row['content'] ?? '') as String,
      ).toLowerCase();
      if (existing == normalized) return KnowledgeItem.fromMap(row);
    }
    return null;
  }

  Future<List<KnowledgeItem>> listByTopic(
    String topicId, {
    bool includePaused = true,
    String? query,
  }) async {
    final List<String> where = <String>['topic_id = ?'];
    final List<Object> args = <Object>[topicId];
    if (!includePaused) {
      where.add('is_paused = 0');
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add(
        '(LOWER(title) LIKE ? OR LOWER(content) LIKE ? OR LOWER(details) LIKE ?)',
      );
      final String like = '%${query.trim().toLowerCase()}%';
      args.addAll(<Object>[like, like, like]);
    }
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_items',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(KnowledgeItem.fromMap).toList(growable: false);
  }

  Future<List<KnowledgeItem>> search(String query) async {
    final String value = query.trim();
    if (value.isEmpty) return const <KnowledgeItem>[];
    final String like = '%${value.toLowerCase()}%';
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_items',
      where:
          'LOWER(title) LIKE ? OR LOWER(content) LIKE ? OR LOWER(details) LIKE ?',
      whereArgs: <Object>[like, like, like],
      orderBy: 'updated_at DESC',
      limit: 200,
    );
    return rows.map(KnowledgeItem.fromMap).toList(growable: false);
  }

  Future<KnowledgeItem> update(KnowledgeItem item) async {
    final String cleanTitle = item.title.trim();
    final String cleanContent = item.content.trim();
    if (cleanTitle.isEmpty) {
      throw const ValidationException(
        'Tiêu đề không được để trống.',
        field: 'title',
      );
    }
    if (cleanContent.isEmpty) {
      throw const ValidationException(
        'Nội dung không được để trống.',
        field: 'content',
      );
    }
    final KnowledgeItem updated = item.copyWith(
      title: cleanTitle,
      content: cleanContent,
      updatedAt: DateTime.now().toUtc(),
    );
    final int count = await _db.update(
      'knowledge_items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[item.id],
    );
    if (count == 0) {
      throw const NotFoundException('Không tìm thấy kiến thức.');
    }
    return updated;
  }

  Future<void> toggleFavorite(String id, {required bool value}) async {
    await _db.update(
      'knowledge_items',
      <String, Object?>{'is_favorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> setPaused(String id, {required bool paused}) async {
    await _db.update(
      'knowledge_items',
      <String, Object?>{'is_paused': paused ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> delete(String id) async {
    await _db.transaction((Transaction txn) async {
      await txn.rawDelete(
        'DELETE FROM review_logs WHERE card_id IN '
        '(SELECT id FROM review_cards WHERE knowledge_item_id = ?)',
        <Object>[id],
      );
      await txn.delete(
        'review_cards',
        where: 'knowledge_item_id = ?',
        whereArgs: <Object>[id],
      );
      await txn.delete(
        'knowledge_items',
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    });
  }

  Future<int> countAll() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM knowledge_items',
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  Future<TopicRef?> _topicRef(String topicId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'topics',
      columns: <String>['id', 'is_active'],
      where: 'id = ?',
      whereArgs: <Object>[topicId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TopicRef(
      id: rows.first['id']! as String,
      isActive: ((rows.first['is_active'] ?? 1) as int) == 1,
    );
  }
}

class TopicRef {
  const TopicRef({required this.id, required this.isActive});

  final String id;
  final bool isActive;
}

class SourceRepository {
  SourceRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  Future<Source> create({
    String? topicId,
    required SourceType type,
    String title = '',
    String? storagePath,
    String contentText = '',
    SourceStatus status = SourceStatus.ready,
    String? referenceUrl,
    String? referenceLocation,
    String? errorMessage,
    DateTime? now,
  }) async {
    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final Source source = Source(
      id: newId('src'),
      topicId: topicId,
      type: type,
      title: title.trim(),
      storagePath: storagePath,
      contentText: contentText,
      status: status,
      referenceUrl: referenceUrl,
      referenceLocation: referenceLocation,
      errorMessage: errorMessage,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _db.insert('sources', source.toMap());
    return source;
  }

  Future<Source?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'sources',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Source.fromMap(rows.first);
  }

  Future<List<Source>> listByTopic(String topicId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'sources',
      where: 'topic_id = ?',
      whereArgs: <Object>[topicId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Source.fromMap).toList(growable: false);
  }

  Future<Source> update(Source source) async {
    final Source updated = source.copyWith(updatedAt: DateTime.now().toUtc());
    final int count = await _db.update(
      'sources',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[source.id],
    );
    if (count == 0) {
      throw const NotFoundException('Không tìm thấy nguồn.');
    }
    return updated;
  }

  Future<void> updateStatus(
    String id, {
    required SourceStatus status,
    String? contentText,
    String? errorMessage,
  }) async {
    await _db.update(
      'sources',
      <String, Object?>{
        'status': status.dbValue,
        'content_text': ?contentText,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> delete(String id) async {
    await _db.update(
      'knowledge_items',
      <String, Object?>{'source_id': null},
      where: 'source_id = ?',
      whereArgs: <Object>[id],
    );
    await _db.delete('sources', where: 'id = ?', whereArgs: <Object>[id]);
  }
}
