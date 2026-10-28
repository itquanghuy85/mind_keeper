/// Schema đầu vào/đầu ra cho AI. Validate trước khi dùng kết quả.
library;

import '../../core/services/notification_text.dart';

/// Exception cho lỗi cấu hình AI.
class AiConfigurationException implements Exception {
  const AiConfigurationException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  final String code;
  final String message;
  final String userMessage;

  @override
  String toString() => 'AiConfigurationException($code): $message';
}

class AiQuestionDraft {
  const AiQuestionDraft({
    required this.question,
    required this.answer,
    this.explanation = '',
  });

  final String question;
  final String answer;
  final String explanation;

  factory AiQuestionDraft.fromMap(Map<String, Object?> map) {
    final String question = (map['question'] ?? '').toString().trim();
    final String answer = (map['answer'] ?? '').toString().trim();
    if (question.isEmpty || answer.isEmpty) {
      throw const FormatException('Thiếu question hoặc answer');
    }
    return AiQuestionDraft(
      question: question,
      answer: answer,
      explanation: (map['explanation'] ?? '').toString().trim(),
    );
  }
}

class AiKnowledgeDraft {
  const AiKnowledgeDraft({
    required this.title,
    required this.content,
    this.details = '',
  });

  final String title;
  final String content;
  final String details;

  factory AiKnowledgeDraft.fromMap(Map<String, Object?> map) {
    final String title = (map['title'] ?? '').toString().trim();
    final String content = (map['content'] ?? '').toString().trim();
    if (title.isEmpty || content.isEmpty) {
      throw const FormatException('Thiếu title hoặc content');
    }
    return AiKnowledgeDraft(
      title: title,
      content: content,
      details: (map['details'] ?? '').toString().trim(),
    );
  }
}

class AiAnswerEvaluation {
  const AiAnswerEvaluation({
    required this.verdict,
    required this.comment,
    this.score,
  });

  /// 'correct' | 'partial' | 'wrong'
  final String verdict;
  final String comment;
  final double? score;

  factory AiAnswerEvaluation.fromMap(Map<String, Object?> map) {
    final String verdict = (map['verdict'] ?? '').toString().trim();
    if (verdict != 'correct' && verdict != 'partial' && verdict != 'wrong') {
      throw const FormatException('Verdict không hợp lệ');
    }
    return AiAnswerEvaluation(
      verdict: verdict,
      comment: (map['comment'] ?? '').toString(),
      score: (map['score'] as num?)?.toDouble(),
    );
  }
}

class AiTutorExplanation {
  const AiTutorExplanation({required this.explanation, this.example = ''});

  final String explanation;
  final String example;

  factory AiTutorExplanation.fromMap(Map<String, Object?> map) {
    final String explanation = (map['explanation'] ?? '').toString().trim();
    if (explanation.isEmpty) {
      throw const FormatException('Thiếu explanation');
    }
    return AiTutorExplanation(
      explanation: explanation,
      example: (map['example'] ?? '').toString().trim(),
    );
  }
}

class AiLessonSection {
  const AiLessonSection({required this.heading, required this.body});

  final String heading;
  final String body;

  factory AiLessonSection.fromMap(Map<String, Object?> map) {
    final String heading = (map['heading'] ?? '').toString().trim();
    final String body = (map['body'] ?? '').toString().trim();
    if (heading.isEmpty || body.isEmpty) {
      throw const FormatException('Thiếu heading hoặc body');
    }
    return AiLessonSection(heading: heading, body: body);
  }
}

class AiLessonConcept {
  const AiLessonConcept({required this.name, required this.explanation});

  final String name;
  final String explanation;

  factory AiLessonConcept.fromMap(Map<String, Object?> map) {
    final String name = (map['name'] ?? '').toString().trim();
    final String explanation = (map['explanation'] ?? '').toString().trim();
    if (name.isEmpty || explanation.isEmpty) {
      throw const FormatException('Thiếu name hoặc explanation cho concept');
    }
    return AiLessonConcept(name: name, explanation: explanation);
  }
}

