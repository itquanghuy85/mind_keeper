enum TopicOrigin {
  personal('personal'),
  system('system'),
  discovered('discovered');

  const TopicOrigin(this.dbValue);

  final String dbValue;

  static TopicOrigin fromDb(String? value) => TopicOrigin.values.firstWhere(
    (TopicOrigin e) => e.dbValue == value,
    orElse: () => TopicOrigin.personal,
  );
}

enum SourceType {
  text('text'),
  image('image'),
  pdf('pdf'),
  document('document'),
  audio('audio'),
  link('link');

  const SourceType(this.dbValue);

  final String dbValue;

  static SourceType fromDb(String? value) => SourceType.values.firstWhere(
    (SourceType e) => e.dbValue == value,
    orElse: () => SourceType.text,
  );
}

enum SourceStatus {
  pending('pending'),
  processing('processing'),
  ready('ready'),
  failed('failed');

  const SourceStatus(this.dbValue);

  final String dbValue;

  static SourceStatus fromDb(String? value) => SourceStatus.values.firstWhere(
    (SourceStatus e) => e.dbValue == value,
    orElse: () => SourceStatus.ready,
  );
}

enum KnowledgeOrigin {
  extracted('extracted'),
  aiSuggested('ai_suggested'),
  userConfirmed('user_confirmed');

  const KnowledgeOrigin(this.dbValue);

  final String dbValue;

  static KnowledgeOrigin fromDb(String? value) =>
      KnowledgeOrigin.values.firstWhere(
        (KnowledgeOrigin e) => e.dbValue == value,
        orElse: () => KnowledgeOrigin.userConfirmed,
      );
}

enum QuestionType {
  recall('recall'),
  cloze('cloze'),
  multipleChoice('multiple_choice'),
  freeForm('free_form');

  const QuestionType(this.dbValue);

  final String dbValue;

  static QuestionType fromDb(String? value) => QuestionType.values.firstWhere(
    (QuestionType e) => e.dbValue == value,
    orElse: () => QuestionType.recall,
  );
}

enum MemoryRating {
  again(1, 'Quên', 'Again'),
  hard(2, 'Khó', 'Hard'),
  good(3, 'Tốt', 'Good'),
  easy(4, 'Dễ', 'Easy');

  const MemoryRating(this.value, this.vietnameseLabel, this.fsrsLabel);

  final int value;
  final String vietnameseLabel;
  final String fsrsLabel;

  static MemoryRating fromValue(int? value) => MemoryRating.values.firstWhere(
    (MemoryRating e) => e.value == value,
    orElse: () => MemoryRating.good,
  );
}
