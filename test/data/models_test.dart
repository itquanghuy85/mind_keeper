import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/models/enums.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/lesson.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/data/models/review_log.dart';
import 'package:mind_keeper/data/models/source.dart';
import 'package:mind_keeper/data/models/topic.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 4, 25, 9, 41);

  test('Topic toMap/fromMap roundtrip', () {
    final Topic topic = Topic(
      id: 'tp_1',
      name: 'Khoa học',
      description: 'Mô tả',
      category: 'Khoa học',
      icon: '🔬',
      origin: TopicOrigin.discovered,
      isActive: false,
      createdAt: now,
      updatedAt: now,
    );
    final Topic restored = Topic.fromMap(topic.toMap());
    expect(restored.id, topic.id);
    expect(restored.name, 'Khoa học');
    expect(restored.origin, TopicOrigin.discovered);
    expect(restored.isActive, false);
    expect(restored.createdAt.toUtc(), now);
  });

  test('Source roundtrip giữ trạng thái xử lý và nguồn tham khảo', () {
    final Source source = Source(
      id: 'src_1',
      topicId: 'tp_1',
      type: SourceType.pdf,
      title: 'Bài báo',
      storagePath: '/tmp/a.pdf',
      contentText: 'Nội dung trích xuất',
      status: SourceStatus.processing,
      referenceUrl: 'https://example.com',
      referenceLocation: 'trang 3',
      errorMessage: null,
      createdAt: now,
      updatedAt: now,
    );
    final Source restored = Source.fromMap(source.toMap());
    expect(restored.type, SourceType.pdf);
    expect(restored.status, SourceStatus.processing);
    expect(restored.referenceUrl, 'https://example.com');
    expect(restored.isReady, false);
  });

  test('KnowledgeItem roundtrip giữ cờ yêu thích và tạm dừng', () {
    final KnowledgeItem item = KnowledgeItem(
      id: 'ki_1',
      topicId: 'tp_1',
      sourceId: 'src_1',
      title: 'Đường cong lãng quên',
      content: 'Trí nhớ giảm nhanh sau khi học.',
      details: 'Chi tiết',
      origin: KnowledgeOrigin.extracted,
      isFavorite: true,
      isPaused: true,
      createdAt: now,
      updatedAt: now,
    );
    final KnowledgeItem restored = KnowledgeItem.fromMap(item.toMap());
    expect(restored.origin, KnowledgeOrigin.extracted);
    expect(restored.isFavorite, true);
    expect(restored.isPaused, true);
    expect(restored.sourceId, 'src_1');
  });

  test('ReviewCard roundtrip lưu toàn bộ trạng thái lịch ôn', () {
    final ReviewCard card = ReviewCard(
      id: 'rc_1',
      knowledgeItemId: 'ki_1',
      question: 'Câu hỏi?',
      answer: 'Đáp án',
      questionType: QuestionType.cloze,
      fsrsState: 1,
      fsrsStep: 2,
      stability: 3.5,
      difficulty: 6.25,
      dueAt: now.add(const Duration(days: 3)),
      lastReviewAt: now,
      reps: 4,
      lapses: 1,
      createdAt: now,
      updatedAt: now,
    );
    final ReviewCard restored = ReviewCard.fromMap(card.toMap());
    expect(restored.fsrsState, 1);
    expect(restored.fsrsStep, 2);
    expect(restored.stability, 3.5);
    expect(restored.difficulty, 6.25);
    expect(restored.dueAt.toUtc(), now.add(const Duration(days: 3)));
    expect(restored.reps, 4);
    expect(restored.lapses, 1);
    expect(restored.isNew, false);
  });

  test('ReviewLog roundtrip giữ đánh giá bốn mức', () {
    final ReviewLog log = ReviewLog(
      id: 'rl_1',
      cardId: 'rc_1',
      reviewedAt: now,
      rating: MemoryRating.hard,
      dueBefore: now,
      dueAfter: now.add(const Duration(days: 1)),
      stateBefore: 0,
      stateAfter: 0,
      stabilityBefore: 0.5,
      stabilityAfter: 0.9,
      answerText: 'trả lời',
      autoGrade: 'partial',
      note: 'ghi chú',
    );
    final ReviewLog restored = ReviewLog.fromMap(log.toMap());
    expect(restored.rating, MemoryRating.hard);
    expect(restored.rating.vietnameseLabel, 'Khó');
    expect(restored.stabilityAfter, 0.9);
    expect(restored.autoGrade, 'partial');
  });

  test('MemoryRating ánh xạ bốn mức đúng theo FSRS', () {
    expect(MemoryRating.fromValue(1), MemoryRating.again);
    expect(MemoryRating.fromValue(2), MemoryRating.hard);
    expect(MemoryRating.fromValue(3), MemoryRating.good);
    expect(MemoryRating.fromValue(4), MemoryRating.easy);
    expect(MemoryRating.again.fsrsLabel, 'Again');
    expect(MemoryRating.easy.fsrsLabel, 'Easy');
    expect(MemoryRating.good.value, 3);
  });

  test('Enum db không khớp không làm hỏng model', () {
    final Map<String, Object?> map = <String, Object?>{
      'id': 'tp_x',
      'name': 'A',
      'origin': 'khong_ro',
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    };
    final Topic topic = Topic.fromMap(map);
    expect(topic.origin, TopicOrigin.personal);
    expect(QuestionType.fromDb('unknown'), QuestionType.recall);
    expect(SourceStatus.fromDb('unknown'), SourceStatus.ready);
    expect(KnowledgeOrigin.fromDb('unknown'), KnowledgeOrigin.userConfirmed);
  });

  test('Lesson toRow/fromRow roundtrip giữ nội dung, câu hỏi và nguồn', () {
    final Lesson lesson = Lesson(
      id: 'ls_1',
      domainId: 'science',
      domainName: 'Khoa học',
      topic: 'Vũ trụ',
      mode: LessonMode.deep,
      promptVersion: 'v1',
      dedupKey: 'science|vũ trụ|deep|v1',
      title: 'Vũ trụ — khám phá trong Khoa học',
      content: const LessonContent(
        introduction: 'Mở đầu bài học.',
        sections: <LessonSection>[
          LessonSection(heading: 'Bức tranh tổng quan', body: 'Nội dung phần một.'),
        ],
        keyPoints: <String>['Ý chính 1', 'Ý chính 2'],
        examples: <String>['Ví dụ 1'],
        summary: 'Tóm tắt ngắn gọn.',
      ),
      questions: const <LessonQuestion>[
        LessonQuestion(
          question: 'Vũ trụ là gì?',
          answer: 'Toàn bộ không gian và thời gian.',
          explanation: 'Giải thích.',
        ),
      ],
      sources: const <LessonSource>[
        LessonSource(title: 'Wikipedia', url: 'https://example.com'),
      ],
      verification: LessonVerification.sourced,
      medical: false,
      wordCount: 42,
      isFavorite: true,
      isRead: true,
      linkedTopicId: 'tp_1',
      createdAt: now,
      updatedAt: now,
    );

    final Lesson restored = Lesson.fromRow(lesson.toRow());
    expect(restored.id, 'ls_1');
    expect(restored.domainId, 'science');
    expect(restored.mode, LessonMode.deep);
    expect(restored.content.introduction, 'Mở đầu bài học.');
    expect(restored.content.sections, hasLength(1));
    expect(restored.content.keyPoints, hasLength(2));
    expect(restored.questions, hasLength(1));
    expect(restored.questions.first.answer, 'Toàn bộ không gian và thời gian.');
    expect(restored.sources, hasLength(1));
    expect(restored.sources.first.url, 'https://example.com');
    expect(restored.verification, LessonVerification.sourced);
    expect(restored.medical, isFalse);
    expect(restored.isFavorite, isTrue);
    expect(restored.isRead, isTrue);
    expect(restored.linkedTopicId, 'tp_1');
    expect(restored.createdAt.toUtc(), now);
  });

  test('Lesson dedup key chuẩn hóa topic và khác nhau theo mode', () {
    final String a = Lesson.buildDedupKey(
      domainId: 'tech',
      topic: '  Trí Tuệ  Nhân Tạo ',
      mode: LessonMode.standard,
      promptVersion: 'v1',
    );
    final String b = Lesson.buildDedupKey(
      domainId: 'tech',
      topic: 'trí tuệ nhân tạo',
      mode: LessonMode.standard,
      promptVersion: 'v1',
    );
    final String c = Lesson.buildDedupKey(
      domainId: 'tech',
      topic: 'trí tuệ nhân tạo',
      mode: LessonMode.deep,
      promptVersion: 'v1',
    );
    expect(a, b);
    expect(a, isNot(c));
  });

  test('LessonContent.fromMap từ chối bài thiếu mở đầu hoặc phần nội dung', () {
    expect(
      () => LessonContent.fromMap(const <String, Object?>{
        'introduction': '',
        'sections': <Object?>[
          <String, Object?>{'heading': 'A', 'body': 'B'},
        ],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => LessonContent.fromMap(const <String, Object?>{
        'introduction': 'Có mở đầu',
        'sections': <Object?>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('LessonMode ánh xạ mặc định và parse', () {
    expect(LessonMode.tryParse('deep'), LessonMode.deep);
    expect(LessonMode.tryParse('unknown'), isNull);
    expect(LessonMode.defaultMode, LessonMode.standard);
    expect(LessonMode.path.isGated, isTrue);
    expect(LessonMode.standard.isGated, isFalse);
  });
}
