import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/enums.dart';

class DailyReviewStat {
  const DailyReviewStat({
    required this.day,
    required this.count,
    required this.againCount,
  });

  final DateTime day;
  final int count;
  final int againCount;
}

class TopicProgressStat {
  const TopicProgressStat({
    required this.topicId,
    required this.topicName,
    required this.icon,
    required this.totalCards,
    required this.reviewedCards,
  });

  final String topicId;
  final String topicName;
  final String icon;
  final int totalCards;
  final int reviewedCards;

  double get progress => totalCards == 0 ? 0 : reviewedCards / totalCards;
}

class OverallStats {
  const OverallStats({
    required this.topicCount,
    required this.knowledgeCount,
    required this.cardCount,
    required this.dueCount,
    required this.overdueCount,
    required this.totalReviews,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
  });

  final int topicCount;
  final int knowledgeCount;
  final int cardCount;
  final int dueCount;
  final int overdueCount;
  final int totalReviews;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;

  double get accuracy =>
      totalReviews == 0 ? 0 : (totalReviews - againCount) / totalReviews;
}

class StatsRepository {
  StatsRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  Future<OverallStats> overall({required DateTime now}) async {
    final int nowMs = now.toUtc().millisecondsSinceEpoch;
    final DateTime startOfToday = DateTime.utc(
      now.toLocal().year,
      now.toLocal().month,
      now.toLocal().day,
    );
    final List<Map<String, Object?>> topics = await _db.rawQuery(
      'SELECT COUNT(*) AS t FROM topics WHERE is_active = 1',
    );
    final List<Map<String, Object?>> knowledge = await _db.rawQuery(
      'SELECT COUNT(*) AS t FROM knowledge_items',
    );
    final List<Map<String, Object?>> cards = await _db.rawQuery(
      'SELECT COUNT(*) AS t FROM review_cards WHERE is_active = 1',
    );
    final List<Map<String, Object?>> due = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS t
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      WHERE c.is_active = 1 AND k.is_paused = 0 AND c.due_at <= ?
      ''',
      <Object>[nowMs],
    );
    final List<Map<String, Object?>> overdue = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS t
      FROM review_cards c
      JOIN knowledge_items k ON k.id = c.knowledge_item_id
      WHERE c.is_active = 1 AND k.is_paused = 0 AND c.reps > 0 AND c.due_at < ?
      ''',
      <Object>[startOfToday.toUtc().millisecondsSinceEpoch],
    );
    final List<Map<String, Object?>> logs = await _db.rawQuery(
      'SELECT rating, COUNT(*) AS t FROM review_logs GROUP BY rating',
    );
    int again = 0, hard = 0, good = 0, easy = 0, total = 0;
    for (final Map<String, Object?> row in logs) {
      final int count = ((row['t'] ?? 0) as num).toInt();
      total += count;
      switch ((row['rating']! as num).toInt()) {
        case 1:
          again += count;
        case 2:
          hard += count;
        case 3:
          good += count;
        case 4:
          easy += count;
      }
    }
    return OverallStats(
      topicCount: ((topics.first['t'] ?? 0) as num).toInt(),
      knowledgeCount: ((knowledge.first['t'] ?? 0) as num).toInt(),
      cardCount: ((cards.first['t'] ?? 0) as num).toInt(),
      dueCount: ((due.first['t'] ?? 0) as num).toInt(),
      overdueCount: ((overdue.first['t'] ?? 0) as num).toInt(),
      totalReviews: total,
      againCount: again,
      hardCount: hard,
      goodCount: good,
      easyCount: easy,
    );
  }

  Future<List<DailyReviewStat>> dailyReviews({
    required DateTime from,
    required DateTime to,
  }) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      '''
      SELECT
        (reviewed_at / 86400000) AS day_index,
        COUNT(*) AS t,
        SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) AS again_t
      FROM review_logs
      WHERE reviewed_at >= ? AND reviewed_at < ?
      GROUP BY day_index
      ORDER BY day_index ASC
      ''',
      <Object>[
        from.toUtc().millisecondsSinceEpoch,
        to.toUtc().millisecondsSinceEpoch,
      ],
    );
    return rows
        .map((Map<String, Object?> row) {
          final int dayIndex = ((row['day_index'] ?? 0) as num).toInt();
          return DailyReviewStat(
            day: DateTime.fromMillisecondsSinceEpoch(
              dayIndex * 86400000,
              isUtc: true,
            ),
            count: ((row['t'] ?? 0) as num).toInt(),
            againCount: ((row['again_t'] ?? 0) as num).toInt(),
          );
        })
        .toList(growable: false);
  }

  Future<List<TopicProgressStat>> topicProgress() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery('''
      SELECT
        t.id AS id, t.name AS name, t.icon AS icon,
        COUNT(c.id) AS total_cards,
        SUM(CASE WHEN c.reps > 0 THEN 1 ELSE 0 END) AS reviewed_cards
      FROM topics t
      LEFT JOIN knowledge_items k ON k.topic_id = t.id
      LEFT JOIN review_cards c ON c.knowledge_item_id = k.id AND c.is_active = 1
      WHERE t.is_active = 1
      GROUP BY t.id
      ORDER BY t.created_at DESC
      ''');
    return rows
        .map((Map<String, Object?> row) {
          return TopicProgressStat(
            topicId: row['id']! as String,
            topicName: row['name']! as String,
            icon: (row['icon'] ?? '') as String,
            totalCards: ((row['total_cards'] ?? 0) as num).toInt(),
            reviewedCards: ((row['reviewed_cards'] ?? 0) as num).toInt(),
          );
        })
        .toList(growable: false);
  }

  Future<Map<MemoryRating, int>> ratingBreakdown() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT rating, COUNT(*) AS t FROM review_logs GROUP BY rating',
    );
    final Map<MemoryRating, int> result = <MemoryRating, int>{
      for (final MemoryRating r in MemoryRating.values) r: 0,
    };
    for (final Map<String, Object?> row in rows) {
      result[MemoryRating.fromValue((row['rating']! as num).toInt())] =
          ((row['t'] ?? 0) as num).toInt();
    }
    return result;
  }

  Future<int> newTopicsSince(DateTime from) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS t FROM topics WHERE created_at >= ?',
      <Object>[from.toUtc().millisecondsSinceEpoch],
    );
    return ((rows.first['t'] ?? 0) as num).toInt();
  }

  Future<int> reviewsToday({required DateTime now}) async {
    final DateTime local = now.toLocal();
    final DateTime start = DateTime(local.year, local.month, local.day);
    final DateTime end = start.add(const Duration(days: 1));
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS t FROM review_logs WHERE reviewed_at >= ? AND reviewed_at < ?',
      <Object>[
        start.toUtc().millisecondsSinceEpoch,
        end.toUtc().millisecondsSinceEpoch,
      ],
    );
    return ((rows.first['t'] ?? 0) as num).toInt();
  }
}
