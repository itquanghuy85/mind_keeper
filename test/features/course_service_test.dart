import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/models/course.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/features/ai/ai_provider.dart';
import 'package:mind_keeper/features/ai/mock_ai_provider.dart';
import 'package:mind_keeper/features/courses/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

Future<({AppServices services, CourseService course, FakeNotificationService fake})>
_build({bool allowMock = true}) async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final FakeNotificationService fake = FakeNotificationService();
  final AppServices services = AppServices.build(
    database: await openMemoryDb(),
    prefs: prefs,
    notifications: fake,
  );
  services.ai.useProvider(MockAIProvider(latency: Duration.zero));
  final CourseService course = CourseService(
    prefs: services.prefs,
    courses: services.courseRepo,
    topics: services.topics,
    knowledge: services.knowledge,
    cards: services.cards,
    ai: services.ai,
    notifications: fake,
    allowMockContent: allowMock,
  );
  return (services: services, course: course, fake: fake);
}

void main() {
  // Mốc cố định: 05:00 sáng, mọi khung giờ mặc định (08:00...) ở tương lai.
  final DateTime base = DateTime.now().add(const Duration(days: 1));
  final DateTime morning = DateTime(base.year, base.month, base.day, 5);

  test('draftOutline trả đúng số mẩu, không trùng', () async {
    final r = await _build();
    final List<String> titles = await r.course.draftOutline(
      topicName: 'Bếp từ',
      level: CourseLevel.advanced,
      count: 12,
    );
    expect(titles, hasLength(12));
    expect(titles.toSet(), hasLength(12));
    expect(titles.first, contains('Bếp từ'));
  });

  test('chưa cấu hình AI thật: không soạn đề cương, không sinh mẩu', () async {
    final r = await _build(allowMock: false);
    await expectLater(
      r.course.draftOutline(
        topicName: 'Bếp từ',
        level: CourseLevel.basic,
        count: 5,
      ),
      throwsA(isA<AiConfigurationException>()),
    );
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['A', 'B'],
    );
    final CourseSyncResult res = await r.course.sync(now: morning);
    expect(res.generated, 0);
    expect((await r.services.courseRepo.listItems(c.id)).every(
      (CourseItem i) => i.status == CourseItemStatus.pending,
    ), isTrue);
  });

  test('startCourse tạo chủ đề + đề cương theo thứ tự', () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Lò vi sóng',
      level: CourseLevel.pro,
      titles: <String>['Một', '  ', 'Hai', 'Ba'],
    );
    expect(c.totalItems, 3);
    expect(c.level, CourseLevel.pro);
    expect(await r.services.topics.findByName('Lò vi sóng'), isNotNull);
    final List<CourseItem> items = await r.services.courseRepo.listItems(c.id);
    expect(items.map((CourseItem i) => i.title), <String>['Một', 'Hai', 'Ba']);
    expect(items.map((CourseItem i) => i.position), <int>[0, 1, 2]);
  });

  test('sync sinh mẩu hôm nay + ngày mai, lưu nội dung, lên lịch thông báo',
      () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.advanced,
      titles: <String>['T1', 'T2', 'T3', 'T4'],
    );
    final CourseSyncResult res = await r.course.sync(now: morning);
    expect(res.generated, 2);
    expect(res.scheduled, 2);
    final List<CourseItem> items = await r.services.courseRepo.listItems(c.id);
    expect(items[0].status, CourseItemStatus.ready);
    expect(items[1].status, CourseItemStatus.ready);
    expect(items[2].status, CourseItemStatus.pending);
    expect(items[0].knowledgeItemId, isNotNull);
    expect(items[0].summary, isNotEmpty);

    final KnowledgeItem k = (await r.services.knowledge.getById(
      items[0].knowledgeItemId!,
    ))!;
    expect(k.title, 'T1');
    expect(k.details, contains(courseUnverifiedLabel));

    // Thẻ ôn đã tạo nhưng CHƯA vào lịch ôn.
    final List<ReviewCard> cards = await r.services.cards.listAllByKnowledgeItem(
      k.id,
    );
    expect(cards, hasLength(1));
    expect(cards.first.isActive, isFalse);

    // Thông báo: id âm, khác nhau, payload course:<id>, có bigText.
    expect(r.fake.scheduledCourse, hasLength(2));
    for (final MapEntry<int, String> e in r.fake.coursePayloads.entries) {
      expect(e.key, lessThan(0));
      expect(e.value, startsWith('course:'));
      expect(r.fake.courseBigTexts[e.key], isNotEmpty);
    }
    // Nội dung mới: title = tên mẩu, body ≤180, bigText = tóm tắt + mẹo nhớ,
    // subText = khóa · cấp độ.
    for (final CourseItem it in items.take(2)) {
      final int id = CourseService.notificationIdFor(it.id);
      expect(r.fake.courseTitles[id], it.title);
      expect(r.fake.courseBodies[id]!.length, lessThanOrEqualTo(180));
      expect(it.memoryTip, isNotEmpty);
      expect(
        r.fake.courseBigTexts[id],
        contains('Mẹo nhớ: ${it.memoryTip}'),
      );
      expect(r.fake.courseSubTexts[id], contains(' · '));
    }
    expect(
      r.fake.coursePayloads.values.toSet(),
      <String>{'course:${items[0].id}', 'course:${items[1].id}'},
    );

    // Idempotent: chạy lại không sinh thêm, không nhân bản lịch.
    final CourseSyncResult again = await r.course.sync(now: morning);
    expect(again.generated, 0);
    expect(r.fake.scheduledCourse, hasLength(2));
  });

  test('perDay = 2: mỗi ngày phát hành 2 mẩu', () async {
    final r = await _build();
    final Course c = await r.services.courseRepo.createWithOutline(
      topicId: (await r.services.topics.create(name: 'Sinh học')).id,
      name: 'Sinh học',
      level: CourseLevel.basic,
      titles: <String>['a', 'b', 'c', 'd', 'e'],
      perDay: 2,
    );
    final CourseSyncResult res = await r.course.sync(now: morning);
    expect(res.generated, 4);
    final List<CourseItem> items = await r.services.courseRepo.listItems(c.id);
    expect(
      items.where((CourseItem i) => i.status == CourseItemStatus.ready),
      hasLength(4),
    );
  });

  test('markRead: ghi nhận, hủy thông báo, kích hoạt thẻ ôn, idempotent',
      () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['T1', 'T2'],
    );
    await r.course.sync(now: morning);
    final CourseItem first =
        (await r.services.courseRepo.listItems(c.id)).first;

    final CourseItem? done = await r.course.markRead(first.id, now: morning);
    expect(done!.status, CourseItemStatus.read);
    expect(r.fake.cancelledCourse, contains(
      CourseService.notificationIdFor(first.id),
    ));
    expect(r.fake.scheduledCourse.containsKey(
      CourseService.notificationIdFor(first.id),
    ), isFalse);

    final List<ReviewCard> cards = await r.services.cards.listAllByKnowledgeItem(
      first.knowledgeItemId!,
    );
    expect(cards.single.isActive, isTrue);
    expect(
      cards.single.dueAt.toUtc(),
      morning.toUtc().add(const Duration(days: 1)),
    );
    final KnowledgeItem k = (await r.services.knowledge.getById(
      first.knowledgeItemId!,
    ))!;
    expect(k.startedAt, isNotNull);

    await r.course.markRead(first.id, now: morning);
    expect(
      (await r.services.cards.listAllByKnowledgeItem(first.knowledgeItemId!))
          .single
          .isActive,
      isTrue,
    );
  });

  test('reconcile kích hoạt thẻ cho mẩu đã đọc từ nút Đã hiểu ở nền', () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['T1'],
    );
    await r.course.sync(now: morning);
    final CourseItem item = (await r.services.courseRepo.listItems(c.id)).first;
    // Giả lập isolate nền: chỉ đổi status, không đụng thẻ.
    await r.services.courseRepo.updateItem(
      item.copyWith(status: CourseItemStatus.read, readAt: morning.toUtc()),
    );
    expect(
      (await r.services.cards.listAllByKnowledgeItem(item.knowledgeItemId!))
          .single
          .isActive,
      isFalse,
    );
    expect(await r.course.reconcile(now: morning), 1);
    expect(
      (await r.services.cards.listAllByKnowledgeItem(item.knowledgeItemId!))
          .single
          .isActive,
      isTrue,
    );
    expect(await r.course.reconcile(now: morning), 0);
  });

  test('đổi cấp độ giữa chừng: giữ đề cương, mẩu sau theo cấp độ mới',
      () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['T1', 'T2', 'T3', 'T4'],
    );
    await r.course.sync(now: morning); // T1, T2 theo cơ bản
    await r.course.changeLevel(c.id, CourseLevel.master);
    final DateTime later = morning.add(const Duration(days: 2));
    await r.course.sync(now: later);
    final List<CourseItem> items = await r.services.courseRepo.listItems(c.id);
    expect(items.map((CourseItem i) => i.title), <String>['T1', 'T2', 'T3', 'T4']);
    final KnowledgeItem t1 = (await r.services.knowledge.getById(
      items[0].knowledgeItemId!,
    ))!;
    final KnowledgeItem t4 = (await r.services.knowledge.getById(
      items[3].knowledgeItemId!,
    ))!;
    expect(t1.content, contains('Cơ bản'));
    expect(t4.content, contains('Master'));
  });

  test('tạm dừng kế hoạch hủy lịch nhưng giữ nội dung; hết mẩu thì hoàn thành',
      () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['T1'],
    );
    await r.course.sync(now: morning);
    expect(r.fake.scheduledCourse, hasLength(1));

    await r.services.prefs.setStudyPlanPaused(true);
    await r.course.sync(now: morning);
    expect(r.fake.scheduledCourse, isEmpty);
    final CourseItem item = (await r.services.courseRepo.listItems(c.id)).first;
    expect(item.status, CourseItemStatus.ready);
    expect(item.knowledgeItemId, isNotNull);

    await r.services.prefs.setStudyPlanPaused(false);
    await r.course.markRead(item.id, now: morning);
    await r.course.sync(now: morning);
    expect(
      (await r.services.courseRepo.getById(c.id))!.status,
      CourseStatus.done,
    );
  });

  test('unread + progress phản ánh trạng thái thật', () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['T1', 'T2', 'T3'],
    );
    await r.course.sync(now: morning);
    // Trước giờ phát hành: chưa có mẩu "chưa đọc".
    expect(await r.course.unread(now: morning), isEmpty);
    // Sau giờ phát hành hôm đó: T1 chưa đọc.
    final DateTime noon = DateTime(base.year, base.month, base.day, 23);
    final List<CourseItemEntry> unread = await r.course.unread(now: noon);
    expect(unread.map((CourseItemEntry e) => e.item.title), <String>['T1']);

    CourseProgress p = (await r.course.progress()).single;
    expect(p.readCount, 0);
    expect(p.total, 3);
    expect(p.nextTitle, 'T1');

    await r.course.markRead(unread.single.item.id, now: noon);
    p = (await r.course.progress()).single;
    expect(p.readCount, 1);
    expect(p.fraction, closeTo(1 / 3, 0.001));
    expect(p.nextTitle, 'T2');
    expect(c.id, p.course.id);
  });

  test('generateNext đọc trước mẩu kế tiếp ngay', () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['T1', 'T2'],
    );
    final CourseItem? next = await r.course.generateNext(c.id, now: morning);
    expect(next!.title, 'T1');
    expect(next.status, CourseItemStatus.ready);
    final CourseItem? second = await r.course.generateNext(c.id, now: morning);
    expect(second!.title, 'T2');
    expect(await r.course.generateNext(c.id, now: morning), isNull);
  });

  test('xóa khóa học hủy thông báo và xóa đề cương', () async {
    final r = await _build();
    final Course c = await r.course.startCourse(
      topicName: 'Bếp từ',
      level: CourseLevel.basic,
      titles: <String>['T1', 'T2'],
    );
    await r.course.sync(now: morning);
    expect(r.fake.scheduledCourse, isNotEmpty);
    await r.course.deleteCourse(c.id);
    expect(r.fake.scheduledCourse, isEmpty);
    expect(await r.services.courseRepo.getById(c.id), isNull);
    expect(await r.services.courseRepo.listItems(c.id), isEmpty);
  });
}
