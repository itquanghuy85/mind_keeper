import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mind_keeper/core/services/review_scheduler_service.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/review_card.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 4, 25, 12);

  ReviewCard newCard({String id = 'rc_1'}) {
    return ReviewCard(
      id: id,
      knowledgeItemId: 'ki_1',
      question: 'Câu hỏi?',
      answer: 'Đáp án',
      dueAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('thẻ mới + đánh giá Tốt: due được đẩy ra sau và stability tăng', () {
    final ReviewSchedulerService scheduler = ReviewSchedulerService(
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );
    final ReviewCard card = newCard();
    final ScheduleResult result = scheduler.schedule(
      card: card,
      rating: MemoryRating.good,
      now: now,
    );
    expect(result.card.dueAt.isAfter(now), isTrue);
    expect(result.card.reps, 1);
    expect(result.card.lastReviewAt, isNotNull);
    expect(result.card.stability, isNotNull);
    expect(result.log.rating, MemoryRating.good);
    expect(result.log.dueBefore, card.dueAt);
    expect(result.log.dueAfter, result.card.dueAt);
    expect(result.log.stateBefore, 0);
    expect(result.log.stateAfter, greaterThanOrEqualTo(0));
  });

  test('mỗi mức đánh giá cho due khác nhau và hợp lệ', () {
    final ReviewSchedulerService scheduler = ReviewSchedulerService(
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );
    final Map<MemoryRating, Duration> gaps = <MemoryRating, Duration>{};
    for (final MemoryRating rating in MemoryRating.values) {
      final ScheduleResult r = scheduler.schedule(
        card: newCard(id: 'rc_${rating.name}'),
        rating: rating,
        now: now,
      );
      expect(r.card.dueAt.isAfter(now.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(r.card.dueAt.isUtc, isFalse, reason: 'due lưu local');
      gaps[rating] = r.card.dueAt.difference(now);
    }
    // Quên nhanh nhất; Dễ >= Tốt >= Khó.
    expect(gaps[MemoryRating.again]! < gaps[MemoryRating.easy]!, isTrue);
    expect(gaps[MemoryRating.hard]! <= gaps[MemoryRating.good]!, isTrue);
  });

  test('Quên tăng lapses', () {
    final ReviewSchedulerService scheduler = ReviewSchedulerService(
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );
    final ReviewCard card = newCard();
    final ScheduleResult first = scheduler.schedule(
      card: card,
      rating: MemoryRating.good,
      now: now,
    );
    final ScheduleResult second = scheduler.schedule(
      card: first.card,
      rating: MemoryRating.again,
      now: now.add(const Duration(days: 3)),
    );
    expect(second.card.lapses, 1);
  });

  test('ôn trễ: lịch vẫn hợp lệ sau khi trễ nhiều ngày', () {
    final ReviewSchedulerService scheduler = ReviewSchedulerService(
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );
    ReviewCard card = newCard();
    card = scheduler.schedule(
      card: card,
      rating: MemoryRating.easy,
      now: now,
    ).card;
    final DateTime muchLater = now.add(const Duration(days: 40));
    final ScheduleResult late = scheduler.schedule(
      card: card,
      rating: MemoryRating.hard,
      now: muchLater,
    );
    expect(late.card.dueAt.isAfter(muchLater), isTrue);
    expect(late.card.reps, 2);
  });

  test('danh sách thẻ mới có due ngay (initialDue)', () {
    final DateTime due = ReviewSchedulerService.initialDue(now);
    expect(due.isUtc, isTrue);
    expect(due, now);
  });

  test('retrievability = 0 với thẻ mới, >0 sau khi ôn', () {
    final ReviewSchedulerService scheduler = ReviewSchedulerService(
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );
    final ReviewCard card = newCard();
    expect(scheduler.retrievability(card, now: now), 0);
    final ReviewCard reviewed = scheduler.schedule(
      card: card,
      rating: MemoryRating.good,
      now: now,
    ).card;
    final double r = scheduler.retrievability(
      reviewed,
      now: now.add(const Duration(days: 1)),
    );
    expect(r, greaterThan(0));
    expect(r, lessThanOrEqualTo(1));
  });
}
