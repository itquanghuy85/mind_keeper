import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/services/review_due_reminder.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

Future<AppServices> _build(FakeNotificationService fake) async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return AppServices.build(
    database: await openMemoryDb(),
    prefs: await SharedPreferences.getInstance(),
    notifications: fake,
  );
}

void main() {
  late FakeNotificationService fake;
  late AppServices services;
  late KnowledgeItem item;
  // Cố định "bây giờ" để không phụ thuộc giờ chạy test.
  final DateTime now = DateTime.now();

  setUp(() async {
    fake = FakeNotificationService();
    services = await _build(fake);
    final Topic topic = await services.topics.create(name: 'Chủ đề nhắc');
    item = await services.knowledge.create(
      topicId: topic.id,
      title: 'Kiến thức',
      content: 'Nội dung',
    );
  });

  tearDown(() => services.dispose());

  Future<ReviewCard> card(DateTime dueAt) => services.cards.create(
    knowledgeItemId: item.id,
    question: 'Hỏi?',
    answer: 'Đáp',
    dueAt: dueAt,
  );

  test('không có mục đến hạn → không lập thông báo', () async {
    await ReviewDueReminder.sync(services, now: now);
    expect(fake.scheduledReviewDue, isEmpty);
    expect(fake.calls, contains('cancelReviewDue'));
  });

  test('1 mục đến hạn → payload card:<id>, nhiều mục → review_due + số lượng',
      () async {
    final ReviewCard first = await card(now.subtract(const Duration(days: 1)));
    await ReviewDueReminder.sync(services, now: now);
    expect(fake.scheduledReviewDue, isNotEmpty);
    expect(
      fake.reviewDuePayloads.values.every((String p) => p == 'card:${first.id}'),
      isTrue,
    );
    expect(fake.reviewDueBodies.values.first, contains('1 kiến thức'));

    await card(now.subtract(const Duration(days: 1)));
    await ReviewDueReminder.sync(services, now: now);
    expect(
      fake.reviewDuePayloads.values.every((String p) => p == 'review_due'),
      isTrue,
    );
    expect(fake.reviewDueBodies.values.first, contains('2 kiến thức'));
  });

  test('chỉ lập ở các giờ nhắc còn trong tương lai, tối đa $reviewDueSlots ngày',
      () async {
    await card(now.subtract(const Duration(days: 1)));
    await ReviewDueReminder.sync(services, now: now);
    expect(fake.scheduledReviewDue.length, lessThanOrEqualTo(reviewDueSlots));
    for (final DateTime at in fake.scheduledReviewDue.values) {
      expect(at.isAfter(now.toUtc()), isTrue);
    }
  });
}
