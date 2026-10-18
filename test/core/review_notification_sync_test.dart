import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/models/due_review_item.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:mind_keeper/features/review/review_controller.dart';

import '../helpers/test_db.dart';

Future<AppServices> buildServices(FakeNotificationService fake) async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return AppServices.build(
    database: await openMemoryDb(),
    prefs: prefs,
    notifications: fake,
  );
}

/// Seed topic → knowledge → card vào DB thật.
/// `saveReview` là UPDATE nên thẻ PHẢI tồn tại trước khi rate().
Future<DueReviewItem> seedCard(
  AppServices services, {
  required DateTime dueAt,
  String question = 'Câu hỏi kiểm tra?',
}) async {
  final Topic topic = await services.topics.create(name: 'Chủ đề GĐ16');
  final KnowledgeItem knowledge = await services.knowledge.create(
    topicId: topic.id,
    title: 'Tiêu đề GĐ16',
    content: 'Nội dung GĐ16',
  );
  final ReviewCard card = await services.cards.create(
    knowledgeItemId: knowledge.id,
    question: question,
    answer: 'Đáp án',
    dueAt: dueAt,
  );
  return DueReviewItem(card: card, knowledge: knowledge, topic: topic);
}

/// Đưa controller về trạng thái rate() chạy được (current trỏ item, lộ đáp án).
void prepare(ReviewController controller, DueReviewItem item) {
  controller.queue = <DueReviewItem>[item];
  controller.index = 0;
  controller.current = item;
  controller.phase = ReviewPhase.question;
  controller.revealAnswer();
}

/// Lịch phải khớp dueAt đã lưu (DB lưu ms → cho lệch làm tròn <1ms).
void expectScheduledAt(
  FakeNotificationService fake,
  String cardId,
  ReviewCard saved,
) {
  final DateTime? at = fake.scheduledCards[cardId];
  expect(at, isNotNull, reason: 'phải có lịch cho thẻ $cardId');
  expect(
    at!.difference(saved.dueAt).inMilliseconds.abs(),
    lessThanOrEqualTo(1),
    reason: 'lịch phải khớp dueAt đã lưu',
  );
}

class _FailingNotificationService extends FakeNotificationService {
  @override
  Future<void> scheduleCardDueAt({
    required String cardId,
    required String title,
    required String body,
    required DateTime at,
  }) {
    throw Exception('thông báo lỗi giả lập');
  }
}

