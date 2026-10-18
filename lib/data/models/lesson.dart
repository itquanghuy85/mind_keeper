import 'dart:convert';

/// Chế độ học bài AI. `wordMin/wordMax` là khoảng từ của toàn bài.
enum LessonMode {
  overview(
    id: 'overview',
    label: 'Tổng quan',
    description: 'Một vòng quan sát nhanh toàn cảnh chủ đề.',
    wordMin: 180,
    wordMax: 300,
    questions: 3,
  ),
  standard(
    id: 'standard',
    label: 'Tiêu chuẩn',
    description: 'Bài cân bằng, đọc trong 3–5 phút.',
    wordMin: 350,
    wordMax: 600,
    questions: 4,
  ),
  deep(
    id: 'deep',
    label: 'Chuyên sâu',
    description: 'Nhiều phần chi tiết, đào sâu từng khái niệm.',
    wordMin: 400,
    wordMax: 700,
    questions: 5,
  ),
  path(
    id: 'path',
    label: 'Theo lộ trình',
    description: 'Đi từng chặng, mỗi chặng có quiz chặn để mở tiếp.',
    wordMin: 300,
    wordMax: 600,
    questions: 4,
  );

  const LessonMode({
    required this.id,
    required this.label,
    required this.description,
    required this.wordMin,
    required this.wordMax,
    required this.questions,
  });

  final String id;
  final String label;
  final String description;
  final int wordMin;
  final int wordMax;

  /// Số câu hỏi ghi nhớ mặc định của chế độ (3–5).
  final int questions;

  /// Quiz chặn: phải qua câu hỏi mới mở chặng tiếp theo.
  bool get isGated => this == LessonMode.path;

  static LessonMode? tryParse(String? id) {
    for (final LessonMode mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }

  static LessonMode get defaultMode => LessonMode.standard;
}

/// Trạng thái xác minh nguồn của bài học (nhãn hiển thị cho người học).
enum LessonVerification {
  unverified('unverified', 'Chưa xác minh'),
  sourced('sourced', 'Có nguồn tham khảo'),
  confirmed('confirmed', 'Đã kiểm chứng');

  const LessonVerification(this.id, this.label);

  final String id;
  final String label;

  static LessonVerification tryParse(String? id) {
    for (final LessonVerification value in values) {
      if (value.id == id) return value;
    }
    return LessonVerification.unverified;
  }
}

int countLessonWords(String text) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

class LessonSection {
  const LessonSection({required this.heading, required this.body});

  final String heading;
  final String body;

  factory LessonSection.fromMap(Map<String, Object?> map) {
    return LessonSection(
      heading: (map['heading'] ?? '').toString().trim(),
      body: (map['body'] ?? '').toString().trim(),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'heading': heading,
    'body': body,
  };
}

class LessonQuestion {
  const LessonQuestion({
    required this.question,
    required this.answer,
    this.explanation = '',
  });

  final String question;
  final String answer;
  final String explanation;

  factory LessonQuestion.fromMap(Map<String, Object?> map) {
    return LessonQuestion(
      question: (map['question'] ?? '').toString().trim(),
      answer: (map['answer'] ?? '').toString().trim(),
      explanation: (map['explanation'] ?? '').toString().trim(),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'question': question,
    'answer': answer,
    'explanation': explanation,
  };
}

class LessonSource {
  const LessonSource({required this.title, this.url = ''});

  final String title;
  final String url;

