import '../../core/services/notification_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/review_scheduler_service.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/lesson.dart';
import '../../data/models/review_card.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../discover/domain_catalog.dart';

/// Một lần chấm trong quiz ghi nhớ sau bài học.
class QuizAnswer {
  const QuizAnswer({
    required this.questionIndex,
    required this.rating,
    this.answerText,
  });

  final int questionIndex;
  final MemoryRating rating;
  final String? answerText;
}

/// Kết quả gọi generate: bài học + có phải lấy lại từ gói đã lưu không.
class GeneratedLesson {
  const GeneratedLesson({required this.lesson, required this.fromCache});

  final Lesson lesson;
  final bool fromCache;
}

/// Kết quả hoàn tất quiz: bài đã vào bộ nhớ dài hạn + lịch ôn + thông báo.
class LessonQuizOutcome {
  const LessonQuizOutcome({
    required this.lesson,
    required this.topic,
    required this.knowledgeItem,
    required this.cards,
    this.nextDueAt,
    this.notifiedCardId,
  });

  final Lesson lesson;
  final Topic topic;
  final KnowledgeItem knowledgeItem;
  final List<ReviewCard> cards;

  /// Thẻ đến giờ ôn sớm nhất trong tương lai (nếu có).
  final DateTime? nextDueAt;
  final String? notifiedCardId;
}

/// Service khám phá kiến thức bằng AI:
/// - Sinh bài học (dedup theo lĩnh vực/chủ đề/chế độ/prompt version — không sinh lại).
/// - Quiz ghi nhớ sau đọc → tạo/cập nhật thẻ FSRS từng câu.
/// - Lập lịch thông báo mở đúng câu hỏi đến giờ ôn.
class LessonService {
  LessonService({
    required this.lessons,
    required this.topics,
    required this.knowledge,
    required this.cards,
    required this.scheduler,
    required this.notifications,
    required this.prefs,
    required this.ai,
  });

  final LessonRepository lessons;
  final TopicRepository topics;
  final KnowledgeRepository knowledge;
  final ReviewRepository cards;
  final ReviewSchedulerService scheduler;
  final NotificationService notifications;
  final PreferencesService prefs;
  final AiService ai;

  LessonMode get defaultMode =>
      LessonMode.tryParse(prefs.lessonDefaultMode) ?? LessonMode.defaultMode;

  /// Tạo (hoặc lấy lại gói bài học đã lưu) cho một lĩnh vực.
  Future<GeneratedLesson> generate({
    required LearningDomain domain,
    required String topic,
    LessonMode? mode,
    DateTime? now,
  }) async {
    final String cleanTopic = topic.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanTopic.isEmpty) {
      throw ArgumentError('Chủ đề không được để trống.');
    }
    final LessonMode effectiveMode = mode ?? defaultMode;
    final String dedupKey = Lesson.buildDedupKey(
      domainId: domain.id,
      topic: cleanTopic,
      mode: effectiveMode,
      promptVersion: AiService.lessonPromptVersion,
    );

    // Gói nội dung bền vững: đã có thì dùng lại, không tốn token.
    final Lesson? existing = await lessons.findByDedupKey(dedupKey);
    if (existing != null) {
      return GeneratedLesson(lesson: existing, fromCache: true);
    }

