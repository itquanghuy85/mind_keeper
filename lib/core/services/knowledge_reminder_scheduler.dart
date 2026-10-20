import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../data/db/app_database.dart';
import '../../data/models/lesson.dart';
import '../../data/repositories/lesson_repository.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

class KnowledgeReminderPreviewItem {
  const KnowledgeReminderPreviewItem({
    required this.at,
    required this.lessonId,
    required this.lessonTitle,
    required this.snippet,
    this.snippetKey = '',
  });

  final DateTime at;
  final String lessonId;
  final String lessonTitle;
  final String snippet;
  final String snippetKey;
}

class _Snippet {
  const _Snippet({
    required this.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.text,
  });

  final String key;
  final String lessonId;
  final String lessonTitle;
  final String text;
}

class KnowledgeReminderScheduler {
  KnowledgeReminderScheduler({
    required this.lessons,
    required this.prefs,
    required this.notifications,
    required this.database,
  });

  final LessonRepository lessons;
  final PreferencesService prefs;
  final NotificationService notifications;
  final AppDatabase database;

  Database get _db => database.db;

  Future<List<_Snippet>> _buildSnippets() async {
    final List<Lesson> all = await lessons.list(limit: 1000);
    final List<String> selectedTopics = prefs.knowledgeReminderSelectedTopics;
    final bool selectedMode = prefs.knowledgeReminderSource == 'selected';
    final List<Lesson> filtered = selectedMode && selectedTopics.isNotEmpty
        ? all.where((Lesson l) => selectedTopics.contains(l.linkedTopicId)).toList()
        : all;

    final List<_Snippet> result = <_Snippet>[];
    for (final Lesson lesson in filtered) {
      final List<String> candidates = <String>[];
      candidates.addAll(lesson.content.keyPoints);
      if (lesson.content.summary.trim().isNotEmpty) {
        candidates.add(lesson.content.summary);
      }
      if (lesson.content.introduction.trim().isNotEmpty) {
        candidates.add(lesson.content.introduction);
      }
      if (candidates.isEmpty) {
        candidates.add(lesson.title);
      }
      int index = 0;
      for (final String raw in candidates) {
        final String text = raw.trim();
        if (text.isEmpty) continue;
        final String short = text.length > 160 ? '${text.substring(0, 157)}...' : text;
        result.add(
          _Snippet(
            key: '${lesson.id}:$index',
            lessonId: lesson.id,
            lessonTitle: lesson.title,
            text: short,
          ),
        );
        index++;
      }
    }
    return result;
  }