class AiLessonSource {
  const AiLessonSource({required this.title, this.url = ''});

  final String title;
  final String url;

  factory AiLessonSource.fromMap(Map<String, Object?> map) {
    final String title = (map['title'] ?? '').toString().trim();
    if (title.isEmpty) {
      throw const FormatException('Thiếu title nguồn');
    }
    return AiLessonSource(
      title: title,
      url: (map['url'] ?? '').toString().trim(),
    );
  }
}

/// Bài học AI: cấu trúc đầy đủ cho một buổi khám phá kiến thức.
class AiTopicSuggestion {
  const AiTopicSuggestion({required this.title, required this.description});

  final String title;
  final String description;

  factory AiTopicSuggestion.fromMap(Map<String, Object?> map) {
    final String title = (map['title'] ?? '').toString().trim();
    final String description = (map['description'] ?? '').toString().trim();
    if (title.isEmpty) {
      throw const FormatException('Thiếu title chủ đề.');
    }
    return AiTopicSuggestion(
      title: title,
      description: description.isEmpty ? title : description,
    );
  }
}

class AiLessonDraft {
  const AiLessonDraft({
    required this.title,
    required this.learningObjectives,
    required this.introduction,
    required this.concepts,
    required this.sections,
    required this.keyPoints,
    required this.examples,
    required this.commonMistakes,
    required this.summary,
    required this.questions,
    required this.sources,
    this.medical = false,
    this.memoryTip = '',
  });

  final String title;
  final List<String> learningObjectives;
  final String introduction;
  final List<AiLessonConcept> concepts;
  final List<AiLessonSection> sections;
  final List<String> keyPoints;
  final List<String> examples;
  final List<String> commonMistakes;
  final String summary;

  /// Mẹo nhớ 1 câu (≤120 ký tự); rỗng nếu AI không trả về.
  final String memoryTip;
  final List<AiQuestionDraft> questions;

  /// Nguồn tham khảo. BẮT BUỘC để rỗng khi AI không chắc — không được bịa.
  final List<AiLessonSource> sources;

  /// true khi nội dung liên quan y tế → bắt buộc kèm disclaimer.
  final bool medical;

  int get wordCount {
    int count(String text) {
      final String t = text.trim();
      return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
    }

    int total = count(introduction) + count(summary);
    for (final String obj in learningObjectives) {
      total += count(obj);
    }
    for (final AiLessonConcept concept in concepts) {
      total += count(concept.name) + count(concept.explanation);
    }
    for (final AiLessonSection section in sections) {
      total += count(section.heading) + count(section.body);
    }
    for (final String point in keyPoints) {
      total += count(point);
    }
    for (final String example in examples) {
      total += count(example);
    }
    for (final String mistake in commonMistakes) {
      total += count(mistake);
    }
    return total;
  }

