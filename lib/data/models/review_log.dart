import 'enums.dart';

class ReviewLog {
  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.reviewedAt,
    required this.rating,
    this.dueBefore,
    this.dueAfter,
    this.stateBefore,
    this.stateAfter,
    this.stabilityBefore,
    this.stabilityAfter,
    this.answerText,
    this.autoGrade,
    this.note,
  });

  final String id;
  final String cardId;
  final DateTime reviewedAt;
  final MemoryRating rating;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final int? stateBefore;
  final int? stateAfter;
  final double? stabilityBefore;
  final double? stabilityAfter;
  final String? answerText;
  final String? autoGrade;
  final String? note;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'card_id': cardId,
        'reviewed_at': reviewedAt.toUtc().millisecondsSinceEpoch,
        'rating': rating.value,
        'due_before': dueBefore?.toUtc().millisecondsSinceEpoch,
        'due_after': dueAfter?.toUtc().millisecondsSinceEpoch,
        'state_before': stateBefore,
        'state_after': stateAfter,
        'stability_before': stabilityBefore,
        'stability_after': stabilityAfter,
        'answer_text': answerText,
        'auto_grade': autoGrade,
        'note': note,
      };

  factory ReviewLog.fromMap(Map<String, Object?> map) => ReviewLog(
        id: map['id']! as String,
        cardId: map['card_id']! as String,
        reviewedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['reviewed_at']! as num).toInt(),
          isUtc: true,
        ),
        rating: MemoryRating.fromValue((map['rating']! as num).toInt()),
        dueBefore: map['due_before'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (map['due_before']! as num).toInt(),
                isUtc: true,
              ),
        dueAfter: map['due_after'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (map['due_after']! as num).toInt(),
                isUtc: true,
              ),
        stateBefore: map['state_before'] as int?,
        stateAfter: map['state_after'] as int?,
        stabilityBefore: (map['stability_before'] as num?)?.toDouble(),
        stabilityAfter: (map['stability_after'] as num?)?.toDouble(),
        answerText: map['answer_text'] as String?,
        autoGrade: map['auto_grade'] as String?,
        note: map['note'] as String?,
      );
}
