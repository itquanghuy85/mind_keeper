import 'package:fsrs/fsrs.dart' as fsrs;

import 'enums.dart';

class ReviewCard {
  const ReviewCard({
    required this.id,
    required this.knowledgeItemId,
    required this.question,
    required this.answer,
    this.questionType = QuestionType.recall,
    this.fsrsState = 0,
    this.fsrsStep = 0,
    this.stability,
    this.difficulty,
    required this.dueAt,
    this.lastReviewAt,
    this.reps = 0,
    this.lapses = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String knowledgeItemId;
  final String question;
  final String answer;
  final QuestionType questionType;
  final int fsrsState;
  final int? fsrsStep;
  final double? stability;
  final double? difficulty;
  final DateTime dueAt;
  final DateTime? lastReviewAt;
  final int reps;
  final int lapses;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isNew => lastReviewAt == null;
  bool isDue(DateTime now) => !dueAt.isAfter(now);

  ReviewCard copyWith({
    String? question,
    String? answer,
    QuestionType? questionType,
    int? fsrsState,
    int? fsrsStep,
    double? stability,
    double? difficulty,
    DateTime? dueAt,
    DateTime? lastReviewAt,
    int? reps,
    int? lapses,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ReviewCard(
      id: id,
      knowledgeItemId: knowledgeItemId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      questionType: questionType ?? this.questionType,
      fsrsState: fsrsState ?? this.fsrsState,
      fsrsStep: fsrsStep ?? this.fsrsStep,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueAt: dueAt ?? this.dueAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  fsrs.Card toFsrsCard() {
    return fsrs.Card(
      cardId: id.hashCode & 0x7fffffff,
      state: fsrs.State.values.firstWhere(
        (fsrs.State e) => e.index == fsrsState,
        orElse: () => fsrs.State.learning,
      ),
      step: fsrsStep,
      stability: stability,
      difficulty: difficulty,
      due: dueAt.toUtc(),
      lastReview: lastReviewAt?.toUtc(),
    );
  }

  static ReviewCard fromFsrsCard({
    required ReviewCard card,
    required fsrs.Card updated,
    required DateTime updatedAt,
    bool lapsesIncrement = false,
  }) {
    return card.copyWith(
      fsrsState: updated.state.index,
      fsrsStep: updated.step,
      stability: updated.stability,
      difficulty: updated.difficulty,
      dueAt: updated.due.toLocal(),
      lastReviewAt: updated.lastReview?.toLocal(),
      reps: updated.lastReview == null ? card.reps : card.reps + 1,
      lapses: lapsesIncrement ? card.lapses + 1 : card.lapses,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'knowledge_item_id': knowledgeItemId,
    'question': question,
    'answer': answer,
    'question_type': questionType.dbValue,
    'fsrs_state': fsrsState,
    'fsrs_step': fsrsStep,
    'stability': stability,
    'difficulty': difficulty,
    'due_at': dueAt.toUtc().millisecondsSinceEpoch,
    'last_review_at': lastReviewAt?.toUtc().millisecondsSinceEpoch,
    'reps': reps,
    'lapses': lapses,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory ReviewCard.fromMap(Map<String, Object?> map) => ReviewCard(
    id: map['id']! as String,
    knowledgeItemId: map['knowledge_item_id']! as String,
    question: map['question']! as String,
    answer: map['answer']! as String,
    questionType: QuestionType.fromDb(map['question_type'] as String?),
    fsrsState: ((map['fsrs_state'] ?? 0) as int).clamp(0, 2),
    fsrsStep: map['fsrs_step'] as int?,
    stability: (map['stability'] as num?)?.toDouble(),
    difficulty: (map['difficulty'] as num?)?.toDouble(),
    dueAt: DateTime.fromMillisecondsSinceEpoch(
      (map['due_at']! as num).toInt(),
      isUtc: true,
    ),
    lastReviewAt: map['last_review_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            (map['last_review_at']! as num).toInt(),
            isUtc: true,
          ),
    reps: ((map['reps'] ?? 0) as int),
    lapses: ((map['lapses'] ?? 0) as int),
    isActive: ((map['is_active'] ?? 1) as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['created_at']! as num).toInt(),
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['updated_at']! as num).toInt(),
      isUtc: true,
    ),
  );
}
