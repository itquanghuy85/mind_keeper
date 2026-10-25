import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/services/preferences_service.dart';
import 'package:mind_keeper/core/di/app_providers.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:mind_keeper/features/ai/ai_provider.dart';
import 'package:mind_keeper/features/profile/study_plan_screen.dart';
import '../helpers/test_db.dart';

class F implements AIProvider {
  @override
  String get name => 'f';
  @override
  bool get isConfigured => true;
  @override
  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  }) async => sourceText.trim().isEmpty
      ? const []
      : [AiKnowledgeDraft(title: 't', content: 'x $sourceText', details: 'd')];
  @override
  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  }) async => [];
  @override
  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  }) async => const AiTutorExplanation(explanation: 'e');
  @override
  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  }) async => AiAnswerEvaluation(verdict: 'correct', comment: '');
  @override
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  }) async {
    final b = 'Detailed content about $topic with examples. ' * 8;
    return AiLessonDraft(
      title: 'L:$topic',
      learningObjectives: <String>['u'],
      introduction: 'i $b',
      concepts: const [],
      sections: [AiLessonSection(heading: 'h', body: b)],
      keyPoints: const [],
      examples: const [],
      commonMistakes: const [],
      summary: 's',
      questions: [AiQuestionDraft(question: 'q?', answer: 'a')],
      sources: const [],
      medical: false,
    );
  }

  @override
  Future<List<AiTopicSuggestion>> suggestTopics({
    required String domain,
    int count = 20,
  }) async => [];
}

void main() {
  group('StudyPlanScreen widget (GD17)', () {
    testWidgets('opens with default config and shows quota', (
      WidgetTester t,
    ) async {
      final s = await bs(qpd: 2, lpd: 1);
      await st(s, name: 'Atoms');
      await st(s, name: 'Evolution');
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppServices>.value(value: s),
            ChangeNotifierProvider<PreferencesService>.value(value: s.prefs),
            ...buildAppProviders(s),
          ],
          child: MaterialApp(home: StudyPlanScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Kế hoạch học'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('1 lesson'), findsOneWidget);
      await s.dispose();
    });
    testWidgets('shows topics tracked', (WidgetTester t) async {
      final s = await bs();
      await st(s, name: 'A');
      await st(s, name: 'B');
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppServices>.value(value: s),
            ChangeNotifierProvider<PreferencesService>.value(value: s.prefs),
            ...buildAppProviders(s),
          ],
          child: MaterialApp(home: StudyPlanScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('2 subjects being tracked'), findsOneWidget);
      await s.dispose();
    });
    testWidgets('toggle new content notifications', (WidgetTester t) async {
      final s = await bs(ne: true);
      await st(s, name: 'X');
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppServices>.value(value: s),
            ChangeNotifierProvider<PreferencesService>.value(value: s.prefs),
            ...buildAppProviders(s),
          ],
          child: MaterialApp(home: StudyPlanScreen()),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byType(SwitchListTile).first);
      await t.pumpAndSettle();
      expect(s.prefs.studyPlanNewContentNotifications, isFalse);
      await t.tap(find.byType(SwitchListTile).first);
      await t.pumpAndSettle();
      expect(s.prefs.studyPlanNewContentNotifications, isTrue);
      await s.dispose();
    });
    testWidgets('edit daily quota via dialog', (WidgetTester t) async {
      final s = await bs(qpd: 2, lpd: 1);
      await st(s, name: 'Y');
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppServices>.value(value: s),
            ChangeNotifierProvider<PreferencesService>.value(value: s.prefs),
            ...buildAppProviders(s),
          ],
          child: MaterialApp(home: StudyPlanScreen()),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Quick info per day'));
      await t.pumpAndSettle();
      await t.tap(find.text('3').last);
      await t.pumpAndSettle();
      expect(s.prefs.studyPlanQuickPerDay, 3);
      expect(find.text('3 items'), findsOneWidget);
      await s.dispose();
    });
    testWidgets('shows sync button', (WidgetTester t) async {
      final s = await bs();
      await st(s, name: 'Z');
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppServices>.value(value: s),
            ChangeNotifierProvider<PreferencesService>.value(value: s.prefs),
            ...buildAppProviders(s),
          ],
          child: MaterialApp(home: StudyPlanScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Sync now'), findsOneWidget);
      await s.dispose();
    });
    testWidgets('does not change FSRS data', (WidgetTester t) async {
      final s = await bs();
      await st(s, name: 'FSRS');
      final c1 = await s.cards.countAll();
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppServices>.value(value: s),
            ChangeNotifierProvider<PreferencesService>.value(value: s.prefs),
            ...buildAppProviders(s),
          ],
          child: MaterialApp(home: StudyPlanScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(await s.cards.countAll(), equals(c1));
      await s.dispose();
    });
    testWidgets('reloads saved settings', (WidgetTester t) async {
      final s = await bs(qpd: 5, lpd: 3, ne: false, p: true);
      await st(s, name: 'Saved');
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppServices>.value(value: s),
            ChangeNotifierProvider<PreferencesService>.value(value: s.prefs),
            ...buildAppProviders(s),
          ],
          child: MaterialApp(home: StudyPlanScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('5 items'), findsOneWidget);
      expect(find.text('3 lessons'), findsOneWidget);
      await s.dispose();
    });
  });
}

Future<AppServices> bs({
  bool amc = true,
  int qpd = 2,
  int lpd = 1,
  bool ne = true,
  bool p = false,
}) async {
  await initFfi();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = FakeNotificationService()..notificationsEnabledStatus = ne;
  final s = AppServices.build(
    database: await openMemoryDb(),
    prefs: prefs,
    notifications: fake,
  );
  s.ai.useProvider(F());
  await s.prefs.setStudyPlanQuickPerDay(qpd);
  await s.prefs.setStudyPlanLessonPerDay(lpd);
  await s.prefs.setStudyPlanPaused(p);
  await s.prefs.setStudyPlanNewContentNotifications(ne);
  return s;
}

Future<Topic> st(AppServices s, {required String name, String c = 'Science'}) =>
    s.topics.create(
      name: name,
      category: c,
      icon: '',
      origin: TopicOrigin.personal,
    );
