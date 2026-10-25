import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/app_providers.dart';
import 'core/services/app_services.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_button.dart';
import 'features/discover/discover_screen.dart';
import 'features/import/link_import_screen.dart';
import 'features/import/text_import_screen.dart';
import 'features/knowledge/knowledge_detail_screen.dart';
import 'features/knowledge/knowledge_editor_screen.dart';
import 'features/knowledge/knowledge_library_screen.dart';
import 'features/knowledge/learned_library_screen.dart';
import 'features/lessons/lesson_discover_screen.dart';
import 'features/lessons/lesson_reader_screen.dart';
import 'package:mind_keeper/features/profile/notification_settings_screen.dart';
import 'package:mind_keeper/features/profile/study_plan_screen.dart';
import 'features/review/review_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/topics/create_topic_screen.dart';
import 'features/topics/topic_detail_screen.dart';

class MindKeeperApp extends StatelessWidget {
  const MindKeeperApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(services),
      child: MaterialApp(
        title: 'MindKeeper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        locale: const Locale('vi'),
        supportedLocales: const <Locale>[Locale('vi'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.home,
        onGenerateRoute: buildAppRoute,
      ),
    );
  }
}

abstract final class AppRoutes {
  static const String home = '/';
  static const String discover = '/discover';
  static const String review = '/review';
  static const String reviewSession = '/review/session';
  static const String articleDetail = '/article/detail';
  static const String quickInfoDetail = '/quick-info/detail';
  static const String createTopic = '/topics/create';
  static const String topicDetail = '/topics/detail';
  static const String knowledgeEditor = '/knowledge/editor';
  static const String knowledgeDetail = '/knowledge/detail';
  static const String knowledgeLibrary = '/knowledge/library';
  static const String learnedLibrary = '/knowledge/learned';
  static const String textImport = '/import/text';
  static const String linkImport = '/import/link';
  static const String notificationSettings = '/settings/notifications';
  static const String studyPlan = '/settings/study-plan';
  static const String lessonDiscover = '/lessons/discover';
  static const String lessonRead = '/lessons/read';
}

Route<dynamic>? buildAppRoute(RouteSettings settings) {
  final Object? args = settings.arguments;
  return switch (settings.name) {
    AppRoutes.home || null => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const AppShell(),
    ),
    AppRoutes.discover => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const DiscoverScreen(),
    ),
    AppRoutes.review => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => ReviewScreen(targetCardId: args is String ? args : null),
    ),
    AppRoutes.reviewSession => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const ReviewScreen(),
    ),
    AppRoutes.articleDetail => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => KnowledgeDetailScreen(itemId: args is String ? args : ''),
    ),
    AppRoutes.quickInfoDetail => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => KnowledgeDetailScreen(itemId: args is String ? args : ''),
    ),
    AppRoutes.createTopic => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const CreateTopicScreen(),
    ),
    AppRoutes.topicDetail => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => TopicDetailScreen(topicId: args! as String),
    ),
    AppRoutes.knowledgeEditor => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) =>
          args is KnowledgeEditorScreen ? args : const SizedBox.shrink(),
    ),
    AppRoutes.knowledgeDetail => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => KnowledgeDetailScreen(itemId: args! as String),
    ),
    AppRoutes.knowledgeLibrary => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => KnowledgeLibraryScreen(topicId: args! as String),
    ),
    AppRoutes.learnedLibrary => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const LearnedLibraryScreen(),
    ),
    AppRoutes.textImport => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => TextImportScreen(topicId: args is String ? args : null),
    ),
    AppRoutes.linkImport => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const LinkImportScreen(),
    ),
    AppRoutes.notificationSettings => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const NotificationSettingsScreen(),
    ),
    AppRoutes.studyPlan => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const StudyPlanScreen(),
    ),
    AppRoutes.lessonDiscover => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const LessonDiscoverScreen(),
    ),
    AppRoutes.lessonRead => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => LessonReaderScreen(lessonId: args! as String),
    ),
    _ => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const UnknownRouteScreen(),
    ),
  };
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Trang bạn tìm không tồn tại.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Về trang chủ',
                expanded: false,
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
