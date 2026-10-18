import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/errors/app_exception.dart';
import 'package:mind_keeper/core/utils/id_generator.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/lesson.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/data/models/review_log.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:mind_keeper/data/repositories/knowledge_repository.dart';
import 'package:mind_keeper/data/repositories/lesson_repository.dart';
import 'package:mind_keeper/data/repositories/review_repository.dart';
import 'package:mind_keeper/data/repositories/topic_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase app;
  late TopicRepository topics;
  late KnowledgeRepository knowledge;
  late SourceRepository sources;
  late ReviewRepository cards;
  late ReviewLogRepository logs;
  late LessonRepository lessons;

  setUp(() async {
    app = await openMemoryDb();
    topics = TopicRepository(app);
    knowledge = KnowledgeRepository(app);
    sources = SourceRepository(app);
    cards = ReviewRepository(app);
    logs = ReviewLogRepository(app);
    lessons = LessonRepository(app);
  });

  tearDown(() async {
    await app.close();
  });

  group('TopicRepository', () {
    test('tạo, đọc, sửa, danh sách chủ đề', () async {
      final Topic created = await topics.create(
        name: '  Kỹ   thuật iPhone ',
        description: 'Mẹo vặt',
        category: 'Công nghệ',
        icon: '📱',
      );
      expect(created.name, 'Kỹ thuật iPhone');

      final Topic? fetched = await topics.getById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.description, 'Mẹo vặt');

      final Topic updated = await topics.update(
        fetched.copyWith(name: 'Kỹ thuật iPhone Pro'),
      );
      expect(updated.name, 'Kỹ thuật iPhone Pro');
      expect(
        updated.updatedAt.isAfter(created.updatedAt) ||
            !updated.updatedAt.isBefore(created.updatedAt),
        isTrue,
      );

      final List<Topic> all = await topics.list();
      expect(all.length, 1);
      expect(all.first.id, created.id);
    });

    test('từ chối tên trống và tên trùng', () async {
      await topics.create(name: 'Khoa hoc');
      await expectLater(
        topics.create(name: '   '),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        topics.create(name: 'khoa   hoc'),
        throwsA(isA<ValidationException>()),
      );
      final List<Topic> all = await topics.list();
      expect(all.length, 1);
    });

    test('tìm kiếm theo tên, mô tả, danh mục', () async {
      await topics.create(name: 'Lịch sử Việt Nam', category: 'Lịch sử');
      await topics.create(name: 'Kinh tế vĩ mô', category: 'Kinh doanh');
      expect((await topics.list(query: 'việt')).length, 1);
      expect((await topics.list(query: 'kinh doanh')).length, 1);
      expect((await topics.list(query: '')).length, 2);
    });

    test('xóa chủ đề không để lại bản ghi mồ côi', () async {
      final Topic topic = await topics.create(name: 'Sức khỏe');
      final KnowledgeItem item = await knowledge.create(
        topicId: topic.id,
        title: 'Uống nước',
        content: 'Nên uống đủ nước mỗi ngày.',
      );
      final ReviewCard card = await cards.create(
        knowledgeItemId: item.id,
        question: 'Bao nhiêu nước?',
        answer: '2 lít',
        dueAt: DateTime.now(),
      );
      await logs.insert(
        ReviewLog(
          id: 'log1',
          cardId: card.id,
          reviewedAt: DateTime.now(),
          rating: MemoryRating.good,
        ),
      );

      await topics.delete(topic.id);

      expect(await topics.getById(topic.id), isNull);
      expect(await knowledge.getById(item.id), isNull);
      expect(await cards.getById(card.id), isNull);
      expect(await logs.listByCard(card.id), isEmpty);
      expect(await knowledge.countAll(), 0);
      expect(await cards.countAll(activeOnly: false), 0);
    });

    test('đếm kiến thức và thẻ đến hạn theo chủ đề', () async {
      final Topic topic = await topics.create(name: 'Địa lý');
      final KnowledgeItem item = await knowledge.create(
        topicId: topic.id,
        title: 'Sông dài nhất',
        content: 'Sông Nile dài nhất thế giới.',
      );
      await cards.create(
        knowledgeItemId: item.id,
        question: 'Sông nào dài nhất?',
        answer: 'Sông Nile',
        dueAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );
      final TopicStats stats = await topics.statsOf(topic.id);
      expect(stats.knowledgeCount, 1);
      expect(stats.dueCount, 1);
    });
  });

  group('KnowledgeRepository', () {
    late Topic topic;

    setUp(() async {
      topic = await topics.create(name: 'Tâm lý học');
    });

    test('tạo và đọc kiến thức', () async {
      final KnowledgeItem item = await knowledge.create(
        topicId: topic.id,
        title: 'Đường cong lãng quên',
        content: 'Trí nhớ giảm nhanh trong những ngày đầu.',
        details: 'Ebbinghaus 1885',
      );
      expect((await knowledge.getById(item.id))?.details, 'Ebbinghaus 1885');
      expect(await knowledge.listByTopic(topic.id), hasLength(1));
    });

    test('từ chối tiêu đề hoặc nội dung trống', () async {
      await expectLater(
        knowledge.create(topicId: topic.id, title: ' ', content: 'x'),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        knowledge.create(topicId: topic.id, title: 'x', content: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('từ chối kiến thức trùng trong cùng chủ đề', () async {
      await knowledge.create(
        topicId: topic.id,
        title: 'A',
        content: 'Nội dung   giống nhau.',
      );
      await expectLater(
        knowledge.create(
          topicId: topic.id,
          title: 'B',
          content: 'nội dung giống nhau.',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('từ chối kiến thức thuộc chủ đề không tồn tại', () async {
      await expectLater(
        knowledge.create(topicId: 'nope', title: 'A', content: 'B'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('sửa kiến thức không phá vỡ thẻ và lịch ôn', () async {
      final KnowledgeItem item = await knowledge.create(
        topicId: topic.id,
        title: 'A',
        content: 'B',
      );
      final ReviewCard card = await cards.create(
        knowledgeItemId: item.id,
        question: 'Q',
        answer: 'A',
        dueAt: DateTime.now(),
      );
      await logs.insert(
        ReviewLog(
          id: 'log_keep',
          cardId: card.id,
          reviewedAt: DateTime.now(),
          rating: MemoryRating.easy,
        ),
      );

      final KnowledgeItem updated = await knowledge.update(
        item.copyWith(title: 'A mới', content: 'B mới'),
      );
      expect(updated.title, 'A mới');

      final ReviewCard? stillThere = await cards.getById(card.id);
      expect(stillThere, isNotNull);
      expect(await logs.listByCard(card.id), hasLength(1));
      expect(await cards.listByKnowledgeItem(item.id), hasLength(1));
    });

    test('xóa kiến thức xóa kèm thẻ và lịch sử', () async {
      final KnowledgeItem item = await knowledge.create(
        topicId: topic.id,
        title: 'A',
        content: 'B',
      );
      final ReviewCard card = await cards.create(
        knowledgeItemId: item.id,
        question: 'Q',
        answer: 'A',
        dueAt: DateTime.now(),
      );
      await logs.insert(
        ReviewLog(
          id: 'log_del',
          cardId: card.id,
          reviewedAt: DateTime.now(),
          rating: MemoryRating.again,
        ),
      );
      await knowledge.delete(item.id);
      expect(await cards.getById(card.id), isNull);
      expect(await logs.listByCard(card.id), isEmpty);
    });

    test('tìm kiếm toàn bộ kho kiến thức', () async {
      await knowledge.create(
        title: 'A',
        topicId: topic.id,
        content: 'Cấu trúc ADN',
      );
      await knowledge.create(
        title: 'B',
        topicId: topic.id,
        content: 'Chọn lọc tự nhiên',
      );
      expect(await knowledge.search('adn'), hasLength(1));
      expect(await knowledge.search('   '), isEmpty);
      expect(await knowledge.search('tự nhiên'), hasLength(1));
    });

    test('đánh dấu yêu thích và tạm ngừng ôn', () async {
      final KnowledgeItem item = await knowledge.create(
        topicId: topic.id,
        title: 'A',
        content: 'B',
      );
      await knowledge.toggleFavorite(item.id, value: true);
      await knowledge.setPaused(item.id, paused: true);
      final KnowledgeItem? reloaded = await knowledge.getById(item.id);
      expect(reloaded!.isFavorite, isTrue);
      expect(reloaded.isPaused, isTrue);
      expect(
        await knowledge.listByTopic(topic.id, includePaused: false),
        isEmpty,
      );
    });

    test('dữ liệu dài không làm hỏng truy vấn', () async {
      final String longContent = 'Nội dung dài. ' * 500;
      final KnowledgeItem item = await knowledge.create(
        topicId: topic.id,
        title: 'Dài',
        content: longContent,
      );
      expect(
        (await knowledge.getById(item.id))!.content.length,
        greaterThan(6000),
      );
      expect(await knowledge.search('Nội dung dài'), hasLength(1));
    });
  });

  group('SourceRepository', () {
    test(
      'tạo, cập nhật trạng thái, xóa giữ nguyên liên kết kiến thức',
      () async {
        final Topic topic = await topics.create(name: 'Công nghệ');
        final source = await sources.create(
          topicId: topic.id,
          type: SourceType.text,
          title: 'Ghi chú',
          contentText: 'Bản gốc',
        );
        await sources.updateStatus(
          source.id,
          status: SourceStatus.failed,
          errorMessage: 'Không đọc được',
        );
        final reloaded = await sources.getById(source.id);
        expect(reloaded!.status, SourceStatus.failed);
        expect(reloaded.errorMessage, 'Không đọc được');

        final item = await knowledge.create(
          topicId: topic.id,
          title: 'K',
          content: 'N',
          sourceId: source.id,
        );
        await sources.delete(source.id);
        expect(await sources.getById(source.id), isNull);
        expect((await knowledge.getById(item.id))!.sourceId, isNull);
      },
    );
  });

  group('ReviewRepository', () {
    late Topic topic;
    late KnowledgeItem item;

    setUp(() async {
      topic = await topics.create(name: 'Khoa học');
      item = await knowledge.create(
        topicId: topic.id,
        title: 'Vì sao chúng ta hay quên?',
        content: 'Đường cong quên lõm mô tả trí nhớ giảm theo thời gian.',
      );
    });

    test('tạo thẻ và đếm thẻ đến hạn', () async {
      final DateTime now = DateTime.now().toUtc();
      await cards.create(
        knowledgeItemId: item.id,
        question: 'Đường cong quên mô tả điều gì?',
        answer: 'Trí nhớ giảm theo thời gian nếu không ôn lại.',
        dueAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(await cards.countDue(now: now), 1);
      expect(
        await cards.countDue(now: now.subtract(const Duration(days: 30))),
        0,
      );
      // Quá hạn chỉ tính thẻ đã ôn (reps > 0) và trễ hơn đầu hôm nay.
      expect(
        await cards.countOverdue(
          startOfTodayUtc: DateTime.now().toUtc().subtract(
            const Duration(days: 1),
          ),
        ),
        0,
        reason: 'thẻ mới chưa ôn không tính quá hạn',
      );
    });

    test(
      'từ chối câu hỏi hoặc đáp án trống và kiến thức không tồn tại',
      () async {
        await expectLater(
          cards.create(
            knowledgeItemId: item.id,
            question: ' ',
            answer: 'A',
            dueAt: DateTime.now(),
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          cards.create(
            knowledgeItemId: 'khong_ton_tai',
            question: 'Q',
            answer: 'A',
            dueAt: DateTime.now(),
          ),
          throwsA(isA<NotFoundException>()),
        );
      },
    );

    test('saveReview ghi thẻ và lịch sử trong một giao dịch', () async {
      final DateTime now = DateTime.now().toUtc();
      final ReviewCard card = await cards.create(
        knowledgeItemId: item.id,
        question: 'Q',
        answer: 'A',
        dueAt: now,
      );
      final ReviewCard updated = card.copyWith(
        dueAt: now.add(const Duration(days: 2)),
        lastReviewAt: now,
        reps: card.reps + 1,
        updatedAt: now,
      );
      final ReviewLog log = ReviewLog(
        id: 'rl_x',
        cardId: card.id,
        reviewedAt: now,
        rating: MemoryRating.good,
        dueBefore: now,
        dueAfter: updated.dueAt,
      );
      await cards.saveReview(updatedCard: updated, log: log);

      final ReviewCard? reloaded = await cards.getById(card.id);
      expect(reloaded!.reps, 1);
      expect(reloaded.lastReviewAt, isNotNull);
      expect(reloaded.dueAt.isAfter(now), isTrue);
      expect(await logs.listByCard(card.id), hasLength(1));
      expect(await cards.countDue(now: now), 0);
    });

    test('saveReview với thẻ đã bị xóa không tạo bản ghi mồ côi', () async {
      final DateTime now = DateTime.now().toUtc();
      final ReviewCard card = await cards.create(
        knowledgeItemId: item.id,
        question: 'Q',
        answer: 'A',
        dueAt: now,
      );
      await cards.delete(card.id);
      final ReviewLog log = ReviewLog(
        id: 'rl_fail',
        cardId: card.id,
        reviewedAt: now,
        rating: MemoryRating.good,
      );
      await expectLater(
        cards.saveReview(updatedCard: card, log: log),
        throwsA(isA<NotFoundException>()),
      );
      expect(await logs.listByCard(card.id), isEmpty);
    });

    test('thẻ của kiến thức tạm ngừng không được tính đến hạn', () async {
      final DateTime now = DateTime.now().toUtc();
      await cards.create(
        knowledgeItemId: item.id,
        question: 'Q',
        answer: 'A',
        dueAt: now.subtract(const Duration(hours: 1)),
      );
      expect(await cards.countDue(now: now), 1);
      await knowledge.setPaused(item.id, paused: true);
      expect(await cards.countDue(now: now), 0);
      expect(await cards.countDueByTopic(now: now), isEmpty);
    });

    test('xóa thẻ xóa lịch sử liên quan', () async {
      final DateTime now = DateTime.now().toUtc();
      final ReviewCard card = await cards.create(
        knowledgeItemId: item.id,
        question: 'Q',
        answer: 'A',
        dueAt: now,
      );
      await logs.insert(
        ReviewLog(
          id: 'l1',
          cardId: card.id,
          reviewedAt: now,
          rating: MemoryRating.again,
        ),
      );
      await cards.delete(card.id);
      expect(await logs.listByCard(card.id), isEmpty);
    });
  });

  group('LessonRepository', () {
    Lesson makeLesson({
      String domainId = 'science',
      String topic = 'Vũ trụ',
      LessonMode mode = LessonMode.standard,
      String? dedupKey,
      bool isRead = false,
      bool isFavorite = false,
      LessonVerification verification = LessonVerification.unverified,
    }) {
      final String key =
          dedupKey ??
          Lesson.buildDedupKey(
            domainId: domainId,
            topic: topic,
            mode: mode,
            promptVersion: 'v1',
          );
      final DateTime ts = DateTime.utc(2026, 10, 17);
      return Lesson(
        id: newId('ls'),
        domainId: domainId,
        domainName: 'Khoa học',
        topic: topic,
        mode: mode,
        promptVersion: 'v1',
        dedupKey: key,
        title: topic,
        content: const LessonContent(
          learningObjectives: <String>['Mục tiêu'],
          introduction: 'Mở đầu.',
          concepts: <LessonConcept>[
            LessonConcept(name: 'Khái niệm', explanation: 'Giải thích'),
          ],
          sections: <LessonSection>[
            LessonSection(heading: 'Tổng quan', body: 'Nội dung.'),
          ],
          keyPoints: <String>['Ý 1'],
          examples: <String>['Ví dụ 1'],
          commonMistakes: <String>['Sai lầm 1'],
          summary: 'Tóm tắt.',
        ),
        questions: const <LessonQuestion>[
          LessonQuestion(question: 'Câu hỏi?', answer: 'Đáp án.'),
        ],
        sources: const <LessonSource>[],
        verification: verification,
        medical: false,
        wordCount: 20,
        isFavorite: isFavorite,
        isRead: isRead,
        linkedTopicId: null,
        createdAt: ts,
        updatedAt: ts,
      );
    }

    test('tạo và đọc lại bài học', () async {
      final Lesson created = await lessons.create(makeLesson());
      final Lesson? fetched = await lessons.getById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Vũ trụ');
      expect(fetched.content.sections, hasLength(1));
      expect(await lessons.countAll(), 1);
    });

    test('dedup: tạo lại cùng dedup_key trả về bài đã có', () async {
      final Lesson first = await lessons.create(makeLesson());
      final Lesson second = await lessons.create(makeLesson());
      expect(second.id, first.id);
      expect(await lessons.countAll(), 1);
    });

    test('lọc theo domain, yêu thích và chưa đọc', () async {
      await lessons.create(makeLesson(domainId: 'science', isRead: true));
      await lessons.create(
        makeLesson(domainId: 'history', topic: 'Lịch sử', isFavorite: true),
      );
      await lessons.create(makeLesson(domainId: 'tech', topic: 'Công nghệ'));

      expect(await lessons.list(domainId: 'science'), hasLength(1));
      expect(await lessons.list(favoritesOnly: true), hasLength(1));
      expect(await lessons.list(unreadOnly: true), hasLength(2));
      expect(await lessons.list(query: 'công'), hasLength(1));
    });

    test('đổi cờ favorite/read/verification và liên kết chủ đề', () async {
      final Lesson created = await lessons.create(makeLesson());
      final Topic linked = await topics.create(name: 'Chủ đề liên kết');
      await lessons.setFavorite(created.id, favorite: true);
      await lessons.setRead(created.id, read: true);
      await lessons.setVerification(
        created.id,
        verification: LessonVerification.confirmed,
      );
      await lessons.setLinkedTopic(created.id, topicId: linked.id);

      final Lesson? reloaded = await lessons.getById(created.id);
      expect(reloaded!.isFavorite, isTrue);
      expect(reloaded.isRead, isTrue);
      expect(reloaded.verification, LessonVerification.confirmed);
      expect(reloaded.linkedTopicId, linked.id);
    });

    test('đếm theo lĩnh vực và tổng số', () async {
      await lessons.create(makeLesson(domainId: 'science', isRead: true));
      await lessons.create(
        makeLesson(domainId: 'science', topic: 'Thuyết tiến hóa'),
      );
      await lessons.create(
        makeLesson(domainId: 'history', topic: 'Lịch sử', isFavorite: true),
      );

      final Map<String, LessonDomainCount> counts = await lessons
          .countByDomain();
      expect(counts['science']!.total, 2);
      expect(counts['science']!.read, 1);
      expect(counts['history']!.favorites, 1);
      expect(await lessons.countRead(), 1);
      expect(await lessons.countAll(), 3);
    });

    test('xóa bài học', () async {
      final Lesson created = await lessons.create(makeLesson());
      await lessons.delete(created.id);
      expect(await lessons.getById(created.id), isNull);
      expect(await lessons.countAll(), 0);
    });
  });

  group('Bền vững dữ liệu', () {
    test('dữ liệu tồn tại sau khi khởi động lại ứng dụng', () async {
      final ({AppDatabase app, Directory dir}) first = await openFileDb();
      final TopicRepository topicRepo = TopicRepository(first.app);
      final KnowledgeRepository knowledgeRepo = KnowledgeRepository(first.app);
      final ReviewRepository cardRepo = ReviewRepository(first.app);

      final Topic topic = await topicRepo.create(name: 'Ngoại ngữ');
      final KnowledgeItem item = await knowledgeRepo.create(
        topicId: topic.id,
        title: 'Thì hiện tại đơn',
        content: 'Dùng để diễn tả sự thật thường xuyên.',
      );
      final ReviewCard card = await cardRepo.create(
        knowledgeItemId: item.id,
        question: 'Thì hiện tại đơn dùng để làm gì?',
        answer: 'Diễn tả sự thật thường xuyên.',
        dueAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      );
      await first.app.close();

      final AppDatabase reopened = AppDatabase(
        factory: first.app.factory,
        name: first.app.name,
        directory: first.dir.path,
      );
      await reopened.open();
      final TopicRepository topicRepo2 = TopicRepository(reopened);
      final KnowledgeRepository knowledgeRepo2 = KnowledgeRepository(reopened);
      final ReviewRepository cardRepo2 = ReviewRepository(reopened);

      expect(await topicRepo2.getById(topic.id), isNotNull);
      expect(await knowledgeRepo2.getById(item.id), isNotNull);
      final ReviewCard? reloaded = await cardRepo2.getById(card.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.question, 'Thì hiện tại đơn dùng để làm gì?');
      expect(
        reloaded.dueAt.toUtc().millisecondsSinceEpoch,
        card.dueAt.toUtc().millisecondsSinceEpoch,
      );

      await reopened.close();
      await first.dir.delete(recursive: true);
    });
  });
}
