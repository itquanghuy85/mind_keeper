import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/repositories/knowledge_generation_repository.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../features/ai/ai_service.dart';
import '../../features/discover/discovery_service.dart';
import '../../features/knowledge/knowledge_generation_service.dart';
import '../../features/lessons/lesson_service.dart';
import '../../features/study/study_plan_service.dart';
import '../services/app_services.dart';
import '../services/preferences_service.dart';
import '../services/review_scheduler_service.dart';

List<SingleChildWidget> buildAppProviders(AppServices services) {
  return <SingleChildWidget>[
    Provider<AppServices>.value(value: services),
    ChangeNotifierProvider<PreferencesService>.value(value: services.prefs),
    Provider<TopicRepository>.value(value: services.topics),
    Provider<KnowledgeRepository>.value(value: services.knowledge),
    Provider<SourceRepository>.value(value: services.sources),
    Provider<ReviewRepository>.value(value: services.cards),
    Provider<ReviewLogRepository>.value(value: services.logs),
    Provider<StatsRepository>.value(value: services.stats),
    Provider<LessonRepository>.value(value: services.lessons),
    Provider<KnowledgeGenerationRepository>.value(
      value: services.knowledgeGeneration.generationRepo,
    ),
    Provider<ReviewSchedulerService>.value(value: services.scheduler),
    Provider<AiService>.value(value: services.ai),
    Provider<DiscoveryService>.value(value: services.discovery),
    Provider<LessonService>.value(value: services.lessonService),
    Provider<KnowledgeGenerationService>.value(
      value: services.knowledgeGeneration,
    ),
    Provider<StudyPlanService>.value(value: services.studyPlan),
  ];
}
