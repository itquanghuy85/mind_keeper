import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/id_generator.dart';
import '../db/app_database.dart';
import '../models/due_review_item.dart';
import '../models/enums.dart';
import '../models/review_card.dart';
import '../models/review_log.dart';

class ReviewRepository {
  ReviewRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  static const String _dueWhere = '''
c.is_active = 1
AND k.is_paused = 0
AND k.title IS NOT NULL
AND c.due_at <= ?''';

  Future<ReviewCard> create({
    required String knowledgeItemId,
    required String question,
    required String answer,
    QuestionType questionType = QuestionType.recall,
    required DateTime dueAt,
    DateTime? now,
  }) async {
    final String cleanQuestion = question.trim();
    final String cleanAnswer = answer.trim();
    if (cleanQuestion.isEmpty) {
      throw const ValidationException(
        'Câu hỏi không được để trống.',
        field: 'question',
      );
    }
    if (cleanAnswer.isEmpty) {
      throw const ValidationException(
        'Đáp án không được để trống.',
        field: 'answer',
      );
    }
    final List<Map<String, Object?>> owner = await _db.query(
      'knowledge_items',
      columns: <String>['id'],
      where: 'id = ?',
      whereArgs: <Object>[knowledgeItemId],
      limit: 1,
    );
    if (owner.isEmpty) {
      throw const NotFoundException('Kiến thức không tồn tại.');
    }

    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final ReviewCard card = ReviewCard(
      id: newId('rc'),
      knowledgeItemId: knowledgeItemId,
      question: cleanQuestion,
      answer: cleanAnswer,
      questionType: questionType,
      dueAt: dueAt.toUtc(),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _db.insert('review_cards', card.toMap());
    return card;
  }

  Future<ReviewCard?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'review_cards',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReviewCard.fromMap(rows.first);
  }

  Future<List<ReviewCard>> listByKnowledgeItem(String knowledgeItemId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'review_cards',
      where: 'knowledge_item_id = ? AND is_active = 1',
      whereArgs: <Object>[knowledgeItemId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ReviewCard.fromMap).toList(growable: false);
  }

  /// Mọi thẻ của một kiến thức, KỂ CẢ thẻ chưa kích hoạt (is_active = 0).
  Future<List<ReviewCard>> listAllByKnowledgeItem(String knowledgeItemId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'review_cards',
      where: 'knowledge_item_id = ?',
      whereArgs: <Object>[knowledgeItemId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ReviewCard.fromMap).toList(growable: false);
  }

