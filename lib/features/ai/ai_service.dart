import '../../data/models/course.dart';
import 'ai_provider.dart';
import 'course_ai.dart';
import 'http_ai_provider.dart';
import 'mock_ai_provider.dart';

/// Service AI: chọn provider, cache theo nội dung+tham số.
/// Không tính lịch ôn (thuộc ReviewSchedulerService).
class AiService {
  AiService({AIProvider? provider, this.cacheTtl = defaultCacheTtl})
    : _provider = provider ?? MockAIProvider();

  static const Duration defaultCacheTtl = Duration(days: 1);

  /// Phiên bản prompt sinh bài học. Đổi giá trị này để invalidate
  /// cache/dedup khi yêu cầu nội dung thay đổi.
  static const String lessonPromptVersion = 'v2';

  AIProvider _provider;
  final Duration cacheTtl;
  final Map<String, ({Object value, DateTime at})> _cache =
      <String, ({Object value, DateTime at})>{};

  AIProvider get provider => _provider;

  bool get isRealProvider =>
      _provider is HttpAIProvider && _provider.isConfigured;

  int get debugCacheSize => _cache.length;

  void useProvider(AIProvider provider) {
    _provider = provider;
    _cache.clear();
  }

  /// Tạo HttpAIProvider nếu prefs có cấu hình; ngược lại mock.
  /// Nếu không có API key, dùng MockAIProvider và ghi log cảnh báo.
  void configureFromSettings({
    required String baseUrl,
    required String apiKey,
    required String model,
    bool proxyMode = false,
  }) {
    final bool hasValidConfig =
        baseUrl.trim().isNotEmpty && (proxyMode || apiKey.trim().isNotEmpty);
    if (!hasValidConfig) {
      useProvider(MockAIProvider());
      return;
    }
    useProvider(
      HttpAIProvider(
        baseUrl: baseUrl.trim(),
        apiKey: apiKey.trim(),
        model: model.trim(),
        proxyMode: proxyMode,
      ),
    );
  }

  /// Cấu hình mặc định DeepSeek từ environment variables hoặc secret manager.
  /// Trả về true nếu cấu hình thành công, false nếu thiếu API key.
  /// [proxyMode] = true khi baseUrl là proxy backend (không cần key ở client).
  bool configureDeepSeekDefault({
    required String apiKey,
    String? baseUrl,
    String? model,
    bool proxyMode = false,
  }) {
    if (!proxyMode && apiKey.trim().isEmpty) {
      useProvider(MockAIProvider());
      return false;
    }
    if (proxyMode && (baseUrl?.trim().isEmpty ?? true)) {
      useProvider(MockAIProvider());
      return false;
    }
    useProvider(
      HttpAIProvider(
        baseUrl: (baseUrl?.trim().isNotEmpty == true)
            ? baseUrl!.trim()
            : HttpAIProvider.defaultBaseUrl,
        apiKey: apiKey.trim(),
        model: (model?.trim().isNotEmpty == true)
            ? model!.trim()
            : HttpAIProvider.defaultModel,
        proxyMode: proxyMode,
      ),
    );
    return true;
  }

  /// Kiểm tra xem có cấu hình AI thật hợp lệ không.
  /// Nếu không, ném exception với mã lỗi rõ ràng.
  void validateConfiguration() {
    if (!isRealProvider) {
      throw AiConfigurationException(
        code: 'AI_NOT_CONFIGURED',
        message: 'AI chưa được cấu hình. Cần cung cấp API key DeepSeek hợp lệ.',
        userMessage:
            'Tính năng AI cần cấu hình API key. Vui lòng liên hệ quản trị viên.',
      );
    }
  }

  static String _hash(String input) {
    int h = 5381;
    for (int i = 0; i < input.length; i++) {
      h = ((h << 5) + h + input.codeUnitAt(i)) & 0x7fffffff;
    }
    return h.toRadixString(16);
  }