    final AiLessonDraft draft = await ai.generateLesson(
      domain: domain.name,
      topic: cleanTopic,
      mode: effectiveMode.id,
      wordMin: effectiveMode.wordMin,
      wordMax: effectiveMode.wordMax,
      questionCount: effectiveMode.questions,
    );

    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final List<LessonSource> sources = <LessonSource>[
      for (final AiLessonSource source in draft.sources)
        LessonSource(title: source.title, url: source.url),
    ];
    final List<LessonQuestion> questions = _uniqueQuestions(draft.questions);
    final List<LessonConcept> concepts = <LessonConcept>[
      for (final AiLessonConcept concept in draft.concepts)
        LessonConcept(name: concept.name, explanation: concept.explanation),
    ];
    final Lesson lesson = Lesson(
      id: newId('ls'),
      domainId: domain.id,
      domainName: domain.name,
      topic: cleanTopic,
      mode: effectiveMode,
      promptVersion: AiService.lessonPromptVersion,
      dedupKey: dedupKey,
      title: draft.title,
      content: LessonContent(
        learningObjectives: draft.learningObjectives,
        introduction: draft.introduction,
        concepts: concepts,
        sections: <LessonSection>[
          for (final AiLessonSection section in draft.sections)
            LessonSection(heading: section.heading, body: section.body),
        ],
        keyPoints: draft.keyPoints,
        examples: draft.examples,
        commonMistakes: draft.commonMistakes,
        summary: draft.summary,
      ),
      questions: questions,
      sources: sources,
      verification: sources.isEmpty
          ? LessonVerification.unverified
          : LessonVerification.sourced,
      medical: domain.isHealth || draft.medical,
      wordCount: draft.wordCount,
      isFavorite: false,
      isRead: false,
      linkedTopicId: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final Lesson saved = await lessons.create(lesson);
    return GeneratedLesson(lesson: saved, fromCache: saved.id != lesson.id);
  }

  /// Ghép bài học vào bộ nhớ dài hạn + chấm quiz → cập nhật lịch ôn FSRS
  /// cho TỪNG câu hỏi, rồi lập lịch thông báo mở đúng câu đến giờ.
  ///
  /// [markRead] = false khi quiz chặn (chặng giữa của lộ trình).
  Future<LessonQuizOutcome> completeQuiz({
    required Lesson lesson,
    required List<QuizAnswer> answers,
    bool markRead = true,
    DateTime? now,
  }) async {
    final DateTime moment = (now ?? DateTime.now()).toUtc();

    final Topic topic = await _ensureTopic(lesson, moment);
    if (lesson.linkedTopicId != topic.id) {
      await lessons.setLinkedTopic(lesson.id, topicId: topic.id);
    }
    final KnowledgeItem item = await _ensureKnowledgeItem(
      lesson,
      topic,
      moment,
    );

    final List<ReviewCard> existingCards = await cards.listByKnowledgeItem(
      item.id,
    );
    final List<ReviewCard> handled = <ReviewCard>[];
    final Set<String> handledCardIds = <String>{};
    for (final QuizAnswer answer in answers) {
      if (answer.questionIndex < 0 ||
          answer.questionIndex >= lesson.questions.length) {
        continue;
      }
      final LessonQuestion question = lesson.questions[answer.questionIndex];
      ReviewCard? card = _findCard(existingCards, question.question);
      card ??= await cards.create(
        knowledgeItemId: item.id,
        question: question.question,
        answer: question.answer,
        dueAt: moment,
        now: moment,
      );
      // Bảo vệ trước câu hỏi trùng: không chấm cùng một thẻ hai lần
      // trong cùng một lần hoàn tất quiz.
      if (!handledCardIds.add(card.id)) {
        continue;
      }
      final ScheduleResult result = scheduler.schedule(
        card: card,
        rating: answer.rating,
        now: moment,
        answerText: answer.answerText,
      );
      await cards.saveReview(updatedCard: result.card, log: result.log);
      handled.add(result.card);
    }

    if (markRead && !lesson.isRead) {
      await lessons.setRead(lesson.id, read: true);
    }

    final Lesson refreshed = await lessons.getById(lesson.id) ?? lesson;

    // Thông báo mở đúng câu hỏi kế tiếp đến giờ ôn (một lần, có thời điểm).
    String? notifiedCardId;
    DateTime? nextDueAt;
    if (prefs.notificationsEnabled) {
      final List<ReviewCard> allCards = await cards.listByKnowledgeItem(
        item.id,
      );
      final DateTime floor = moment.add(const Duration(minutes: 1));
      final DateTime horizon = moment.add(const Duration(days: 30));
      ReviewCard? earliest;
      for (final ReviewCard card in allCards) {
        if (!card.dueAt.isAfter(floor) || !card.dueAt.isBefore(horizon)) {
          continue;
        }
        if (earliest == null || card.dueAt.isBefore(earliest.dueAt)) {
          earliest = card;
        }
      }
      if (earliest != null) {
        nextDueAt = earliest.dueAt;
        notifiedCardId = earliest.id;
        await notifications.scheduleCardDueAt(
          cardId: earliest.id,
          title: 'Đến giờ ôn: ${refreshed.title}',
          body: earliest.question,
          at: earliest.dueAt,
        );
      }
    }

    return LessonQuizOutcome(
      lesson: refreshed,
      topic: topic,
      knowledgeItem: item,
      cards: handled,
      nextDueAt: nextDueAt,
      notifiedCardId: notifiedCardId,
    );
  }

