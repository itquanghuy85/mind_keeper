import 'dart:async';

import '../../core/utils/id_generator.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_generation.dart';
import '../../data/models/lesson.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/knowledge_generation_repository.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../discover/domain_catalog.dart';

/// Service sinh thư viện kiến thức tự động cho chủ đề mới.
class KnowledgeGenerationService {
  KnowledgeGenerationService({
    required this.topics,
    required this.knowledge,
    required this.lessons,
    required this.generationRepo,
    required this.ai,
    this.config = KnowledgeGenerationConfig.defaultConfig,
  });

  final TopicRepository topics;
  final KnowledgeRepository knowledge;
  final LessonRepository lessons;
  final KnowledgeGenerationRepository generationRepo;
  final AiService ai;
  final KnowledgeGenerationConfig config;

  /// Getter để truy cập repository từ provider.
  KnowledgeGenerationRepository get generationRepository => generationRepo;

  final Map<String, Timer> _timers = <String, Timer>{};

  /// Bắt đầu sinh thư viện kiến thức cho chủ đề.
  /// Trả về task đã tạo/cập nhật.
  Future<KnowledgeGenerationTask> startGeneration({
    required String topicId,
    required String topicName,
    String? topicDescription,
    String? topicCategory,
    int? lessonCount,
    int? wordMin,
    int? wordMax,
    LessonMode? mode,
  }) async {
    final Topic? topic = await topics.getById(topicId);
    if (topic == null) {
      throw ArgumentError('Chủ đề không tồn tại: $topicId');
    }

    final int count = lessonCount ?? config.defaultLessonCount;
    final int minWords = wordMin ?? config.defaultWordMin;
    final int maxWords = wordMax ?? config.defaultWordMax;
    final LessonMode effectiveMode = mode ?? LessonMode.standard;

    // Tạo task với trạng thái generating
    final KnowledgeGenerationTask task = await generationRepo.upsert(
      topicId: topicId,
      status: KnowledgeGenerationStatus.generating,
      totalPlanned: count,
    );

    // Khởi chạy sinh kiến thức trong background
    _runGenerationInBackground(
      task: task,
      topic: topic,
      count: count,
      wordMin: minWords,
      wordMax: maxWords,
      lessonMode: effectiveMode,
    );

    return task;
  }

  /// Chạy sinh kiến thức trong background.
  void _runGenerationInBackground({
    required KnowledgeGenerationTask task,
    required Topic topic,
    required int count,
    required int wordMin,
    required int wordMax,
    required LessonMode lessonMode,
  }) {
    // Sử dụng Timer để không chặn UI
    _timers[task.topicId] = Timer(const Duration(milliseconds: 100), () async {
      await _generateLessons(
        task: task,
        topic: topic,
        count: count,
        wordMin: wordMin,
        wordMax: wordMax,
        lessonMode: lessonMode,
      );
    });
  }

