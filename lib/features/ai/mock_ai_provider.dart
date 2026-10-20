import 'dart:convert';

import '../discover/domain_catalog.dart';
import '../discover/topic_seed_catalog.dart';
import 'ai_provider.dart';

/// Mock AI dùng cho phát triển và test.
/// KHÔNG phải dịch vụ AI thật — mọi kết quả được đánh dấu "đề xuất thử nghiệm".
class MockAIProvider implements AIProvider {
  MockAIProvider({this.latency = const Duration(milliseconds: 30)});

  final Duration latency;

  @override
  String get name => 'mock';

  @override
  bool get isConfigured => true;

  Future<void> _delay() => Future<void>.delayed(latency);

  @override
  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  }) async {
    await _delay();
    final String text = sourceText.trim();
    if (text.isEmpty) return const <AiKnowledgeDraft>[];
    final List<String> sentences = text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((String s) => s.trim())
        .where((String s) => s.length >= 15)
        .toList();
    final List<AiKnowledgeDraft> drafts = <AiKnowledgeDraft>[];
    for (int i = 0; i < sentences.length && drafts.length < maxItems; i++) {
      final String sentence = sentences[i];
      final String titleSource = sentence.length > 48
          ? '${sentence.substring(0, 45)}…'
          : sentence;
      drafts.add(
        AiKnowledgeDraft(
          title: titleSource.replaceAll(RegExp(r'[.!?]+$'), ''),
          content: sentence,
        ),
      );
    }
    if (drafts.isEmpty) {
      drafts.add(
        AiKnowledgeDraft(
          title: text.length > 48 ? '${text.substring(0, 45)}…' : text,
          content: text,
        ),
      );
    }
    return drafts;
  }

  @override
  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  }) async {
    await _delay();
    final String content = knowledgeContent.trim();
    if (content.isEmpty) return const <AiQuestionDraft>[];
    final String firstSentence = content.split(RegExp(r'[.!?]+')).first.trim();
    final List<AiQuestionDraft> drafts = <AiQuestionDraft>[
      AiQuestionDraft(
        question: 'Nội dung chính của ý sau là gì?\n"$firstSentence"',
        answer: content,
        explanation: 'Ôn lại nguyên văn ý chính để ghi nhớ.',
      ),
    ];
    if (count >= 2) {
      drafts.add(
        AiQuestionDraft(
          question: 'Bổ sung kiến thức: "$firstSentence" — nhớ được bao nhiêu?',
          answer: content,
        ),
      );
    }
    return drafts.take(count).toList(growable: false);
  }

  @override
  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  }) async {
    await _delay();
    return AiTutorExplanation(
      explanation: 'Đáp án tham chiếu: $answer',
      example: userAnswer == null || userAnswer.trim().isEmpty
          ? ''
          : 'Câu trả lời của bạn gần với đáp án — hãy đối chiếu từng ý.',
    );
  }

  @override
  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  }) async {
    await _delay();
    final String user = userAnswer.trim().toLowerCase();
    final String ref = referenceAnswer.trim().toLowerCase();
    if (user.isEmpty) {
      return const AiAnswerEvaluation(
        verdict: 'wrong',
        comment: 'Bạn chưa nhập câu trả lời.',
        score: 0,
      );
    }
    final List<String> refTokens = ref
        .split(RegExp(r'[^a-z0-9à-ỹ]+'))
        .where((String t) => t.length > 2)
        .toSet()
        .toList();
    if (refTokens.isEmpty) {
      return AiAnswerEvaluation(
        verdict: 'partial',
        comment: 'Không đủ dữ liệu để chấm tự động.',
        score: 0.5,
      );
    }
    int hit = 0;
    for (final String token in refTokens) {
      if (user.contains(token)) hit++;
    }
    final double ratio = hit / refTokens.length;
    if (ratio >= 0.7) {
      return AiAnswerEvaluation(
        verdict: 'correct',
        comment: 'Câu trả lời đúng trọng tâm.',
        score: ratio,
      );
    }
    if (ratio >= 0.35) {
      return AiAnswerEvaluation(
        verdict: 'partial',
        comment: 'Đúng một phần — thiếu vài ý chính.',
        score: ratio,
      );
    }
    return AiAnswerEvaluation(
      verdict: 'wrong',
      comment: 'Câu trả lời chưa sát đáp án.',
      score: ratio,
    );
  }

  /// Serialize draft (hữu ích test cache).
  static String encodeDrafts(List<AiKnowledgeDraft> drafts) => jsonEncode(
    drafts
        .map(
          (AiKnowledgeDraft d) => <String, String>{
            'title': d.title,
            'content': d.content,
            'details': d.details,
          },
        )
        .toList(),
  );

  static const List<String> _lessonSentences = <String>[
    'Để hiểu rõ chủ đề này, trước tiên cần nắm được ý tưởng nền tảng và cách nó vận động trong thực tế.',
    'Khi quan sát kỹ, bạn sẽ thấy mỗi khái niệm đều gắn với những tình huống cụ thể xảy ra hằng ngày.',
    'Việc đặt câu hỏi tại sao và như thế nào giúp kiến thức chuyển từ nhớ máy sang hiểu thật.',
    'Nhiều người học nhanh nhưng quên chậm vì chưa kết nối thông tin mới với trải nghiệm đã có.',
    'Một cách ghi nhớ bền vững là tách nội dung thành các đơn vị ngắn và luyện lại theo nhịp phù hợp.',
    'Những ví dụ sinh động giúp ta hình dung vấn đề thay vì chỉ lặp lại định nghĩa khô khan.',
    'Trong mọi lĩnh vực, tư duy phản biện giúp bạn lọc thông tin và tránh rơi vào kết luận vội vàng.',
    'Quá trình học tập hiệu quả luôn xen kẽ giữa đọc, suy nghĩ, đặt câu hỏi và tự giải thích lại.',
    'Bạn không cần nhớ hết mọi chi tiết, chỉ cần giữ được sườn ý chính và biết tìm lại khi cần.',
    'Việc theo dõi tiến bộ từng chút một tạo động lực và cho thấy rõ khoảng cách đến mục tiêu.',
    'Hãy liên kết điều vừa học với một câu chuyện hoặc hình ảnh quen thuộc để tăng độ bám dính.',
    'Sai lầm trong quá trình học là dữ liệu hữu ích cho thấy chỗ cần củng cố ở lần sau.',
  ];

  static const List<String> _lessonHeadings = <String>[
    'Bức tranh tổng quan',
    'Ý tưởng cốt lõi',
    'Ví dụ minh họa',
    'Cách áp dụng',
    'Những điểm cần tránh',
    'Ghi nhớ nhanh',
  ];

  static const List<String> _medicalKeywords = <String>[
    'sức khỏe',
    'bệnh',
    'thuốc',
    'dinh dưỡng',
    'tim mạch',
    'huyết áp',
    'ung thư',
    'vaccine',
    'tâm lý',
    'y tế',
  ];

  static int _words(String text) {
    final String t = text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  @override
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  }) async {
    await _delay();
    final int targetMin = wordMin < 80 ? 80 : wordMin;
    final int targetMax = wordMax <= targetMin ? targetMin + 60 : wordMax;

    final int sectionCount = switch (mode) {
      'overview' => 3,
      'deep' => 5,
      'path' => 4,
      _ => 4,
    };

    // Ghép câu cho đến khi đạt tối thiểu, rồi thêm chừng nào còn vừa khung từ.
    final List<String> sentences = <String>[];
    int total = 0;
    int cursor = 0;
    while (total < targetMin) {
      final String sentence =
          _lessonSentences[cursor % _lessonSentences.length];
      sentences.add(sentence);
      total += _words(sentence);
      cursor++;
    }
    while (true) {
      final String sentence =
          _lessonSentences[cursor % _lessonSentences.length];
      final int sentenceWords = _words(sentence);
      if (total + sentenceWords > targetMax) break;
      sentences.add(sentence);
      total += sentenceWords;
      cursor++;
    }

    final int perSection = (sentences.length / sectionCount).ceil();
    final List<AiLessonSection> sections = <AiLessonSection>[];
    for (int s = 0; s < sectionCount; s++) {
      final int start = s * perSection;
      if (start >= sentences.length) break;
      final int end = (start + perSection).clamp(0, sentences.length);
      final String body = sentences.sublist(start, end).join(' ');
      if (body.isEmpty) continue;
      final String prefix = mode == 'path' ? 'Chặng ${s + 1}' : 'Phần ${s + 1}';
      sections.add(
        AiLessonSection(
          heading: '$prefix: ${_lessonHeadings[s % _lessonHeadings.length]}',
          body: body,
        ),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        AiLessonSection(
          heading: 'Phần 1: ${_lessonHeadings.first}',
          body: sentences.join(' '),
        ),
      );
    }

    final List<AiQuestionDraft> questions = <AiQuestionDraft>[];
    final int qCount = questionCount < 3
        ? 3
        : (questionCount > 5 ? 5 : questionCount);
    for (int i = 0; i < qCount; i++) {
      final AiLessonSection section = sections[i % sections.length];
      final String firstSentence = section.body
          .split(RegExp(r'[.!?]+'))
          .first
          .trim();
      questions.add(
        AiQuestionDraft(
          question:
              'Trong "${section.heading}", ý chính cần nhớ về $topic là gì?',
          answer: firstSentence.isEmpty ? section.body : '$firstSentence.',
          explanation: 'Xem lại mục "${section.heading}" để đối chiếu.',
        ),
      );
    }

    final String lowerTopic = topic.toLowerCase();
    final bool medical = _medicalKeywords.any(lowerTopic.contains);

    // Tạo concepts mẫu
    final List<AiLessonConcept> concepts = <AiLessonConcept>[
      AiLessonConcept(
        name: 'Khái niệm cốt lõi 1',
        explanation:
            'Giải thích chi tiết về khái niệm cốt lõi đầu tiên liên quan đến $topic.',
      ),
      AiLessonConcept(
        name: 'Khái niệm cốt lõi 2',
        explanation:
            'Giải thích chi tiết về khái niệm cốt lõi thứ hai liên quan đến $topic.',
      ),
    ];

    return AiLessonDraft(
      title: '$topic — khám phá trong $domain',
      learningObjectives: <String>[
        'Hiểu được khái niệm cơ bản của $topic',
        'Nắm vững các nguyên lý quan trọng',
        'Áp dụng được vào thực tế',
      ],
      introduction:
          'Bài học này giúp bạn khám phá $topic trong lĩnh vực $domain, '
          'đi từ bức tranh tổng quan đến những chi tiết đáng nhớ nhất.',
      concepts: concepts,
      sections: sections,
      keyPoints: <String>[
        for (final AiLessonSection section in sections.take(3))
          '${section.body.split(RegExp(r'[.!?]+')).first.trim()}.',
      ],
      examples: <String>[
        'Ví dụ gần gũi: ${_lessonSentences[2]}',
        'Tình huống thực tế: ${_lessonSentences[5]}',
      ],
      commonMistakes: <String>[
        'Học vẹt mà không hiểu bản chất',
        'Bỏ qua việc ôn tập định kỳ',
        'Không liên kết kiến thức mới với kiến thức cũ',
      ],
      summary:
          'Tóm lại, $topic đòi hỏi cách nhìn vừa bao quát vừa chi tiết. '
          'Hãy quay lại các phần chính và làm quiz ghi nhớ để giữ bài học lâu dài.',
      questions: questions,
      sources: const <AiLessonSource>[], // Mock không bịa nguồn.
      medical: medical,
    );
  }

  @override
  Future<List<AiTopicSuggestion>> suggestTopics({
    required String domain,
    int count = 20,
  }) async {
    await _delay();
    final int total = count.clamp(1, 40);
    // Mock KHÔNG tự chế chuỗi ngẫu nhiên: dùng catalog chủ đề tiếng Việt
    // đã biên soạn để nội dung luôn đọc được và khác nhau về ý nghĩa.
    final LearningDomain? learningDomain = LearningDomains.byName(domain);
    final List<TopicSeed> seeds = TopicSeedCatalog.forDomain(
      domain,
      learningDomain?.sampleTopics ?? const <String>[],
      count: total,
    );
    return <AiTopicSuggestion>[
      for (final TopicSeed seed in seeds)
        AiTopicSuggestion(title: seed.title, description: seed.description),
    ];
  }
}
