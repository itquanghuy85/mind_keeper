import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/knowledge_reminder_scheduler.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/features/ai/ai_service.dart';
import 'package:mind_keeper/features/ai/mock_ai_provider.dart';
import 'package:mind_keeper/features/discover/domain_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

Future<AppServices> buildServices() async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final db = await openMemoryDb();
  return AppServices.build(
    database: db,
    prefs: prefs,
    notifications: FakeNotificationService(),
    ai: AiService(provider: MockAIProvider(latency: Duration.zero)),
  );
}

void main() {
  group('KnowledgeReminderScheduler', () {
    test('empty library returns no schedule', () async {
      final services = await buildServices();
      final items = await services.knowledgeReminders.buildSchedule(
        now: DateTime(2026, 1, 1, 0, 0),
      );
      expect(items, isEmpty);
      await services.dispose();
    });

    test('distributes snippets without early duplicates', () async {
      final services = await buildServices();
      final domain = LearningDomains.byId('science')!;
      for (int i = 0; i < 3; i++) {
        await services.lessonService.generate(
          domain: domain,
          topic: 'Topic $i',
        );
      }
      await services.prefs.setKnowledgeReminderCountPerDay(2);
      final items = await services.knowledgeReminders.buildSchedule(
        now: DateTime(2026, 1, 1, 0, 0),
      );
      expect(items.length, 14);
      final keys = items.map((KnowledgeReminderPreviewItem e) => e.snippetKey).toList();
      expect(keys.toSet().length, keys.length);
      await services.dispose();
    });

    test('sync schedules notifications and persists history', () async {
      final services = await buildServices();
      final fake = services.notifications as FakeNotificationService;
      final domain = LearningDomains.byId('science')!;
      await services.lessonService.generate(domain: domain, topic: 'Topic 1');
      await services.prefs.setKnowledgeReminderEnabled(true);
      await services.prefs.setKnowledgeReminderCountPerDay(1);
      await services.knowledgeReminders.sync(now: DateTime(2026, 1, 1, 0, 0));
      expect(fake.scheduledKnowledgeReminders, isNotEmpty);
      final rows = await services.database.db.query('knowledge_reminder_history');
      expect(rows, isNotEmpty);
      for (final id in fake.scheduledKnowledgeReminders.keys) {
        expect(id, greaterThanOrEqualTo(700000));
      }
      await services.dispose();
    });

    test('permission denied cancels and does not schedule', () async {
      final services = await buildServices();
      final fake = services.notifications as FakeNotificationService;
      final domain = LearningDomains.byId('science')!;
      await services.lessonService.generate(domain: domain, topic: 'Topic 1');
      await services.prefs.setKnowledgeReminderEnabled(true);
      fake.notificationsEnabledStatus = false;
      await services.knowledgeReminders.sync(now: DateTime(2026, 1, 1, 0, 0));
      expect(fake.scheduledKnowledgeReminders, isEmpty);
      await services.dispose();
    });

    test('selected source filters by linked topic', () async {
      final services = await buildServices();
      final domain = LearningDomains.byId('science')!;
      final generated = await services.lessonService.generate(
        domain: domain,
        topic: 'Topic 1',
      );
      final topic = await services.topics.create(name: 'Selected Topic');
      await services.lessons.setLinkedTopic(generated.lesson.id, topicId: topic.id);
      await services.prefs.setKnowledgeReminderSelectedTopics(<String>[topic.id]);
      await services.prefs.setKnowledgeReminderSource('selected');
      // topic id set above

      final items = await services.knowledgeReminders.buildSchedule(
        now: DateTime(2026, 1, 1, 0, 0),
      );
      expect(items, isNotEmpty);
      expect(items.every((KnowledgeReminderPreviewItem e) => e.lessonId == generated.lesson.id), isTrue);
      await services.dispose();
    });
  });
}