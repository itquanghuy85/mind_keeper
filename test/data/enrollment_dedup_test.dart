import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/lesson.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:mind_keeper/data/repositories/knowledge_repository.dart';
import 'package:mind_keeper/data/repositories/lesson_repository.dart';
import 'package:mind_keeper/data/repositories/topic_repository.dart';

import '../helpers/test_db.dart';

void main() {
  setUp(initFfi);

  Future<Lesson> createTestLesson(
    LessonRepository lessons,
    String id,
    String title,
  ) async {
    final Lesson lesson = Lesson(
      id: id,
      domainId: 'science',
      domainName: 'Khoa học',
      topic: title,
      mode: LessonMode.standard,
      promptVersion: 'v1',
      dedupKey: 'test-dedup-$id',
      title: title,
      content: const LessonContent(
        learningObjectives: [],
        introduction: 'Intro',
        concepts: [],
        sections: [],
        keyPoints: [],
        examples: [],
        commonMistakes: [],
        summary: 'Summary',
      ),
      questions: const [],
      sources: const [],
      verification: LessonVerification.unverified,
      medical: false,
      wordCount: 100,
      isFavorite: false,
      isRead: false,
      linkedTopicId: null,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    return lessons.create(lesson);
  }

  /// Helper để so sánh DateTime với độ chính xác giây
  bool dateTimeEquals(DateTime a, DateTime b) {
    return a.difference(b).abs() < const Duration(seconds: 1);
  }

  test('enroll với cùng lessonId chỉ tạo một KnowledgeItem', () async {
    final AppDatabase app = await openMemoryDb();
    final KnowledgeRepository knowledge = KnowledgeRepository(app);
    final TopicRepository topics = TopicRepository(app);
    final LessonRepository lessons = LessonRepository(app);

    await createTestLesson(lessons, 'ls_1', 'Bài học A');
    final Topic topic = await topics.create(name: 'Test Topic');
    final DateTime now = DateTime.now().toUtc();

    // Enroll lần 1 với lessonId
    final KnowledgeItem item1 = await knowledge.enroll(
      topicId: topic.id,
      title: 'Bài học A',
      content: 'Nội dung bài học A',
      lessonId: 'ls_1',
      now: now,
    );

    expect(item1.title, 'Bài học A');
    expect(item1.lessonId, 'ls_1');
    expect(item1.startedAt, isNotNull);

    // Enroll lần 2 với CÙNG lessonId -> phải trả về item cũ
    final KnowledgeItem item2 = await knowledge.enroll(
      topicId: topic.id,
      title: 'Bài học A',
      content: 'Nội dung bài học A',
      lessonId: 'ls_1',
      now: now.add(const Duration(minutes: 1)),
    );

    expect(item2.id, item1.id);
    expect(
      dateTimeEquals(item2.startedAt!, item1.startedAt!),
      isTrue,
    ); // startedAt không đổi
    expect(
      item2.updatedAt,
      isNot(equals(item1.updatedAt)),
    ); // updatedAt cập nhật

    // Kiểm tra DB chỉ có 1 bản ghi
    final count = await knowledge.countAll();
    expect(count, 1);

    await app.close();
  });

  test(
    'enroll với cùng title nhưng KHÁC lessonId -> tạo KnowledgeItem riêng biệt',
    () async {
      final AppDatabase app = await openMemoryDb();
      final KnowledgeRepository knowledge = KnowledgeRepository(app);
      final TopicRepository topics = TopicRepository(app);
      final LessonRepository lessons = LessonRepository(app);

      await createTestLesson(lessons, 'ls_1', 'Bài học trùng tên');
      await createTestLesson(lessons, 'ls_2', 'Bài học trùng tên 2');
      final Topic topic = await topics.create(name: 'Test Topic');
      final DateTime now = DateTime.now().toUtc();

      // Enroll bài 1 với lessonId ls_1
      final KnowledgeItem item1 = await knowledge.enroll(
        topicId: topic.id,
        title: 'Bài học trùng tên',
        content: 'Nội dung bài 1',
        lessonId: 'ls_1',
        now: now,
      );

      // Enroll bài 2 với CÙNG title nhưng KHÁC lessonId
      final KnowledgeItem item2 = await knowledge.enroll(
        topicId: topic.id,
        title: 'Bài học trùng tên',
        content: 'Nội dung bài 2',
        lessonId: 'ls_2',
        now: now.add(const Duration(minutes: 1)),
      );

      // Phải là 2 KnowledgeItem khác nhau
      expect(item2.id, isNot(equals(item1.id)));
      expect(item2.lessonId, 'ls_2');
      expect(item1.lessonId, 'ls_1');

      // Kiểm tra DB có 2 bản ghi
      final count = await knowledge.countAll();
      expect(count, 2);

      await app.close();
    },
  );

  test('enroll không có lessonId fallback tìm theo title', () async {
    final AppDatabase app = await openMemoryDb();
    final KnowledgeRepository knowledge = KnowledgeRepository(app);
    final TopicRepository topics = TopicRepository(app);

    final Topic topic = await topics.create(name: 'Test Topic');
    final DateTime now = DateTime.now().toUtc();

    // Tạo KnowledgeItem không có lessonId (cũ)
    final KnowledgeItem existing = KnowledgeItem(
      id: 'ki_old',
      topicId: topic.id,
      title: 'Bài cũ',
      content: 'Nội dung cũ',
      startedAt: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    );
    await app.db.insert('knowledge_items', existing.toMap());

    // Enroll không cung cấp lessonId -> phải tìm được bài cũ theo title
    final KnowledgeItem found = await knowledge.enroll(
      topicId: topic.id,
      title: 'Bài cũ',
      content: 'Nội dung mới',
      now: now,
    );

    expect(found.id, 'ki_old');
    expect(found.startedAt, isNotNull); // đã có startedAt từ trước

    await app.close();
  });

  test('findByTitle ưu tiên lessonId hơn title', () async {
    final AppDatabase app = await openMemoryDb();
    final KnowledgeRepository knowledge = KnowledgeRepository(app);
    final TopicRepository topics = TopicRepository(app);
    final LessonRepository lessons = LessonRepository(app);

    await createTestLesson(lessons, 'ls_1', 'Bài trùng');
    await createTestLesson(lessons, 'ls_2', 'Bài trùng 2');
    final Topic topic = await topics.create(name: 'Test Topic');
    final DateTime now = DateTime.now().toUtc();

    // Tạo 2 KnowledgeItem cùng title khác lessonId
    await app.db.insert(
      'knowledge_items',
      KnowledgeItem(
        id: 'ki_1',
        topicId: topic.id,
        title: 'Bài trùng',
        content: 'Nội dung 1',
        lessonId: 'ls_1',
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    await app.db.insert(
      'knowledge_items',
      KnowledgeItem(
        id: 'ki_2',
        topicId: topic.id,
        title: 'Bài trùng',
        content: 'Nội dung 2',
        lessonId: 'ls_2',
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );

    // Tìm với lessonId ls_1 -> phải trả về ki_1
    final KnowledgeItem? found1 = await knowledge.findByTitle(
      topic.id,
      'Bài trùng',
      lessonId: 'ls_1',
    );
    expect(found1, isNotNull);
    expect(found1!.id, 'ki_1');

    // Tìm với lessonId ls_2 -> phải trả về ki_2
    final KnowledgeItem? found2 = await knowledge.findByTitle(
      topic.id,
      'Bài trùng',
      lessonId: 'ls_2',
    );
    expect(found2, isNotNull);
    expect(found2!.id, 'ki_2');

    // Tìm không có lessonId -> trả về ki_1 (thứ tự insert)
    final KnowledgeItem? found3 = await knowledge.findByTitle(
      topic.id,
      'Bài trùng',
    );
    expect(found3, isNotNull);

    await app.close();
  });

  test('migration v4->v5 thêm lesson_id column', () async {
    final AppDatabase app = await openMemoryDb();

    // Kiểm tra cột lesson_id tồn tại
    final columns = await app.db.rawQuery("PRAGMA table_info(knowledge_items)");
    final hasLessonId = columns.any((c) => c['name'] == 'lesson_id');
    expect(
      hasLessonId,
      isTrue,
      reason: 'lesson_id column should exist after migration',
    );

    // Kiểm tra index lesson_id
    final indexes = await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_knowledge_lesson'",
    );
    expect(
      indexes,
      isNotEmpty,
      reason: 'idx_knowledge_lesson index should exist',
    );

    await app.close();
  });
}
