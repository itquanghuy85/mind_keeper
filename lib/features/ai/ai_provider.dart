/// Schema đầu vào/đầu ra cho AI. Validate trước khi dùng kết quả.
library;

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
    final String explanation =
        (map['explanation'] ?? '').toString().trim();
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
class AiLessonDraft {
  const AiLessonDraft({
    required this.title,
    required this.introduction,
    required this.sections,
    required this.keyPoints,
    required this.examples,
    required this.summary,
    required this.questions,
    required this.sources,
    this.medical = false,
  });

  final String title;
  final String introduction;
  final List<AiLessonSection> sections;
  final List<String> keyPoints;
  final List<String> examples;
  final String summary;
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
    for (final AiLessonSection section in sections) {
      total += count(section.heading) + count(section.body);
    }
    for (final String point in keyPoints) {
      total += count(point);
    }
    for (final String example in examples) {
      total += count(example);
    }
    return total;
  }

  factory AiLessonDraft.fromMap(
    Map<String, Object?> map, {
    int maxQuestions = 5,
  }) {
    final String title = (map['title'] ?? '').toString().trim();
    final String introduction =
        (map['introduction'] ?? '').toString().trim();
    if (title.isEmpty || introduction.isEmpty) {
      throw const FormatException('Thiếu title hoặc introduction');
    }
    final List<AiLessonSection> sections = <AiLessonSection>[];
    for (final Object? item in (map['sections'] as List<Object?>?) ?? const <Object?>[]) {
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
    for (final Object? item in (map['questions'] as List<Object?>?) ?? const <Object?>[]) {
      if (item is! Map<String, Object?>) continue;
      try {
        questions.add(AiQuestionDraft.fromMap(item));
      } on FormatException {
        continue;
      }
      if (questions.length >= maxQuestions) break;
    }
    final List<AiLessonSource> sources = <AiLessonSource>[];
    for (final Object? item in (map['sources'] as List<Object?>?) ?? const <Object?>[]) {
      if (item is! Map<String, Object?>) continue;
      try {
        sources.add(AiLessonSource.fromMap(item));
      } on FormatException {
        continue;
      }
    }
    return AiLessonDraft(
      title: title,
      introduction: introduction,
      sections: sections,
      keyPoints: _textList(map['key_points']),
      examples: _textList(map['examples']),
      summary: (map['summary'] ?? '').toString().trim(),
      questions: questions,
      sources: sources,
      medical: map['medical'] == true,
    );
  }

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
}
