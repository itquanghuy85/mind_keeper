import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/id_generator.dart';
import '../db/app_database.dart';
import '../models/enums.dart';
import '../models/topic.dart';

class TopicRepository {
  TopicRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  static String normalizeName(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<Topic> create({
    required String name,
    String description = '',
    String category = '',
    String icon = '',
    TopicOrigin origin = TopicOrigin.personal,
    DateTime? now,
  }) async {
    final String cleanName = normalizeName(name);
    if (cleanName.isEmpty) {
      throw const ValidationException('Tên chủ đề không được để trống.', field: 'name');
    }
    if (cleanName.length > 120) {
      throw const ValidationException('Tên chủ đề quá dài (tối đa 120 ký tự).', field: 'name');
    }
    final Topic? existing = await findByName(cleanName);
    if (existing != null) {
      throw const ValidationException('Chủ đề đã tồn tại.', field: 'name');
    }

    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final Topic topic = Topic(
      id: newId('tp'),
      name: cleanName,
      description: description.trim(),
      category: category.trim(),
      icon: icon.trim(),
      origin: origin,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _db.insert('topics', topic.toMap());
    return topic;
  }

  Future<Topic?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'topics',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Topic.fromMap(rows.first);
  }

  Future<Topic?> findByName(String name) async {
    final String clean = normalizeName(name);
    final List<Map<String, Object?>> rows = await _db.query(
      'topics',
      where: 'LOWER(name) = ?',
      whereArgs: <Object>[clean.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Topic.fromMap(rows.first);
  }

  Future<List<Topic>> list({
    bool activeOnly = true,
    String? query,
    TopicOrigin? origin,
    int? limit,
  }) async {
    final List<String> where = <String>[];
    final List<Object> args = <Object>[];
    if (activeOnly) {
      where.add('is_active = 1');
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add('(LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(category) LIKE ?)');
      final String like = '%${query.trim().toLowerCase()}%';
      args.addAll(<Object>[like, like, like]);
    }
    if (origin != null) {
      where.add('origin = ?');
      args.add(origin.dbValue);
    }

    final List<Map<String, Object?>> rows = await _db.query(
      'topics',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Topic.fromMap).toList(growable: false);
  }

  Future<Topic> update(Topic topic) async {
    final String cleanName = normalizeName(topic.name);
    if (cleanName.isEmpty) {
      throw const ValidationException('Tên chủ đề không được để trống.', field: 'name');
    }
    final Topic? clash = await findByName(cleanName);
    if (clash != null && clash.id != topic.id) {
      throw const ValidationException('Chủ đề đã tồn tại.', field: 'name');
    }
    final Topic updated = topic.copyWith(
      name: cleanName,
      updatedAt: DateTime.now().toUtc(),
    );
    final int count = await _db.update(
      'topics',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[topic.id],
    );
    if (count == 0) {
      throw const NotFoundException('Không tìm thấy chủ đề.');
    }
    return updated;
  }

  Future<void> setActive(String id, {required bool active}) async {
    await _db.update(
      'topics',
      <String, Object?>{
        'is_active': active ? 1 : 0,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<TopicStats> statsOf(String topicId) async {
    final List<Map<String, Object?>> knowledge = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM knowledge_items WHERE topic_id = ?',
      <Object>[topicId],
    );
    final List<Map<String, Object?>> due = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      WHERE k.topic_id = ?
        AND c.is_active = 1
        AND k.is_paused = 0
        AND c.due_at <= ?
      ''',
      <Object>[topicId, DateTime.now().toUtc().millisecondsSinceEpoch],
    );
    return TopicStats(
      knowledgeCount: ((knowledge.first['total'] ?? 0) as num).toInt(),
      dueCount: ((due.first['total'] ?? 0) as num).toInt(),
    );
  }

  Future<Map<String, TopicStats>> statsForTopics(List<String> topicIds) async {
    final Map<String, TopicStats> result = <String, TopicStats>{};
    for (final String id in topicIds) {
      result[id] = await statsOf(id);
    }
    return result;
  }

  Future<void> delete(String id) async {
    await _db.transaction((Transaction txn) async {
      await _deleteChildren(txn, id);
      await txn.delete('topics', where: 'id = ?', whereArgs: <Object>[id]);
    });
  }

  Future<void> _deleteChildren(Transaction txn, String topicId) async {
    await txn.rawDelete(
      'DELETE FROM review_logs WHERE card_id IN ('
      'SELECT c.id FROM review_cards c '
      'JOIN knowledge_items k ON k.id = c.knowledge_item_id WHERE k.topic_id = ?)',
      <Object>[topicId],
    );
    await txn.rawDelete(
      'DELETE FROM review_cards WHERE knowledge_item_id IN '
      '(SELECT id FROM knowledge_items WHERE topic_id = ?)',
      <Object>[topicId],
    );
    await txn.delete(
      'knowledge_items',
      where: 'topic_id = ?',
      whereArgs: <Object>[topicId],
    );
    await txn.delete(
      'sources',
      where: 'topic_id = ?',
      whereArgs: <Object>[topicId],
    );
  }

  Future<int> countAll({bool activeOnly = true}) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      activeOnly
          ? 'SELECT COUNT(*) AS total FROM topics WHERE is_active = 1'
          : 'SELECT COUNT(*) AS total FROM topics',
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }
}

class TopicStats {
  const TopicStats({required this.knowledgeCount, required this.dueCount});

  final int knowledgeCount;
  final int dueCount;
}