  String _key(String kind, Map<String, Object?> params) {
    final String canonical = 'p=${_provider.name}|k=$kind|q=$params';
    return _hash(canonical);
  }

  T? _read<T extends Object>(String key) {
    final ({Object value, DateTime at})? entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T;
  }

  void _write(String key, Object value) {
    _cache[key] = (value: value, at: DateTime.now());
  }

  Future<T> _cached<T extends Object>(
    String key,
    Future<T> Function() run,
  ) async {
    final T? hit = _read<T>(key);
    if (hit != null) return hit;
    final T result = await run();
    _write(key, result);
    return result;
  }

  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  }) {
    return _cached(
      _key('knowledge', <String, Object?>{'t': sourceText, 'm': maxItems}),
      () =>
          _provider.draftKnowledge(sourceText: sourceText, maxItems: maxItems),
    );
  }

  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  }) {
    return _cached(
      _key('questions', <String, Object?>{'t': knowledgeContent, 'c': count}),
      () => _provider.draftQuestions(
        knowledgeContent: knowledgeContent,
        count: count,
      ),
    );
  }

  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  }) {
    return _cached(
      _key('explain', <String, Object?>{
        'q': question,
        'a': answer,
        'u': userAnswer,
      }),
      () => _provider.explain(
        question: question,
        answer: answer,
        userAnswer: userAnswer,
      ),
    );
  }

  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  }) {
    return _cached(
      _key('grade', <String, Object?>{
        'q': question,
        'r': referenceAnswer,
        'u': userAnswer,
      }),
      () => _provider.gradeAnswer(
        question: question,
        referenceAnswer: referenceAnswer,
        userAnswer: userAnswer,
      ),
    );
  }

  /// Sinh bài học (cache in-memory theo nhà cung cấp + tham số + prompt version).
  /// Dedup bền vững ở tầng LessonRepository (dedup_key).
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
    String promptVersion = lessonPromptVersion,
  }) {
    return _cached(
      _key('lesson', <String, Object?>{
        'd': domain,
        't': topic,
        'm': mode,
        'w': '$wordMin-$wordMax',
        'c': questionCount,
        'v': promptVersion,
      }),
      () => _provider.generateLesson(
        domain: domain,
        topic: topic,
        mode: mode,
        wordMin: wordMin,
        wordMax: wordMax,
        questionCount: questionCount,
      ),
    );
  }

  Future<List<AiTopicSuggestion>> suggestTopics({
    required String domain,
    int count = 20,
  }) {
    return _cached(
      _key('topics', <String, Object?>{'d': domain, 'c': count}),
      () => _provider.suggestTopics(domain: domain, count: count),
    );
  }

  CourseAiProvider get _courseProvider {
    final AIProvider p = _provider;
    if (p is CourseAiProvider) return p as CourseAiProvider;
    throw const AiConfigurationException(
      code: 'course_unsupported',
      message: 'Provider AI hiện tại không hỗ trợ khóa học.',
      userMessage: 'AI hiện tại chưa hỗ trợ tạo khóa học.',
    );
  }

  /// Dựng đề cương [count] mẩu cho một chủ đề ở cấp [level].
  Future<List<String>> generateOutline({
    required String topic,
    required CourseLevel level,
    required int count,
  }) => _courseProvider.generateOutline(
    topic: topic,
    level: level,
    count: count,
  );

  /// Soạn một mẩu (không cache: mỗi mẩu chỉ sinh một lần rồi lưu SQLite).
  Future<AiBiteDraft> generateBite({
    required String topic,
    required CourseLevel level,
    required String title,
    required int index,
    required int total,
    List<String> previousTitles = const <String>[],
  }) => _courseProvider.generateBite(
    topic: topic,
    level: level,
    title: title,
    index: index,
    total: total,
    previousTitles: previousTitles,
  );

  void clearCache() => _cache.clear();
}