  factory LessonSource.fromMap(Map<String, Object?> map) {
    return LessonSource(
      title: (map['title'] ?? '').toString().trim(),
      url: (map['url'] ?? '').toString().trim(),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{'title': title, 'url': url};
}

class LessonConcept {
  const LessonConcept({required this.name, required this.explanation});

  final String name;
  final String explanation;

  factory LessonConcept.fromMap(Map<String, Object?> map) {
    return LessonConcept(
      name: (map['name'] ?? '').toString().trim(),
      explanation: (map['explanation'] ?? '').toString().trim(),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'name': name,
    'explanation': explanation,
  };
}

/// Cấu trúc nội dung bài học (lưu trong lessons.content_json).
class LessonContent {
  const LessonContent({
    required this.learningObjectives,
    required this.introduction,
    required this.concepts,
    required this.sections,
    required this.keyPoints,
    required this.examples,
    required this.commonMistakes,
    required this.summary,
  });

  final List<String> learningObjectives;
  final String introduction;
  final List<LessonConcept> concepts;
  final List<LessonSection> sections;
  final List<String> keyPoints;
  final List<String> examples;
  final List<String> commonMistakes;
  final String summary;

  factory LessonContent.fromMap(Map<String, Object?> map) {
    final String introduction = (map['introduction'] ?? '').toString().trim();
    final List<String> learningObjectives = _stringList(
      map['learning_objectives'],
    );
    final List<LessonConcept> concepts = <LessonConcept>[
      for (final Object? item
          in (map['concepts'] as List<Object?>?) ?? const <Object?>[])
        if (item is Map<String, Object?>) LessonConcept.fromMap(item),
    ];
    final List<LessonSection> sections =
        <LessonSection>[
              for (final Object? item
                  in (map['sections'] as List<Object?>?) ?? const <Object?>[])
                if (item is Map<String, Object?>) LessonSection.fromMap(item),
            ]
            .where(
              (LessonSection s) => s.heading.isNotEmpty && s.body.isNotEmpty,
            )
            .toList();
    if (introduction.isEmpty || sections.isEmpty) {
      throw const FormatException(
        'Bài học thiếu phần mở đầu hoặc các phần nội dung',
      );
    }
    return LessonContent(
      learningObjectives: learningObjectives,
      introduction: introduction,
      concepts: concepts,
      sections: sections,
      keyPoints: _stringList(map['key_points']),
      examples: _stringList(map['examples']),
      commonMistakes: _stringList(map['common_mistakes']),
      summary: (map['summary'] ?? '').toString().trim(),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List<Object?>) return const <String>[];
    return <String>[
      for (final Object? item in value)
        if (item != null && item.toString().trim().isNotEmpty)
          item.toString().trim(),
    ];
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'learning_objectives': learningObjectives,
    'introduction': introduction,
    'concepts': concepts.map((LessonConcept c) => c.toMap()).toList(),
    'sections': sections.map((LessonSection s) => s.toMap()).toList(),
    'key_points': keyPoints,
    'examples': examples,
    'common_mistakes': commonMistakes,
    'summary': summary,
  };

  int get wordCount {
    int total = countLessonWords(introduction);
    for (final String obj in learningObjectives) {
      total += countLessonWords(obj);
    }
    for (final LessonConcept concept in concepts) {
      total +=
          countLessonWords(concept.name) +
          countLessonWords(concept.explanation);
    }
    for (final LessonSection section in sections) {
      total +=
          countLessonWords(section.heading) + countLessonWords(section.body);
    }
    total += countLessonWords(summary);
    for (final String point in keyPoints) {
      total += countLessonWords(point);
    }
    for (final String example in examples) {
      total += countLessonWords(example);
    }
    for (final String mistake in commonMistakes) {
      total += countLessonWords(mistake);
    }
    return total;
  }
}

/// Bài học AI khám phá kiến thức — lưu trọn gói, không sinh lại khi đã có.
class Lesson {
  const Lesson({
    required this.id,
    required this.domainId,
    required this.domainName,
    required this.topic,
    required this.mode,
    required this.promptVersion,
    required this.dedupKey,
    required this.title,
    required this.content,
    required this.questions,
    required this.sources,
    required this.verification,
    required this.medical,
    required this.wordCount,
    required this.isFavorite,
    required this.isRead,
    required this.linkedTopicId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String domainId;
  final String domainName;
  final String topic;
  final LessonMode mode;
  final String promptVersion;
  final String dedupKey;
  final String title;
  final LessonContent content;
  final List<LessonQuestion> questions;
  final List<LessonSource> sources;
  final LessonVerification verification;
  final bool medical;
  final int wordCount;
  final bool isFavorite;
  final bool isRead;

  /// Chủ đề đã ghép vào bộ nhớ dài hạn (đã có thẻ ôn tập).
  final String? linkedTopicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Khóa chống trùng lặp: lĩnh vực + chủ đề + chế độ + phiên bản prompt.
  static String buildDedupKey({
    required String domainId,
    required String topic,
    required LessonMode mode,
    required String promptVersion,
  }) {
    final String normalizedTopic = topic.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return '$domainId|$normalizedTopic|${mode.id}|$promptVersion';
  }

  bool get isLinked => linkedTopicId != null;

  factory Lesson.fromRow(Map<String, Object?> row) {
    final Object? contentRaw = row['content_json'];
    final Map<String, Object?> contentMap =
        contentRaw is String && contentRaw.trim().isNotEmpty
        ? jsonDecode(contentRaw) as Map<String, Object?>
        : <String, Object?>{};
    return Lesson(
      id: row['id']! as String,
      domainId: row['domain_id']! as String,
      domainName: (row['domain_name'] ?? '').toString(),
      topic: row['topic']! as String,
      mode:
          LessonMode.tryParse((row['mode'] ?? '').toString()) ??
          LessonMode.defaultMode,
      promptVersion: (row['prompt_version'] ?? '').toString(),
      dedupKey: (row['dedup_key'] ?? '').toString(),
      title: (row['title'] ?? '').toString(),
      content: LessonContent.fromMap(contentMap),
      questions: decodeQuestions(row['questions_json']),
      sources: decodeSources(row['sources_json']),
      verification: LessonVerification.tryParse(
        (row['verification'] ?? '').toString(),
      ),
      medical: ((row['medical'] as num?) ?? 0) != 0,
      wordCount: ((row['word_count'] as num?) ?? 0).toInt(),
      isFavorite: ((row['is_favorite'] as num?) ?? 0) != 0,
      isRead: ((row['is_read'] as num?) ?? 0) != 0,
      linkedTopicId: row['linked_topic_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at']! as num).toInt(),
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at']! as num).toInt(),
        isUtc: true,
      ),
    );
  }

  Map<String, Object?> toRow() => <String, Object?>{
    'id': id,
    'domain_id': domainId,
    'domain_name': domainName,
    'topic': topic,
    'mode': mode.id,
    'prompt_version': promptVersion,
    'dedup_key': dedupKey,
    'title': title,
    'content_json': jsonEncode(content.toMap()),
    'questions_json': jsonEncode(
      questions.map((LessonQuestion q) => q.toMap()).toList(),
    ),
    'sources_json': jsonEncode(
      sources.map((LessonSource s) => s.toMap()).toList(),
    ),
    'verification': verification.id,
    'medical': medical ? 1 : 0,
    'word_count': wordCount,
    'is_favorite': isFavorite ? 1 : 0,
    'is_read': isRead ? 1 : 0,
    'linked_topic_id': linkedTopicId,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  static List<LessonQuestion> decodeQuestions(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return const <LessonQuestion>[];
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) return const <LessonQuestion>[];
    return <LessonQuestion>[
          for (final Object? item in decoded)
            if (item is Map<String, Object?>) LessonQuestion.fromMap(item),
        ]
        .where(
          (LessonQuestion q) => q.question.isNotEmpty && q.answer.isNotEmpty,
        )
        .toList();
  }

  static List<LessonSource> decodeSources(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return const <LessonSource>[];
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) return const <LessonSource>[];
    return <LessonSource>[
      for (final Object? item in decoded)
        if (item is Map<String, Object?>) LessonSource.fromMap(item),
    ].where((LessonSource s) => s.title.isNotEmpty).toList();
  }

  Lesson copyWith({
    bool? isFavorite,
    bool? isRead,
    String? linkedTopicId,
    bool clearLinkedTopicId = false,
  }) {
    return Lesson(
      id: id,
      domainId: domainId,
      domainName: domainName,
      topic: topic,
      mode: mode,
      promptVersion: promptVersion,
      dedupKey: dedupKey,
      title: title,
      content: content,
      questions: questions,
      sources: sources,
      verification: verification,
      medical: medical,
      wordCount: wordCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isRead: isRead ?? this.isRead,
      linkedTopicId: clearLinkedTopicId
          ? null
          : (linkedTopicId ?? this.linkedTopicId),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