void main() {
  final DateTime now = DateTime.now();

  group('GĐ16 — đồng bộ thông báo sau khi chấm điểm', () {
    test('chấm Tốt: hủy lịch cũ và lên lịch mới bằng dueAt mới', () async {
      final FakeNotificationService fake = FakeNotificationService()
        ..notificationsEnabledStatus = true;
      final AppServices services = await buildServices(fake);
      try {
        final DueReviewItem item = await seedCard(
          services,
          dueAt: now.subtract(const Duration(days: 1)),
        );
        final String cardId = item.card.id;
        // Lịch cũ đã có cho thẻ này (mô phỏng trước GĐ16).
        await services.notifications.scheduleCardDueAt(
          cardId: cardId,
          title: 'Cũ',
          body: 'Cũ',
          at: now.add(const Duration(days: 2)),
        );
        expect(fake.scheduledCards.containsKey(cardId), isTrue);

        final ReviewController controller = ReviewController(
          services: services,
        );
        prepare(controller, item);
        await controller.rate(MemoryRating.good);

        expect(controller.error, isNull);
        final ReviewCard saved = (await services.cards.getById(cardId))!;
        expect(saved.reps, 1);
        expect(saved.dueAt.isAfter(now), isTrue);
        expect(fake.cancelledCards, contains(cardId));
        expectScheduledAt(fake, cardId, saved);
        expect(fake.scheduledCards[cardId]!.isAfter(now), isTrue);
      } finally {
        await services.dispose();
      }
    });

    test('cả 4 mức đánh giá đều hủy + lên lịch lại theo dueAt mới', () async {
      for (final MemoryRating rating in MemoryRating.values) {
        final FakeNotificationService fake = FakeNotificationService()
          ..notificationsEnabledStatus = true;
        final AppServices services = await buildServices(fake);
        try {
          final DueReviewItem item = await seedCard(services, dueAt: now);
          final String cardId = item.card.id;
          final ReviewController controller = ReviewController(
            services: services,
          );
          prepare(controller, item);
          await controller.rate(rating);

          expect(controller.error, isNull, reason: 'rating=${rating.name}');
          final ReviewCard saved = (await services.cards.getById(cardId))!;
          expect(saved.reps, 1, reason: 'rating=${rating.name}');
          expect(
            fake.cancelledCards,
            contains(cardId),
            reason: 'rating=${rating.name}',
          );
          expectScheduledAt(fake, cardId, saved);
          expect(
            fake.scheduledCards[cardId]!.isAfter(now),
            isTrue,
            reason: 'rating=${rating.name}',
          );
        } finally {
          await services.dispose();
        }
      }
    });
    test(
      'chấm lại cùng thẻ: nhiều lần cancel nhưng chỉ 1 lịch (không trùng)',
      () async {
        final FakeNotificationService fake = FakeNotificationService()
          ..notificationsEnabledStatus = true;
        final AppServices services = await buildServices(fake);
        try {
          final DueReviewItem item = await seedCard(services, dueAt: now);
          final String cardId = item.card.id;
          final ReviewController controller = ReviewController(
            services: services,
          );
          prepare(controller, item);
          await controller.rate(MemoryRating.good);

          // Chấm lần 2 với trạng thái card đã lưu (mô phỏng phiên sau).
          final ReviewCard saved1 = (await services.cards.getById(cardId))!;
          prepare(
            controller,
            DueReviewItem(
              card: saved1,
              knowledge: item.knowledge,
              topic: item.topic,
            ),
          );
          await controller.rate(MemoryRating.hard);

          final ReviewCard saved2 = (await services.cards.getById(cardId))!;
          expect(controller.error, isNull);
          expect(saved2.reps, 2);
          expect(
            fake.cancelledCards.where((String id) => id == cardId),
            hasLength(2),
            reason: 'mỗi lần chấm đều hủy lịch cũ trước',
          );
          expect(
            fake.scheduledCards.keys.where((String id) => id == cardId),
            hasLength(1),
            reason: 'Map theo cardId → không tạo lịch trùng',
          );
          expectScheduledAt(fake, cardId, saved2);
        } finally {
          await services.dispose();
        }
      },
    );

    test('thông báo bị tắt: chỉ hủy lịch, không lên lịch mới', () async {
      final FakeNotificationService fake = FakeNotificationService()
        ..notificationsEnabledStatus = false;
      final AppServices services = await buildServices(fake);
      try {
        final DueReviewItem item = await seedCard(
          services,
          dueAt: now.subtract(const Duration(days: 1)),
        );
        final String cardId = item.card.id;
        final ReviewController controller = ReviewController(
          services: services,
        );
        prepare(controller, item);
        await controller.rate(MemoryRating.good);

        final ReviewCard saved = (await services.cards.getById(cardId))!;
        expect(saved.reps, 1, reason: 'dữ liệu ôn tập vẫn lưu');
        expect(fake.cancelledCards, contains(cardId));
        expect(fake.scheduledCards, isEmpty);
      } finally {
        await services.dispose();
      }
    });

    test('trạng thái không đọc được (null): không can thiệp lịch', () async {
      final FakeNotificationService fake = FakeNotificationService()
        ..notificationsEnabledStatus = null;
      final AppServices services = await buildServices(fake);
      try {
        final DueReviewItem item = await seedCard(
          services,
          dueAt: now.subtract(const Duration(days: 1)),
        );
        final String cardId = item.card.id;
        final ReviewController controller = ReviewController(
          services: services,
        );
        prepare(controller, item);
        await controller.rate(MemoryRating.good);

        final ReviewCard saved = (await services.cards.getById(cardId))!;
        expect(saved.reps, 1);
        expect(fake.cancelledCards, isEmpty);
        expect(fake.scheduledCards, isEmpty);
      } finally {
        await services.dispose();
      }
    });

    test('lỗi thông báo không làm mất dữ liệu ôn tập đã lưu', () async {
      final _FailingNotificationService fake = _FailingNotificationService()
        ..notificationsEnabledStatus = true;
      final AppServices services = await buildServices(fake);
      try {
        final DueReviewItem item = await seedCard(
          services,
          dueAt: now.subtract(const Duration(days: 1)),
        );
        final String cardId = item.card.id;
        final ReviewController controller = ReviewController(
          services: services,
        );
        prepare(controller, item);
        // Không ném lỗi → rate() thành công dù thông báo lỗi.
        await controller.rate(MemoryRating.good);

        expect(controller.error, isNull);
        final ReviewCard saved = (await services.cards.getById(cardId))!;
        expect(saved.reps, 1, reason: 'review lưu trước khi đồng bộ thông báo');
        expect(saved.dueAt.isAfter(now), isTrue);
        expect(fake.cancelledCards, contains(cardId));
      } finally {
        await services.dispose();
      }
    });
  });
}