  Future<List<ReviewCard>> listDue({
    required DateTime now,
    int? limit,
    bool includeNew = true,
  }) async {
    final String extra = includeNew ? '' : 'AND c.reps > 0';
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''
      SELECT c.*
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      WHERE $_dueWhere $extra
      ORDER BY c.due_at ASC, c.created_at ASC
      ${limit == null ? '' : 'LIMIT $limit'}
      ''',
      <Object>[now.toUtc().millisecondsSinceEpoch],
    );
    return rows.map(ReviewCard.fromMap).toList(growable: false);
  }

  Future<int> countDue({required DateTime now, bool includeNew = true}) async {
    final String extra = includeNew ? '' : 'AND c.reps > 0';
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      WHERE $_dueWhere $extra
      ''',
      <Object>[now.toUtc().millisecondsSinceEpoch],
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  static const String _contextSelect = '''
  SELECT
    c.id AS c_id, c.knowledge_item_id AS c_knowledge_item_id,
    c.question AS c_question, c.answer AS c_answer,
    c.question_type AS c_question_type, c.fsrs_state AS c_fsrs_state,
    c.fsrs_step AS c_fsrs_step, c.stability AS c_stability,
    c.difficulty AS c_difficulty, c.due_at AS c_due_at,
    c.last_review_at AS c_last_review_at, c.reps AS c_reps,
    c.lapses AS c_lapses, c.is_active AS c_is_active,
    c.created_at AS c_created_at, c.updated_at AS c_updated_at,
    k.id AS k_id, k.topic_id AS k_topic_id, k.source_id AS k_source_id,
    k.title AS k_title, k.content AS k_content, k.details AS k_details,
    k.origin AS k_origin, k.is_favorite AS k_is_favorite,
    k.is_paused AS k_is_paused, k.created_at AS k_created_at,
    k.updated_at AS k_updated_at,
    t.id AS t_id, t.name AS t_name, t.description AS t_description,
    t.category AS t_category, t.icon AS t_icon, t.origin AS t_origin,
    t.is_active AS t_is_active, t.created_at AS t_created_at,
    t.updated_at AS t_updated_at
  FROM review_cards c
  JOIN knowledge_items k ON k.id = c.knowledge_item_id
  JOIN topics t ON t.id = k.topic_id
  WHERE c.is_active = 1 AND k.is_paused = 0 AND c.due_at <= ?
  ORDER BY c.due_at ASC, c.created_at ASC
  ''';

  static Map<String, Object?> _pick(Map<String, Object?> row, String prefix) {
    final String p = '${prefix}_';
    return <String, Object?>{
      for (final MapEntry<String, Object?> e in row.entries)
        if (e.key.startsWith(p)) e.key.substring(p.length): e.value,
    };
  }

  static DueReviewItem _toDueItem(Map<String, Object?> row) =>
      DueReviewItem.fromRows(
        cardRow: _pick(row, 'c'),
        knowledgeRow: _pick(row, 'k'),
        topicRow: _pick(row, 't'),
      );

  Future<List<DueReviewItem>> listDueWithContext({
    required DateTime now,
    int? limit,
  }) async {
    final String sql = limit == null
        ? _contextSelect
        : '$_contextSelect LIMIT $limit';
    final List<Map<String, Object?>> rows = await _db.rawQuery(sql, <Object>[
      now.toUtc().millisecondsSinceEpoch,
    ]);
    return rows.map(_toDueItem).toList(growable: false);
  }

  Future<DueReviewItem?> getByIdWithContext(String cardId) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''
      SELECT
        c.id AS c_id, c.knowledge_item_id AS c_knowledge_item_id,
        c.question AS c_question, c.answer AS c_answer,
        c.question_type AS c_question_type, c.fsrs_state AS c_fsrs_state,
        c.fsrs_step AS c_fsrs_step, c.stability AS c_stability,
        c.difficulty AS c_difficulty, c.due_at AS c_due_at,
        c.last_review_at AS c_last_review_at, c.reps AS c_reps,
        c.lapses AS c_lapses, c.is_active AS c_is_active,
        c.created_at AS c_created_at, c.updated_at AS c_updated_at,
        k.id AS k_id, k.topic_id AS k_topic_id, k.source_id AS k_source_id,
        k.title AS k_title, k.content AS k_content, k.details AS k_details,
        k.origin AS k_origin, k.is_favorite AS k_is_favorite,
        k.is_paused AS k_is_paused, k.created_at AS k_created_at,
        k.updated_at AS k_updated_at,
        t.id AS t_id, t.name AS t_name, t.description AS t_description,
        t.category AS t_category, t.icon AS t_icon, t.origin AS t_origin,
        t.is_active AS t_is_active, t.created_at AS t_created_at,
        t.updated_at AS t_updated_at
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      JOIN topics t ON t.id = k.topic_id
      WHERE c.id = ?
      LIMIT 1
      ''',
      <Object>[cardId],
    );
    if (rows.isEmpty) return null;
    return _toDueItem(rows.first);
  }

  Future<Map<String, int>> countDueByTopic({required DateTime now}) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''
      SELECT k.topic_id AS topic_id, COUNT(*) AS total
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      WHERE $_dueWhere
      GROUP BY k.topic_id
      ''',
      <Object>[now.toUtc().millisecondsSinceEpoch],
    );
    return <String, int>{
      for (final Map<String, Object?> row in rows)
        row['topic_id']! as String: ((row['total'] ?? 0) as num).toInt(),
    };
  }

  Future<int> countOverdue({required DateTime startOfTodayUtc}) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      WHERE c.is_active = 1
        AND k.is_paused = 0
        AND c.reps > 0
        AND c.due_at < ?
      ''',
      <Object>[startOfTodayUtc.toUtc().millisecondsSinceEpoch],
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  Future<int> countAll({bool activeOnly = true}) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      activeOnly
          ? 'SELECT COUNT(*) AS total FROM review_cards WHERE is_active = 1'
          : 'SELECT COUNT(*) AS total FROM review_cards',
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  Future<void> updateSchedule(ReviewCard card) async {
    final int count = await _db.update(
      'review_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[card.id],
    );
    if (count == 0) {
      throw const NotFoundException('Không tìm thấy thẻ ôn tập.');
    }
  }

  Future<void> setActive(String id, {required bool active}) async {
    await _db.update(
      'review_cards',
      <String, Object?>{
        'is_active': active ? 1 : 0,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> delete(String id) async {
    await _db.transaction((Transaction txn) async {
      await txn.delete(
        'review_logs',
        where: 'card_id = ?',
        whereArgs: <Object>[id],
      );
      await txn.delete(
        'review_cards',
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    });
  }

  Future<void> deleteByKnowledgeItem(String knowledgeItemId) async {
    await _db.transaction((Transaction txn) async {
      await txn.rawDelete(
        'DELETE FROM review_logs WHERE card_id IN '
        '(SELECT id FROM review_cards WHERE knowledge_item_id = ?)',
        <Object>[knowledgeItemId],
      );
      await txn.delete(
        'review_cards',
        where: 'knowledge_item_id = ?',
        whereArgs: <Object>[knowledgeItemId],
      );
    });
  }

  Future<void> saveReview({
    required ReviewCard updatedCard,
    required ReviewLog log,
  }) async {
    await _db.transaction((Transaction txn) async {
      final int count = await txn.update(
        'review_cards',
        updatedCard.toMap(),
        where: 'id = ?',
        whereArgs: <Object>[updatedCard.id],
      );
      if (count == 0) {
        throw const NotFoundException('Thẻ ôn tập không còn tồn tại.');
      }
      await txn.insert('review_logs', log.toMap());
    });
  }
}

class ReviewLogRepository {
  ReviewLogRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  Future<void> insert(ReviewLog log) async {
    await _db.insert('review_logs', log.toMap());
  }

  Future<List<ReviewLog>> listByCard(String cardId, {int? limit}) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'review_logs',
      where: 'card_id = ?',
      whereArgs: <Object>[cardId],
      orderBy: 'reviewed_at DESC',
      limit: limit,
    );
    return rows.map(ReviewLog.fromMap).toList(growable: false);
  }

  Future<List<ReviewLog>> listRange(DateTime from, DateTime to) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'review_logs',
      where: 'reviewed_at >= ? AND reviewed_at < ?',
      whereArgs: <Object>[
        from.toUtc().millisecondsSinceEpoch,
        to.toUtc().millisecondsSinceEpoch,
      ],
      orderBy: 'reviewed_at ASC',
    );
    return rows.map(ReviewLog.fromMap).toList(growable: false);
  }

  Future<int> countRange(DateTime from, DateTime to) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM review_logs '
      'WHERE reviewed_at >= ? AND reviewed_at < ?',
      <Object>[
        from.toUtc().millisecondsSinceEpoch,
        to.toUtc().millisecondsSinceEpoch,
      ],
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  Future<void> deleteByCard(String cardId) async {
    await _db.delete(
      'review_logs',
      where: 'card_id = ?',
      whereArgs: <Object>[cardId],
    );
  }
}
