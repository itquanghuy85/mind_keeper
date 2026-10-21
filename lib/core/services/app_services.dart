import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/knowledge_generation_repository.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/study_feed_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../features/ai/ai_service.dart';
import '../../features/discover/discovery_service.dart';
import '../../features/knowledge/knowledge_generation_service.dart';
import '../../features/lessons/lesson_service.dart';
import '../../features/study/study_plan_service.dart';
import 'knowledge_reminder_scheduler.dart';
import 'notification_service.dart';
import 'preferences_service.dart';
import 'review_scheduler_service.dart';

/// Service locator tập trung — nạp ở bootstrap, inject qua Provider.
class AppServices {
  AppServices({
    required this.database,
    required this.topics,
    required this.knowledge,
    required this.sources,
    required this.cards,
    required this.logs,
    required this.stats,
    required this.lessons,
    required this.prefs,
    required this.notifications,
    required this.scheduler,
    required this.ai,
    required this.discovery,
    required this.lessonService,
    required this.knowledgeGeneration,
    required this.knowledgeReminders,
    required this.studyPlan,
  });

  final AppDatabase database;
  final TopicRepository topics;
  final KnowledgeRepository knowledge;
  final SourceRepository sources;
  final ReviewRepository cards;
  final ReviewLogRepository logs;
  final StatsRepository stats;
  final LessonRepository lessons;
  final PreferencesService prefs;
  final NotificationService notifications;
  final ReviewSchedulerService scheduler;
  final AiService ai;
  final DiscoveryService discovery;
  final LessonService lessonService;
  final KnowledgeGenerationService knowledgeGeneration;
  final KnowledgeReminderScheduler knowledgeReminders;
  final StudyPlanService studyPlan;

  static AppServices build({
    required AppDatabase database,
    required SharedPreferences prefs,
    NotificationService? notifications,
    ReviewSchedulerService? scheduler,
    AiService? ai,
  }) {
    final PreferencesService preferences = PreferencesService(prefs);
    final TopicRepository topics = TopicRepository(database);
    final KnowledgeRepository knowledge = KnowledgeRepository(database);
    final SourceRepository sources = SourceRepository(database);
    final ReviewRepository cards = ReviewRepository(database);
    final ReviewLogRepository logs = ReviewLogRepository(database);
    final StatsRepository stats = StatsRepository(database);
    final LessonRepository lessons = LessonRepository(database);
    final StudyFeedRepository studyFeed = StudyFeedRepository(database);
    final KnowledgeGenerationRepository knowledgeGenerationRepo =
        KnowledgeGenerationRepository(database);
    final AiService aiService = ai ?? AiService();
    // Cấu hình DeepSeek mặc định từ environment variables
    final bool configured = aiService.configureDeepSeekDefault(
      apiKey: preferences.aiApiKey,
      baseUrl: preferences.aiBaseUrl,
      model: preferences.aiModel,
      proxyMode: preferences.aiProxyMode,
    );
    if (!configured) {
      // Log warning in debug mode
      if (kDebugMode) {
        debugPrint(
          '⚠️ AI: Chưa cấu hình API key DeepSeek. Dùng MockAIProvider. '
          'Set DEEPSEEK_API_KEY (hoặc DEEPSEEK_BASE_URL + DEEPSEEK_PROXY_MODE=true) '
          'khi build để bật AI thật.',
        );
      }
    }
    final NotificationService notificationService =
        notifications ?? LocalNotificationService();
    final ReviewSchedulerService reviewScheduler =
        scheduler ?? ReviewSchedulerService();
    return AppServices(
      database: database,
      topics: topics,
      knowledge: knowledge,
      sources: sources,
      cards: cards,
      logs: logs,
      stats: stats,
      lessons: lessons,
      prefs: preferences,
      notifications: notificationService,
      scheduler: reviewScheduler,
      ai: aiService,
      discovery: DiscoveryService(
        topics: topics,
        knowledge: knowledge,
        cards: cards,
        prefs: preferences,
      ),
      lessonService: LessonService(
        lessons: lessons,
        topics: topics,
        knowledge: knowledge,
        cards: cards,
        scheduler: reviewScheduler,
        notifications: notificationService,
        prefs: preferences,
        ai: aiService,
      ),
      knowledgeGeneration: KnowledgeGenerationService(
        topics: topics,
        knowledge: knowledge,
        lessons: lessons,
        generationRepo: knowledgeGenerationRepo,
        ai: aiService,
      ),
      knowledgeReminders: KnowledgeReminderScheduler(
        lessons: lessons,
        prefs: preferences,
        notifications: notificationService,
        database: database,
      ),
      studyPlan: StudyPlanService(
        prefs: preferences,
        feed: studyFeed,
        topics: topics,
        knowledge: knowledge,
        lessons: lessons,
        ai: aiService,
        notifications: notificationService,
      ),
    );
  }

  /// Mở DB với đường dẫn app documents (dùng cho runtime thật).
  static Future<AppServices> initialize({
    DatabaseFactory? factory,
    NotificationService? notifications,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? directory;
    try {
      final dynamic dir = await getApplicationDocumentsDirectory();
      directory = dir.path as String?;
    } catch (_) {
      directory = null;
    }
    final AppDatabase database = AppDatabase(
      factory: factory ?? databaseFactory,
      directory: directory,
    );
    await database.open();
    return build(
      database: database,
      prefs: prefs,
      notifications: notifications,
    );
  }

  Future<void> dispose() async {
    await database.close();
  }
}
