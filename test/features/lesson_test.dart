import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/services/review_scheduler_service.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/lesson.dart';
import 'package:mind_keeper/features/ai/ai_provider.dart';
import 'package:mind_keeper/features/ai/ai_service.dart';
import 'package:mind_keeper/features/ai/mock_ai_provider.dart';
import 'package:mind_keeper/features/discover/domain_catalog.dart';
import 'package:mind_keeper/features/lessons/lesson_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

Future<AppServices> buildServices() async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final AppDatabase app = await openMemoryDb();
  return AppServices.build(
    database: app,
    prefs: prefs,
    notifications: FakeNotificationService(),
    scheduler: ReviewSchedulerService(
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    ),
    ai: AiService(provider: MockAIProvider(latency: Duration.zero)),
  );
}

void main() {
  group('AiLessonDraft.fromMap — contract JSON (GĐ17)', () {
    test('đọc được camelCase (đúng contract prompt của HttpAIProvider)', () {
      final AiLessonDraft draft = AiLessonDraft.fromMap(<String, Object?>{
        'title': 'Bài học về Vũ trụ',
        'learningObjectives': <String>['Mục tiêu 1', 'Mục tiêu 2'],
        'introduction': 'Mở đầu bài học.',
        'concepts': <Map<String, Object?>>[
          <String, Object?>{'name': 'Khái niệm', 'explanation': 'Giải thích'},
        ],
        'sections': <Map<String, Object?>>[
          <String, Object?>{
            'heading': 'Phần 1',
            'body': 'Nội dung phần 1.',
          },
        ],
        'keyPoints': <String>['Ý chính 1', 'Ý chính 2'],
        'examples': <String>['Ví dụ 1'],
        'commonMistakes': <String>['Sai lầm 1'],
        'summary': 'Tóm tắt bài học.',
        'questions': <Map<String, Object?>>[
          <String, Object?>{'question': 'Câu hỏi?', 'answer': 'Đáp án.'},
        ],
        'sources': <Map<String, Object?>>[
          <String, Object?>{'title': 'Nguồn', 'url': 'https://example.com'},
        ],
        'medical': false,
      });

      expect(draft.title, 'Bài học về Vũ trụ');
      expect(draft.learningObjectives, <String>['Mục tiêu 1', 'Mục tiêu 2']);
      expect(draft.keyPoints, <String>['Ý chính 1', 'Ý chính 2']);
      expect(draft.commonMistakes, <String>['Sai lầm 1']);
      expect(draft.examples, <String>['Ví dụ 1']);
      expect(draft.concepts, hasLength(1));
      expect(draft.sections, hasLength(1));
      expect(draft.questions, hasLength(1));
      expect(draft.sources, hasLength(1));
    });

    test('đọc được snake_case (provider trả về kiểu cũ)', () {
      final AiLessonDraft draft = AiLessonDraft.fromMap(<String, Object?>{
        'title': 'Bài học về Vũ trụ',
        'learning_objectives': <String>['Mục tiêu 1'],
        'introduction': 'Mở đầu bài học.',
        'sections': <Map<String, Object?>>[
          <String, Object?>{
            'heading': 'Phần 1',
            'body': 'Nội dung phần 1.',
          },
        ],
        'key_points': <String>['Ý chính 1'],
        'common_mistakes': <String>['Sai lầm 1'],
        'summary': 'Tóm tắt.',
      });

      expect(draft.learningObjectives, <String>['Mục tiêu 1']);
      expect(draft.keyPoints, <String>['Ý chính 1']);
      expect(draft.commonMistakes, <String>['Sai lầm 1']);
    });

    test('camelCase được ưu tiên khi có cả hai kiểu', () {
      final AiLessonDraft draft = AiLessonDraft.fromMap(<String, Object?>{
        'title': 'T',
        'introduction': 'Mở đầu.',
        'sections': <Map<String, Object?>>[
          <String, Object?>{'heading': 'H', 'body': 'B'},
        ],
        'learningObjectives': <String>['camel'],
        'learning_objectives': <String>['snake'],
        'keyPoints': <String>['camel'],
        'key_points': <String>['snake'],
      });
      expect(draft.learningObjectives, <String>['camel']);
      expect(draft.keyPoints, <String>['camel']);
    });

    test('thiếu title/introduction → FormatException', () {
      expect(
        () => AiLessonDraft.fromMap(<String, Object?>{
          'introduction': 'Mở đầu.',
          'sections': <Map<String, Object?>>[
            <String, Object?>{'heading': 'H', 'body': 'B'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => AiLessonDraft.fromMap(<String, Object?>{
          'title': 'T',
          'sections': <Map<String, Object?>>[
            <String, Object?>{'heading': 'H', 'body': 'B'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('không có sections → FormatException (bài học rỗng)', () {
      expect(
        () => AiLessonDraft.fromMap(<String, Object?>{
          'title': 'T',
          'introduction': 'Mở đầu.',
        }),
        throwsFormatException,
      );
    });
  });

  group('AiService sinh bài học (GĐ13)', () {
    test('generateLesson theo schema, cache giảm call thứ hai', () async {
      final AiService ai = AiService(
        provider: MockAIProvider(latency: Duration.zero),
        cacheTtl: const Duration(minutes: 5),
      );
      final AiLessonDraft first = await ai.generateLesson(
        domain: 'Khoa học',
        topic: 'Vũ trụ',
        mode: 'standard',
        wordMin: 350,
        wordMax: 600,
        questionCount: 4,
      );
      expect(first.title, isNotEmpty);
      expect(first.sections, isNotEmpty);
      expect(first.questions, isNotEmpty);
      expect(ai.debugCacheSize, 1);

      final AiLessonDraft second = await ai.generateLesson(
        domain: 'Khoa học',
        topic: 'Vũ trụ',
        mode: 'standard',
        wordMin: 350,
        wordMax: 600,
        questionCount: 4,
      );
      expect(second.title, first.title);
      expect(ai.debugCacheSize, 1, reason: 'không tăng cache khi hit');
    });
  });

  group('LessonService (GĐ13)', () {
    test(
      'generate dedup: lần hai lấy lại gói đã lưu, không sinh lại',
      () async {
        final AppServices services = await buildServices();
        final LearningDomain domain = LearningDomains.byId('science')!;

        final GeneratedLesson first = await services.lessonService.generate(
          domain: domain,
          topic: 'Vũ trụ',
        );
        expect(first.fromCache, isFalse);
        expect(first.lesson.topic, 'Vũ trụ');
        expect(first.lesson.domainId, 'science');
        expect(await services.lessons.countAll(), 1);

        final GeneratedLesson second = await services.lessonService.generate(
          domain: domain,
          topic: 'vũ  trụ',
          mode: first.lesson.mode,
        );
        expect(second.fromCache, isTrue);
        expect(second.lesson.id, first.lesson.id);
        expect(await services.lessons.countAll(), 1);

        await services.dispose();
      },
    );

    test('generate từ chối chủ đề trống', () async {
      final AppServices services = await buildServices();
      await expectLater(
        services.lessonService.generate(
          domain: LearningDomains.byId('science')!,
          topic: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      await services.dispose();
    });

    test(
      'completeQuiz tạo chủ đề + kiến thức + thẻ FSRS + thông báo',
      () async {
        final AppServices services = await buildServices();
        final FakeNotificationService fake =
            services.notifications as FakeNotificationService;
        final LearningDomain domain = LearningDomains.byId('science')!;

        final GeneratedLesson generated = await services.lessonService.generate(
          domain: domain,
          topic: 'Thuyết tiến hóa',
        );
        final Lesson lesson = generated.lesson;
        expect(lesson.questions, isNotEmpty);

        final LessonQuizOutcome outcome = await services.lessonService
            .completeQuiz(
              lesson: lesson,
              answers: <QuizAnswer>[
                for (int i = 0; i < lesson.questions.length; i++)
                  QuizAnswer(questionIndex: i, rating: MemoryRating.good),
              ],
            );

        expect(outcome.topic.name, isNotEmpty);
        expect(outcome.knowledgeItem.title, lesson.title);
        expect(outcome.cards, hasLength(lesson.questions.length));

        // Chủ đề đã được ghép vào bộ nhớ dài hạn.
        final items = await services.knowledge.listByTopic(outcome.topic.id);
        expect(items, hasLength(1));
        final cards = await services.cards.listByKnowledgeItem(
          outcome.knowledgeItem.id,
        );
        expect(cards, hasLength(lesson.questions.length));

        // Đã đánh dấu đọc và lập lịch nhắc ôn sớm nhất.
        expect(outcome.lesson.isRead, isTrue);
        expect(outcome.notifiedCardId, isNotNull);
        expect(fake.scheduledCards, isNotEmpty);

        await services.dispose();
      },
    );

    test('completeQuiz không lập lịch thông báo khi tắt thông báo', () async {
      final AppServices services = await buildServices();
      final FakeNotificationService fake =
          services.notifications as FakeNotificationService;
      await services.prefs.setNotificationsEnabled(false);

      final LearningDomain domain = LearningDomains.byId('science')!;
      final GeneratedLesson generated = await services.lessonService.generate(
        domain: domain,
        topic: 'Quang học',
      );
      final LessonQuizOutcome outcome = await services.lessonService
          .completeQuiz(
            lesson: generated.lesson,
            answers: <QuizAnswer>[
              for (int i = 0; i < generated.lesson.questions.length; i++)
                QuizAnswer(questionIndex: i, rating: MemoryRating.easy),
            ],
          );

      expect(outcome.notifiedCardId, isNull);
      expect(fake.scheduledCards, isEmpty);

      await services.dispose();
    });

    test(
      'câu hỏi trùng: generate dedup + completeQuiz nhiều lần không tạo trùng',
      () async {
        final AppServices services = await buildServices();
        // Provider trả về câu hỏi trùng (mô phỏng AI thật có thể lặp).
        services.ai.useProvider(_DuplicateQuestionProvider());

        final LearningDomain domain = LearningDomains.byId('science')!;
        final GeneratedLesson generated = await services.lessonService.generate(
          domain: domain,
          topic: 'Thuyết tiến hóa',
          mode: LessonMode.deep,
        );
        final Lesson lesson = generated.lesson;

        // Câu hỏi đã được loại trùng.
        final Set<String> questions = lesson.questions
            .map((LessonQuestion q) => q.question)
            .toSet();
        expect(questions.length, lesson.questions.length);
        expect(lesson.questions, isNotEmpty);

        final List<QuizAnswer> answers = <QuizAnswer>[
          for (int i = 0; i < lesson.questions.length; i++)
            QuizAnswer(questionIndex: i, rating: MemoryRating.good),
        ];
        final LessonQuizOutcome first = await services.lessonService
            .completeQuiz(lesson: lesson, answers: answers);
        final int cardCount = (await services.cards.listByKnowledgeItem(
          first.knowledgeItem.id,
        )).length;
        expect(cardCount, lesson.questions.length);

        // Hoàn tất lại: không crash (log id trùng), không tạo thêm thẻ.
        await services.lessonService.completeQuiz(
          lesson: lesson,
          answers: answers,
        );
        final int afterSecond = (await services.cards.listByKnowledgeItem(
          first.knowledgeItem.id,
        )).length;
        expect(afterSecond, cardCount);

        await services.dispose();
      },
    );
  });
}

/// Provider test trả về câu hỏi trùng nhau để kiểm chứng lớp dedup.
class _DuplicateQuestionProvider extends MockAIProvider {
  _DuplicateQuestionProvider() : super(latency: Duration.zero);

  @override
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  }) async {
    final AiLessonDraft base = await super.generateLesson(
      domain: domain,
      topic: topic,
      mode: mode,
      wordMin: wordMin,
      wordMax: wordMax,
      questionCount: questionCount,
    );
    final AiQuestionDraft dup = base.questions.first;
    return AiLessonDraft(
      title: base.title,
      learningObjectives: base.learningObjectives,
      introduction: base.introduction,
      concepts: base.concepts,
      sections: base.sections,
      keyPoints: base.keyPoints,
      examples: base.examples,
      commonMistakes: base.commonMistakes,
      summary: base.summary,
      questions: <AiQuestionDraft>[
        ...base.questions,
        dup, // thêm một câu hỏi trùng với câu đầu.
      ],
      sources: base.sources,
      medical: base.medical,
    );
  }
}
