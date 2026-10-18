import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/models/enums.dart';
import '../../data/models/review_card.dart';
import '../../data/models/review_log.dart';

/// Kết quả lập lịch FSRS cho một lần ôn.
class ScheduleResult {
  const ScheduleResult({required this.card, required this.log});

  final ReviewCard card;
  final ReviewLog log;
}

/// Adapter quanh thư viện `fsrs` (FSRS-6).
/// Lịch ôn tính riêng cho từng ReviewCard, không dùng lịch cứng.
class ReviewSchedulerService {
  ReviewSchedulerService({fsrs.Scheduler? scheduler})
    : _scheduler =
          scheduler ??
          fsrs.Scheduler(desiredRetention: 0.9, enableFuzzing: true);

  final fsrs.Scheduler _scheduler;

  fsrs.Rating toFsrsRating(MemoryRating rating) =>
      fsrs.Rating.fromValue(rating.value);

  /// Tính lịch tiếp theo cho [card] sau khi người dùng chấm [rating] tại [now].
  ScheduleResult schedule({
    required ReviewCard card,
    required MemoryRating rating,
    DateTime? now,
    String? answerText,
  }) {
    final DateTime reviewedAt = (now ?? DateTime.now()).toUtc();
    final fsrs.Card fsrsCard = card.toFsrsCard();
    final fsrs.Rating fsrsRating = toFsrsRating(rating);
    final ({fsrs.Card card, fsrs.ReviewLog reviewLog}) result = _scheduler
        .reviewCard(fsrsCard, fsrsRating, reviewDateTime: reviewedAt);

    final ReviewCard updated = ReviewCard.fromFsrsCard(
      card: card,
      updated: result.card,
      updatedAt: reviewedAt,
      lapsesIncrement: rating == MemoryRating.again,
    );

    final ReviewLog log = ReviewLog(
      id: 'rl_${reviewedAt.microsecondsSinceEpoch}_${card.id}',
      cardId: card.id,
      reviewedAt: reviewedAt,
      rating: rating,
      dueBefore: card.dueAt,
      dueAfter: updated.dueAt,
      stateBefore: card.fsrsState,
      stateAfter: updated.fsrsState,
      stabilityBefore: card.stability,
      stabilityAfter: updated.stability,
      answerText: answerText,
    );

    return ScheduleResult(card: updated, log: log);
  }

  /// Ước lượng % nhớ hiện tại (retrievability) — không phải đo trực tiếp não.
  double retrievability(ReviewCard card, {DateTime? now}) {
    if (card.lastReviewAt == null || card.stability == null) return 0;
    final fsrs.Card fsrsCard = card.toFsrsCard();
    if (fsrsCard.lastReview == null || fsrsCard.stability == null) return 0;
    try {
      return _scheduler.getCardRetrievability(
        fsrsCard,
        currentDateTime: (now ?? DateTime.now()).toUtc(),
      );
    } catch (_) {
      return 0;
    }
  }

  /// Lịch ôn mẫu cho thẻ mới: due ngay lúc tạo (người dùng có thể ôn ngay).
  static DateTime initialDue(DateTime now) => now.toUtc();
}
