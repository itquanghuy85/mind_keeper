import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../db/app_database.dart';
import '../models/lesson.dart';

class LessonRepository {
  LessonRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  /// Thêm bài học mới. Trả về bài đã có nếu dedup_key trùng (chống sinh lại).
  Future<Lesson> create(Lesson lesson) async {
    final Lesson? existing = await findByDedupKey(lesson.dedupKey);
    if (existing != null) return existing;
    await _db.insert('lessons', lesson.toRow());
    return lesson;
  }

  Future<Lesson?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'lessons',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Lesson.fromRow(rows.first);
  }

  Future<Lesson?> findByDedupKey(String dedupKey) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'lessons',
      where: 'dedup_key = ?',
      whereArgs: <Object>[dedupKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Lesson.fromRow(rows.first);
  }

  Future<List<Lesson>> list({
    String? domainId,
    String? query,
    bool favoritesOnly = false,
    bool unreadOnly = false,
    int? limit,
  }) async {
    final List<String> where = <String>[];
    final List<Object> args = <Object>[];
    if (domainId != null) {
      where.add('domain_id = ?');
      args.add(domainId);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add(
        '(LOWER(title) LIKE ? OR LOWER(topic) LIKE ? OR LOWER(domain_name) LIKE ?)',
      );
      final String like = '%${query.trim().toLowerCase()}%';
      args.addAll(<Object>[like, like, like]);
    }
    if (favoritesOnly) {
      where.add('is_favorite = 1');
    }
    if (unreadOnly) {
      where.add('is_read = 0');
    }
    final List<Map<String, Object?>> rows = await _db.query(
      'lessons',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Lesson.fromRow).toList(growable: false);
  }

  Future<void> setFavorite(String id, {required bool favorite}) async {
    await _updateFlags(id, <String, Object?>{'is_favorite': favorite ? 1 : 0});
  }

  Future<void> setRead(String id, {required bool read}) async {
    await _updateFlags(id, <String, Object?>{'is_read': read ? 1 : 0});
  }

  Future<void> setLinkedTopic(String id, {required String? topicId}) async {
    await _updateFlags(id, <String, Object?>{'linked_topic_id': topicId});
  }

  Future<void> setVerification(
    String id, {
    required LessonVerification verification,
  }) async {
    await _updateFlags(id, <String, Object?>{'verification': verification.id});
  }

  Future<void> _updateFlags(String id, Map<String, Object?> values) async {
    final Map<String, Object?> payload = <String, Object?>{
      ...values,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
    final int count = await _db.update(
      'lessons',
      payload,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    if (count == 0) {
      throw const NotFoundException('Không tìm thấy bài học.');
    }
  }

  /// Số bài học theo từng lĩnh vực (dùng cho lưới khám phá + thống kê).
  Future<Map<String, LessonDomainCount>> countByDomain() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery('''
      SELECT
        domain_id,
        COUNT(*) AS total,
        SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) AS read_t,
        SUM(CASE WHEN is_favorite = 1 THEN 1 ELSE 0 END) AS fav_t
      FROM lessons
      GROUP BY domain_id
      ''');
    final Map<String, LessonDomainCount> result = <String, LessonDomainCount>{};
    for (final Map<String, Object?> row in rows) {
      result[row['domain_id']! as String] = LessonDomainCount(
        total: ((row['total'] ?? 0) as num).toInt(),
        read: ((row['read_t'] ?? 0) as num).toInt(),
        favorites: ((row['fav_t'] ?? 0) as num).toInt(),
      );
    }
    return result;
  }

  Future<int> countAll() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM lessons',
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  Future<int> countRead() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM lessons WHERE is_read = 1',
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  Future<void> delete(String id) async {
    await _db.delete('lessons', where: 'id = ?', whereArgs: <Object>[id]);
  }
}

class LessonDomainCount {
  const LessonDomainCount({
    required this.total,
    required this.read,
    required this.favorites,
  });

  final int total;
  final int read;
  final int favorites;
}
