import 'package:flutter_test/flutter_test.dart';

import 'package:mind_keeper/core/services/notification_service.dart';

void main() {
  group('NotificationPayload parsing', () {
    test('JSON payload type=article,id=abc → knowledge detail route', () {
      final p = NotificationPayload.parse('{"type":"article","id":"abc123"}');
      expect(p.type, NotificationPayload.kindArticle);
      expect(p.id, 'abc123');
      expect(p.isKnowledge, isTrue);
      expect(p.isReview, isFalse);
    });

    test('JSON payload type=quick_info,id=xyz → knowledge detail route', () {
      final p = NotificationPayload.parse('{"type":"quick_info","id":"xyz789"}');
      expect(p.type, NotificationPayload.kindQuickInfo);
      expect(p.id, 'xyz789');
      expect(p.isKnowledge, isTrue);
    });

    test('JSON payload type=review_due → review session route', () {
      final p = NotificationPayload.parse('{"type":"review_due"}');
      expect(p.type, NotificationPayload.kindReviewDue);
      expect(p.id, isNull);
      expect(p.isReview, isTrue);
    });

    test('JSON payload type=review → review session route', () {
      final p = NotificationPayload.parse('{"type":"review"}');
      expect(p.type, NotificationPayload.kindReview);
      expect(p.isReview, isTrue);
    });

    test('JSON payload type=card,id=card1 → card review route', () {
      final p = NotificationPayload.parse('{"type":"card","id":"card1"}');
      expect(p.type, NotificationPayload.kindCard);
      expect(p.cardId, 'card1');
      expect(p.isCard, isTrue);
    });

    test('Legacy payload card:<id> → card review route', () {
      final p = NotificationPayload.parse('card:card_1');
      expect(p.type, NotificationPayload.kindCard);
      expect(p.cardId, 'card_1');
      expect(p.id, 'card_1');
    });

    test('Legacy payload lesson:<id> → lesson route', () {
      final p = NotificationPayload.parse('lesson:lesson_1');
      expect(p.type, NotificationPayload.kindLesson);
      expect(p.lessonId, 'lesson_1');
      expect(p.id, 'lesson_1');
    });

    test('Legacy payload quick:<id> → knowledge detail route', () {
      final p = NotificationPayload.parse('quick:ki_1');
      expect(p.type, NotificationPayload.kindQuick);
      expect(p.knowledgeItemId, 'ki_1');
      expect(p.id, 'ki_1');
    });

    test('Empty/null payload → default review route', () {
      final p1 = NotificationPayload.parse(null);
      expect(p1.type, NotificationPayload.kindReview);
      expect(p1.isReview, isTrue);

      final p2 = NotificationPayload.parse('');
      expect(p2.type, NotificationPayload.kindReview);
      expect(p2.isReview, isTrue);
    });

    test('Invalid JSON falls back to legacy parsing', () {
      final p = NotificationPayload.parse('not-json-at-all');
      expect(p.type, NotificationPayload.kindReview);
    });

    test('fromJson creates correct payload for article', () {
      final p = NotificationPayload.fromJson({'type': 'article', 'id': 'ki_42'});
      expect(p.type, NotificationPayload.kindArticle);
      expect(p.id, 'ki_42');
      expect(p.knowledgeItemId, 'ki_42');
    });

    test('fromJson creates correct payload for review_due without id', () {
      final p = NotificationPayload.fromJson({'type': 'review_due'});
      expect(p.type, NotificationPayload.kindReviewDue);
      expect(p.id, isNull);
      expect(p.isReview, isTrue);
    });
  });
}