  /// Đọc một trường văn bản, chấp nhận CẢ camelCase lẫn snake_case.
  ///
  /// Lý do: prompt sinh bài học trong `HttpAIProvider` yêu cầu AI trả về
  /// **camelCase** (`learningObjectives`, `keyPoints`, `commonMistakes`) nhưng
  /// các provider/model khác hoặc bản cache cũ có thể trả **snake_case**
  /// (`learning_objectives`, `key_points`, `common_mistakes`). Nếu chỉ đọc một
  /// kiểu, nội dung sẽ bị mất âm thầm (mục tiêu học/ý chính/sai lầm rỗng).
  /// Ưu tiên camelCase (đúng contract prompt), fallback snake_case.
  static String _pick(
    Map<String, Object?> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final Object? value = map[key];
      if (value == null) continue;
      final String text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  /// Đọc một danh sách văn bản, chấp nhận cả camelCase lẫn snake_case.
  static List<String> _pickTextList(
    Map<String, Object?> map,
    List<String> keys,
  ) {
    for (final String key in keys) {
      if (!map.containsKey(key)) continue;
      final List<String> list = _textList(map[key]);
      if (list.isNotEmpty) return list;
    }
    return const <String>[];
  }

  factory AiLessonDraft.fromMap(
    Map<String, Object?> map, {
    int maxQuestions = 5,
  }) {
    final String title = _pick(map, <String>['title']);
    final String introduction = _pick(map, <String>['introduction']);
    if (title.isEmpty || introduction.isEmpty) {
      throw const FormatException('Thiếu title hoặc introduction');
    }
    final List<String> learningObjectives = _pickTextList(map, <String>[
      'learningObjectives',
      'learning_objectives',
    ]);
    final List<AiLessonConcept> concepts = <AiLessonConcept>[];
    for (final Object? item
        in (map['concepts'] as List<Object?>?) ?? const <Object?>[]) {
      if (item is! Map<String, Object?>) continue;
      try {
        concepts.add(AiLessonConcept.fromMap(item));
      } on FormatException {
        continue;
      }
    }
    final List<AiLessonSection> sections = <AiLessonSection>[];
    for (final Object? item
        in (map['sections'] as List<Object?>?) ?? const <Object?>[]) {
      if (item is! Map<String, Object?>) continue;
      try {
        sections.add(AiLessonSection.fromMap(item));
      } on FormatException {
        continue;
      }
    }
    if (sections.isEmpty) {
      throw const FormatException('Bài học không có phần nội dung nào');
    }
    final List<AiQuestionDraft> questions = <AiQuestionDraft>[];
    for (final Object? item
        in (map['questions'] as List<Object?>?) ?? const <Object?>[]) {
      if (item is! Map<String, Object?>) continue;
      try {
        questions.add(AiQuestionDraft.fromMap(item));
      } on FormatException {
        continue;
      }
      if (questions.length >= maxQuestions) break;
    }
    final List<AiLessonSource> sources = <AiLessonSource>[];
    for (final Object? item
        in (map['sources'] as List<Object?>?) ?? const <Object?>[]) {
      if (item is! Map<String, Object?>) continue;
      try {
        sources.add(AiLessonSource.fromMap(item));
      } on FormatException {
        continue;
      }
    }
    return AiLessonDraft(
      title: title,
      learningObjectives: learningObjectives,
      introduction: introduction,
      concepts: concepts,
      sections: sections,
      keyPoints: _pickTextList(map, <String>['keyPoints', 'key_points']),
      examples: _pickTextList(map, <String>['examples']),
      commonMistakes: _pickTextList(map, <String>[
        'commonMistakes',
        'common_mistakes',
      ]),
      summary: _clamp(_pick(map, <String>['summary']), maxSummaryChars),
      memoryTip: _clamp(
        _pick(map, <String>['memoryTip', 'memory_tip', 'tip']),
        maxMemoryTipChars,
      ),
      questions: questions,
      sources: sources,
      medical: map['medical'] == true || map['is_medical'] == true,
    );
  }

  /// Giới hạn tóm tắt / mẹo nhớ của bài học mới (ký tự).
  static const int maxSummaryChars = 200;
  static const int maxMemoryTipChars = 120;

  static String _clamp(String text, int max) =>
      text.length <= max ? text : truncateAtWord(text, max);

  static List<String> _textList(Object? value) {
    if (value is! List<Object?>) return const <String>[];
    return <String>[
      for (final Object? item in value)
        if (item != null && item.toString().trim().isNotEmpty)
          item.toString().trim(),
    ];
  }
}

/// Interface nhà cung cấp AI. Mọi provider (mock, HTTP thật) phải implement.
abstract class AIProvider {
  String get name;
  bool get isConfigured;

  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  });

  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  });

  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  });

  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  });

  /// Tạo bài học cho khám phá kiến thức. Kết quả phải nằm trong khoảng
  /// [wordMin, wordMax] từ và có 3–5 câu hỏi ghi nhớ.
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  });

  /// Gợi ý danh sách chủ đề liên quan để người dùng chọn.
  Future<List<AiTopicSuggestion>> suggestTopics({
    required String domain,
    int count = 20,
  });
}