  Future<Topic> _ensureTopic(Lesson lesson, DateTime moment) async {
    if (lesson.linkedTopicId != null) {
      final Topic? linked = await topics.getById(lesson.linkedTopicId!);
      if (linked != null) return linked;
    }
    final String name = TopicRepository.normalizeName(
      lesson.topic.isEmpty ? lesson.title : lesson.topic,
    );
    final Topic? existing = await topics.findByName(name);
    if (existing != null) return existing;
    return topics.create(
      name: name,
      description: 'lesson:${lesson.id}',
      category: lesson.domainName,
      icon: '',
      origin: TopicOrigin.discovered,
      now: moment,
    );
  }

  Future<KnowledgeItem> _ensureKnowledgeItem(
    Lesson lesson,
    Topic topic,
    DateTime moment,
  ) async {
    // Kiểm tra đã đăng ký (enroll) chưa - KnowledgeItem đã có startedAt từ lúc đọc lần đầu
    // Ưu tiên tìm theo lessonId để tránh gộp sai bài trùng tiêu đề
    final KnowledgeItem? existing = await knowledge.findByTitle(
      topic.id,
      lesson.title,
      lessonId: lesson.id,
    );
    if (existing != null) return existing;

    // Fallback: tạo mới nếu chưa có (trường hợp hiếm khi user làm quiz mà chưa đọc)
    final String summary = lesson.content.summary.isNotEmpty
        ? lesson.content.summary
        : lesson.content.introduction;
    return knowledge.enroll(
      topicId: topic.id,
      title: lesson.title,
      content: summary,
      details: lesson.content.keyPoints.join(' — '),
      origin: KnowledgeOrigin.aiSuggested,
      lessonId: lesson.id,
      now: moment,
    );
  }

  ReviewCard? _findCard(List<ReviewCard> existing, String question) {
    for (final ReviewCard card in existing) {
      if (card.question == question) return card;
    }
    return null;
  }

  /// Loại bỏ câu hỏi trùng (AI có thể trả về câu hỏi giống nhau cho các phần
  /// khác nhau) để không tạo thẻ ôn trùng và không ghi log trùng.
  static List<LessonQuestion> _uniqueQuestions(List<AiQuestionDraft> drafts) {
    final List<LessonQuestion> result = <LessonQuestion>[];
    final Set<String> seen = <String>{};
    for (final AiQuestionDraft draft in drafts) {
      final String key = draft.question.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      if (key.isEmpty || !seen.add(key)) continue;
      result.add(
        LessonQuestion(
          question: draft.question,
          answer: draft.answer,
          explanation: draft.explanation,
        ),
      );
    }
    return result;
  }

  Future<void> toggleFavorite(Lesson lesson) =>
      lessons.setFavorite(lesson.id, favorite: !lesson.isFavorite);

  Future<void> markRead(Lesson lesson, {required bool read}) =>
      lessons.setRead(lesson.id, read: read);

  Future<void> confirmVerification(Lesson lesson) => lessons.setVerification(
    lesson.id,
    verification: LessonVerification.confirmed,
  );

  /// Hủy thông báo ôn của một thẻ (khi người dùng ôn sớm/thủ công).
  Future<void> cancelCardReminder(String cardId) =>
      notifications.cancelCardNotification(cardId);
}