  Future<Map<String, DateTime>> _lastSentByKey(DateTime now) async {
    final int cutoff = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_reminder_history',
      where: 'sent_at >= ?',
      whereArgs: <Object>[cutoff],
      orderBy: 'sent_at ASC',
    );
    final Map<String, DateTime> map = <String, DateTime>{};
    for (final Map<String, Object?> row in rows) {
      final String key = (row['snippet_key'] ?? '') as String;
      final int sent = (row['sent_at'] as int?) ?? 0;
      map[key] = DateTime.fromMillisecondsSinceEpoch(sent, isUtc: true).toLocal();
    }
    return map;
  }

  Future<Map<String, DateTime>> _lastSentByLesson(DateTime now) async {
    final int cutoff = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final List<Map<String, Object?>> rows = await _db.query(
      'knowledge_reminder_history',
      where: 'sent_at >= ?',
      whereArgs: <Object>[cutoff],
      orderBy: 'sent_at ASC',
    );
    final Map<String, DateTime> map = <String, DateTime>{};
    for (final Map<String, Object?> row in rows) {
      final String lessonId = (row['lesson_id'] ?? '') as String;
      final int sent = (row['sent_at'] as int?) ?? 0;
      final DateTime dt = DateTime.fromMillisecondsSinceEpoch(sent, isUtc: true).toLocal();
      final DateTime? existing = map[lessonId];
      if (existing == null || dt.isAfter(existing)) {
        map[lessonId] = dt;
      }
    }
    return map;
  }

  List<DateTime> _slotTimes(DateTime day, int count) {
    final DateTime start = DateTime(
      day.year,
      day.month,
      day.day,
      prefs.knowledgeReminderStartHour,
      prefs.knowledgeReminderStartMinute,
    );
    int endHour = prefs.knowledgeReminderEndHour;
    int endMinute = prefs.knowledgeReminderEndMinute;
    DateTime end = DateTime(day.year, day.month, day.day, endHour, endMinute);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    final List<DateTime> slots = <DateTime>[];
    if (count <= 1) {
      slots.add(start);
      return slots;
    }
    final int totalMinutes = end.difference(start).inMinutes;
    for (int i = 0; i < count; i++) {
      final int offset = (totalMinutes * i / (count - 1)).round();
      slots.add(start.add(Duration(minutes: offset)));
    }
    return slots;
  }

  Future<List<KnowledgeReminderPreviewItem>> buildSchedule({DateTime? now}) async {
    final DateTime baseNow = now ?? DateTime.now();
    final List<_Snippet> snippets = await _buildSnippets();
    if (snippets.isEmpty) return const <KnowledgeReminderPreviewItem>[];

    final Map<String, DateTime> lastByKey = await _lastSentByKey(baseNow);
    final Map<String, DateTime> lastByLesson = await _lastSentByLesson(baseNow);
    final Set<String> recentKeys = lastByKey.keys.toSet();
    final Set<String> recentLessons = lastByLesson.keys.toSet();

    final List<KnowledgeReminderPreviewItem> chosen =
        <KnowledgeReminderPreviewItem>[];
    final Set<String> usedKeys = <String>{};

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final DateTime day = DateTime(
        baseNow.year,
        baseNow.month,
        baseNow.day,
      ).add(Duration(days: dayOffset));
      final List<DateTime> slots = _slotTimes(day, prefs.knowledgeReminderCountPerDay);
      for (final DateTime slot in slots) {
        if (!slot.isAfter(baseNow)) continue;
        List<_Snippet> available = snippets
            .where((_Snippet s) => !usedKeys.contains(s.key))
            .toList();
        if (available.isEmpty) available = List<_Snippet>.of(snippets);

        available.sort((_Snippet a, _Snippet b) {
          final bool aRecent = recentKeys.contains(a.key) || recentLessons.contains(a.lessonId);
          final bool bRecent = recentKeys.contains(b.key) || recentLessons.contains(b.lessonId);
          if (aRecent != bRecent) return aRecent ? 1 : -1;
          final DateTime aLast = lastByKey[a.key] ?? lastByLesson[a.lessonId] ?? DateTime(2000);
          final DateTime bLast = lastByKey[b.key] ?? lastByLesson[b.lessonId] ?? DateTime(2000);
          final int cmp = aLast.compareTo(bLast);
          if (cmp != 0) return cmp;
          return Random().nextInt(3) - 1;
        });

        final _Snippet pick = available.first;
        usedKeys.add(pick.key);
        chosen.add(
          KnowledgeReminderPreviewItem(
            at: slot,
            lessonId: pick.lessonId,
            lessonTitle: pick.lessonTitle,
            snippet: pick.text,
            snippetKey: pick.key,
          ),
        );
      }
    }
    return chosen;
  }

  Future<void> sync({DateTime? now}) async {
    final DateTime baseNow = now ?? DateTime.now();
    // cancel previous
    for (final int id in prefs.knowledgeReminderScheduledIds) {
      await notifications.cancelKnowledgeReminder(id);
    }
    await prefs.setKnowledgeReminderScheduledIds(const <int>[]);

    if (!prefs.knowledgeReminderEnabled) return;

    final bool? allowed = await notifications.areNotificationsEnabled();
    if (allowed == false) {
      // Permission denied: cancel any previously scheduled knowledge reminders.
      for (final int id in prefs.knowledgeReminderScheduledIds) {
        await notifications.cancelKnowledgeReminder(id);
      }
      await prefs.setKnowledgeReminderScheduledIds(const <int>[]);
      return;
    }

    final List<KnowledgeReminderPreviewItem> schedule = await buildSchedule(now: baseNow);
    if (schedule.isEmpty) return;

    final List<int> newIds = <int>[];
    int index = 0;
    for (final KnowledgeReminderPreviewItem item in schedule) {
      final int id = 700000 + index;
      await notifications.scheduleKnowledgeReminder(
        id: id,
        title: item.lessonTitle,
        body: item.snippet,
        at: item.at,
        payload: 'lesson:${item.lessonId}',
      );
      newIds.add(id);
      // persist history
      await _db.insert('knowledge_reminder_history', <String, Object?>{
        'id': 'krh_${item.lessonId}_${item.at.millisecondsSinceEpoch}',
        'lesson_id': item.lessonId,
        'snippet_key': item.snippetKey.isNotEmpty
            ? item.snippetKey
            : '${item.lessonId}:${item.snippet.hashCode}',
        'snippet': item.snippet,
        'sent_at': item.at.toUtc().millisecondsSinceEpoch,
        'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      index++;
    }
    await prefs.setKnowledgeReminderScheduledIds(newIds);
  }

  Future<void> cancel() async {
    for (final int id in prefs.knowledgeReminderScheduledIds) {
      await notifications.cancelKnowledgeReminder(id);
    }
    await prefs.setKnowledgeReminderScheduledIds(const <int>[]);
  }
}