  /// Sinh các bài học cho chủ đề.
  Future<void> _generateLessons({
    required KnowledgeGenerationTask task,
    required Topic topic,
    required int count,
    required int wordMin,
    required int wordMax,
    required LessonMode lessonMode,
  }) async {
    try {
      // Phân tích chủ đề để xác định lĩnh vực
      final String domainId = _inferDomain(topic.category, topic.name);
      final LearningDomain? domain = LearningDomains.byId(domainId);
      final LearningDomain effectiveDomain =
          domain ?? LearningDomains.all.first;

      int completed = 0;
      int failed = 0;

      // Sinh từng bài học
      for (int i = 0; i < count; i++) {
        // Kiểm tra xem task còn đang active không
        final KnowledgeGenerationTask? currentTask = await generationRepo
            .getByTopicId(task.topicId);
        if (currentTask == null || !currentTask.isGenerating) {
          return; // Task đã bị hủy hoặc hoàn tất
        }

        try {
          // Tạo tiêu đề bài học dựa trên thứ tự
          final String lessonTopic = _generateLessonTopic(
            topic.name,
            i + 1,
            count,
          );

          final AiLessonDraft draft = await ai.generateLesson(
            domain: effectiveDomain.name,
            topic: lessonTopic,
            mode: lessonMode.id,
            wordMin: wordMin,
            wordMax: wordMax,
            questionCount: lessonMode.questions,
          );

          // Lưu bài học
          final DateTime timestamp = DateTime.now().toUtc();
          final List<LessonSource> sources = <LessonSource>[
            for (final AiLessonSource source in draft.sources)
              LessonSource(title: source.title, url: source.url),
          ];
          final List<LessonQuestion> questions = _uniqueQuestions(
            draft.questions,
          );
          final List<LessonConcept> concepts = <LessonConcept>[
            for (final AiLessonConcept concept in draft.concepts)
              LessonConcept(
                name: concept.name,
                explanation: concept.explanation,
              ),
          ];

          final Lesson lesson = Lesson(
            id: newId('ls'),
            domainId: effectiveDomain.id,
            domainName: effectiveDomain.name,
            topic: lessonTopic,
            mode: lessonMode,
            promptVersion: AiService.lessonPromptVersion,
            dedupKey: Lesson.buildDedupKey(
              domainId: effectiveDomain.id,
              topic: lessonTopic,
              mode: lessonMode,
              promptVersion: AiService.lessonPromptVersion,
            ),
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
            medical: effectiveDomain.isHealth || draft.medical,
            wordCount: draft.wordCount,
            isFavorite: false,
            isRead: false,
            linkedTopicId: topic.id,
            createdAt: timestamp,
            updatedAt: timestamp,
          );

          await lessons.create(lesson);

          // Tạo KnowledgeItem tương ứng để có thể ôn tập
          await _createKnowledgeItemFromLesson(lesson, topic, timestamp);

          completed++;
          await generationRepo.incrementCompleted(task.topicId);
        } catch (e) {
          failed++;
          final String errorMsg = 'Lỗi sinh bài ${i + 1}: $e';
          await generationRepo.incrementFailed(task.topicId, errorMsg);

          // Thử lại nếu chưa vượt quá maxRetries
          if (failed < config.maxRetries) {
            // Có thể implement retry logic ở đây
          }
        }
      }

      // Cập nhật trạng thái cuối cùng
      if (failed > 0 && completed == 0) {
        await generationRepo.markFailed(
          task.topicId,
          'Tất cả bài học đều thất bại',
        );
      } else if (failed > 0) {
        await generationRepo.upsert(
          topicId: task.topicId,
          status: KnowledgeGenerationStatus.completed,
          completedCount: completed,
          failedCount: failed,
        );
      } else {
        await generationRepo.markCompleted(task.topicId);
      }
    } catch (e) {
      await generationRepo.markFailed(task.topicId, 'Lỗi không mong đợi: $e');
    } finally {
      _timers.remove(task.topicId);
    }
  }

  /// Tạo KnowledgeItem từ Lesson để tích hợp với hệ thống ôn tập.
  Future<void> _createKnowledgeItemFromLesson(
    Lesson lesson,
    Topic topic,
    DateTime timestamp,
  ) async {
    final String summary = lesson.content.summary.isNotEmpty
        ? lesson.content.summary
        : lesson.content.introduction;

    try {
      await knowledge.create(
        topicId: topic.id,
        title: lesson.title,
        content: summary,
        details: lesson.content.keyPoints.join(' — '),
        origin: KnowledgeOrigin.aiSuggested,
        skipDuplicateCheck: true,
        now: timestamp,
      );
    } catch (e) {
      // Bỏ qua lỗi trùng lặp
    }
  }

