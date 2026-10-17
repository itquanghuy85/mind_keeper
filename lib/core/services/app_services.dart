import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../features/ai/ai_service.dart';
import '../../features/discover/discovery_service.dart';
import '../../features/lessons/lesson_service.dart';
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
    final AiService aiService = ai ?? AiService();
    aiService.configureFromSettings(
      baseUrl: preferences.aiBaseUrl,
      apiKey: preferences.aiApiKey,
      model: preferences.aiModel,
    );
    final NotificationService notificationService =
        notifications ?? LocalNotificationService();
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
      scheduler: scheduler ?? ReviewSchedulerService(),
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
        scheduler: scheduler ?? ReviewSchedulerService(),
        notifications: notificationService,
        prefs: preferences,
        ai: aiService,
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