  /// Suy ra domain từ category và tên chủ đề.
  String _inferDomain(String? category, String name) {
    final String searchText = '${category ?? ''} $name'.toLowerCase();

    // Map từ khóa sang domain ID
    const Map<String, List<String>> domainKeywords = {
      'science': [
        'khoa học',
        'vật lý',
        'hóa học',
        'sinh học',
        'vũ trụ',
        'nguyên tử',
      ],
      'technology': [
        'công nghệ',
        'ai',
        'trí tuệ nhân tạo',
        'robot',
        'iot',
        'đám mây',
      ],
      'computing': [
        'lập trình',
        'thuật toán',
        'cơ sở dữ liệu',
        'bảo mật',
        'di động',
      ],
      'history': [
        'lịch sử',
        'chiến tranh',
        'cách mạng',
        'triều đại',
        'nhân vật lịch sử',
      ],
      'geography': ['địa lý', 'khí hậu', 'bản đồ', 'địa hình', 'hải lưu'],
      'psychology': [
        'tâm lý',
        'cảm xúc',
        'hành vi',
        'thói quen',
        'lo âu',
        'động lực',
      ],
      'education': [
        'giáo dục',
        'phương pháp học',
        'ghi chú',
        'bài luận',
        'thi cử',
      ],
      'business': [
        'kinh doanh',
        'khởi nghiệp',
        'quản trị',
        'thương hiệu',
        'mô hình',
      ],
      'finance': [
        'tài chính',
        'đầu tư',
        'lãi suất',
        'lạm phát',
        'ngân sách',
        'quỹ dự phòng',
      ],
      'health': [
        'sức khỏe',
        'bệnh',
        'giấc ngủ',
        'tập thể dục',
        'phục hồi',
        'cúm',
      ],
      'nutrition': [
        'dinh dưỡng',
        'thực phẩm',
        'protein',
        'đường',
        'khẩu phần',
        'ăn uống',
      ],
      'sports': [
        'thể thao',
        'bóng đá',
        'chạy bộ',
        'yoga',
        'rèn luyện',
        'thi đấu',
      ],
      'art': ['nghệ thuật', 'hội họa', 'âm nhạc', 'điện ảnh', 'đường phố'],
      'literature': ['văn học', 'truyện', 'thơ', 'tiểu thuyết', 'dân gian'],
      'languages': [
        'ngoại ngữ',
        'tiếng anh',
        'hán tự',
        'tiếng nhật',
        'dịch thuật',
      ],
      'food': ['ẩm thực', 'món ăn', 'nấu ăn', 'gia vị', 'bánh', 'đường phố'],
      'travel': ['du lịch', 'vé máy bay', 'di sản', 'hành lý', 'bụi'],
      'environment': [
        'môi trường',
        'rác',
        'rừng',
        'nước',
        'năng lượng tái tạo',
      ],
      'lifestyle': ['đời sống', 'dọn dẹp', 'thời gian', 'sở thích', 'quan hệ'],
      'lifeskills': [
        'kỹ năng sống',
        'giao tiếp',
        'tư duy phản biện',
        'email',
        'phỏng vấn',
      ],
    };

    for (final MapEntry<String, List<String>> entry in domainKeywords.entries) {
      for (final String keyword in entry.value) {
        if (searchText.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'lifestyle'; // Default
  }

  /// Tạo tiêu đề bài học dựa trên thứ tự.
  String _generateLessonTopic(String topicName, int index, int total) {
    if (total == 1) return topicName;

    const List<String> prefixes = [
      'Cơ bản về',
      'Nguyên lý cốt lõi của',
      'Ứng dụng thực tế của',
      'Kỹ năng nâng cao về',
      'Tổng kết và mở rộng về',
    ];

    final String prefix = prefixes[(index - 1) % prefixes.length];
    return '$prefix $topicName';
  }

  /// Loại bỏ câu hỏi trùng.
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

  /// Hủy sinh kiến thức cho chủ đề.
  void cancelGeneration(String topicId) {
    _timers[topicId]?.cancel();
    _timers.remove(topicId);
  }

  /// Thử lại sinh kiến thức cho chủ đề đã thất bại.
  Future<KnowledgeGenerationTask?> retryGeneration(String topicId) async {
    final KnowledgeGenerationTask? task = await generationRepo.getByTopicId(
      topicId,
    );
    if (task == null || !task.canRetry) return null;

    // Lấy thông tin topic
    final Topic? topic = await topics.getById(topicId);
    if (topic == null) return null;

    // Reset và bắt đầu lại
    return startGeneration(
      topicId: topicId,
      topicName: topic.name,
      lessonCount: task.totalPlanned,
    );
  }

  void dispose() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
