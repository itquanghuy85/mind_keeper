import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/widgets/memory_tip_card.dart';
import 'package:mind_keeper/data/models/course.dart';
import 'package:mind_keeper/data/models/lesson.dart';
import 'package:mind_keeper/features/ai/ai_provider.dart';
import 'package:mind_keeper/features/ai/course_ai.dart';
import 'package:mind_keeper/features/ai/mock_ai_provider.dart';

int _words(String text) => countLessonWords(text);

int _sentences(String text) => text
    .split(RegExp(r'[.!?]'))
    .where((String s) => s.trim().isNotEmpty)
    .length;

void main() {
  group('AiBiteDraft — mẹo nhớ + giới hạn độ dài', () {
    test('đọc memoryTip / memory_tip / tip', () {
      for (final String key in <String>['memoryTip', 'memory_tip', 'tip']) {
        final AiBiteDraft d = AiBiteDraft.fromMap(<String, Object?>{
          'title': 'T',
          'content': 'Nội dung.',
          'summary': 'Tóm tắt.',
          key: 'Mẹo nhớ ngắn.',
        });
        expect(d.memoryTip, 'Mẹo nhớ ngắn.', reason: key);
      }
    });

    test('thiếu memoryTip → rỗng (không lỗi)', () {
      final AiBiteDraft d = AiBiteDraft.fromMap(<String, Object?>{
        'title': 'T',
        'content': 'Nội dung.',
      });
      expect(d.memoryTip, isEmpty);
    });

    test('summary > 200 và memoryTip > 120 bị cắt theo từ', () {
      final AiBiteDraft d = AiBiteDraft.fromMap(<String, Object?>{
        'title': 'T',
        'content': 'Nội dung.',
        'summary': 'từ ${'dài ' * 100}',
        'memoryTip': 'mẹo ${'dài ' * 100}',
      });
      expect(d.summary.length, lessThanOrEqualTo(200));
      expect(d.memoryTip.length, lessThanOrEqualTo(120));
      expect(d.summary, endsWith('…'));
    });

    test('shortSummary tối đa 2 câu / 200 ký tự', () {
      final String out = AiBiteDraft.shortSummary(
        'Câu một. Câu hai. Câu ba. Câu bốn.',
      );
      expect(out, 'Câu một. Câu hai.');
      expect(
        AiBiteDraft.shortSummary('${'chữ ' * 200}.').length,
        lessThanOrEqualTo(200),
      );
    });
  });

  group('AiLessonDraft / LessonContent — mẹo nhớ', () {
    Map<String, Object?> baseLesson() => <String, Object?>{
      'title': 'T',
      'introduction': 'Mở đầu.',
      'sections': <Object?>[
        <String, Object?>{'heading': 'P1', 'body': 'Nội dung.'},
      ],
    };

    test('parser đọc memoryTip (camel/snake) và cắt ≤120 ký tự', () {
      final AiLessonDraft camel = AiLessonDraft.fromMap(<String, Object?>{
        ...baseLesson(),
        'memoryTip': 'Mẹo A.',
      });
      expect(camel.memoryTip, 'Mẹo A.');
      final AiLessonDraft snake = AiLessonDraft.fromMap(<String, Object?>{
        ...baseLesson(),
        'memory_tip': 'Mẹo B.',
        'summary': 'x ${'y ' * 200}',
      });
      expect(snake.memoryTip, 'Mẹo B.');
      expect(snake.summary.length, lessThanOrEqualTo(200));
      final AiLessonDraft long = AiLessonDraft.fromMap(<String, Object?>{
        ...baseLesson(),
        'memoryTip': 'mẹo ${'dài ' * 100}',
      });
      expect(long.memoryTip.length, lessThanOrEqualTo(120));
    });

    test('LessonContent lưu/đọc memory_tip; bài cũ không có khóa → rỗng', () {
      final LessonContent c = LessonContent.fromMap(<String, Object?>{
        ...baseLesson(),
        'memory_tip': 'Mẹo nhớ.',
      });
      expect(c.memoryTip, 'Mẹo nhớ.');
      expect(c.toMap()['memory_tip'], 'Mẹo nhớ.');
      final LessonContent old = LessonContent.fromMap(baseLesson());
      expect(old.memoryTip, isEmpty);
    });
  });

  group('LessonMode — mô tả và khung từ mới', () {
    test('mọi chế độ nằm trong 100–180 từ, mô tả không còn 500–800', () {
      for (final LessonMode m in LessonMode.values) {
        expect(m.wordMin, inInclusiveRange(100, 180), reason: m.id);
        expect(m.wordMax, inInclusiveRange(m.wordMin, 180), reason: m.id);
        expect(m.description, isNot(contains('500')));
        expect(m.description, isNot(contains('800')));
      }
      expect(LessonMode.standard.wordMin, 120);
      expect(LessonMode.standard.wordMax, 180);
    });
  });

  group('MockAIProvider — nội dung mới ngắn', () {
    final MockAIProvider mock = MockAIProvider(latency: Duration.zero);

    test('mẩu khóa học 120–180 từ, tóm tắt ≤200, mẹo nhớ ≤120', () async {
      for (final CourseLevel level in CourseLevel.values) {
        final AiBiteDraft d = await mock.generateBite(
          topic: 'Bếp từ',
          level: level,
          title: 'Nguyên lý hoạt động',
          index: 2,
          total: 5,
        );
        expect(
          _words(d.content),
          inInclusiveRange(120, 180),
          reason: level.dbValue,
        );
        expect(d.summary.length, lessThanOrEqualTo(200));
        expect(d.memoryTip, isNotEmpty);
        expect(d.memoryTip.length, lessThanOrEqualTo(120));
        expect(_sentences(d.example), 1);
      }
    });

    test(
      'bài học mỗi chế độ nằm trong khung từ, ≤3 ý chính, có mẹo nhớ',
      () async {
        for (final LessonMode mode in LessonMode.values) {
          final AiLessonDraft d = await mock.generateLesson(
            domain: 'Khoa học',
            topic: 'Vũ trụ',
            mode: mode.id,
            wordMin: mode.wordMin,
            wordMax: mode.wordMax,
            questionCount: mode.questions,
          );
          expect(
            d.wordCount,
            inInclusiveRange(mode.wordMin - 15, mode.wordMax + 15),
            reason: '${mode.id}: ${d.wordCount} từ',
          );
          expect(d.keyPoints.length, lessThanOrEqualTo(3));
          expect(d.examples, hasLength(1));
          expect(d.summary.length, lessThanOrEqualTo(200));
          expect(d.memoryTip, isNotEmpty);
          expect(d.memoryTip.length, lessThanOrEqualTo(120));
        }
      },
    );
  });

  group('MemoryTipCard', () {
    testWidgets('hiện tiêu đề + nội dung khi có mẹo nhớ', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MemoryTipCard(tip: 'Gắn với hình ảnh.')),
        ),
      );
      expect(find.text('Mẹo nhớ'), findsOneWidget);
      expect(find.text('Gắn với hình ảnh.'), findsOneWidget);
    });

    testWidgets('ẩn hoàn toàn khi rỗng', (WidgetTester t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MemoryTipCard(tip: '  ')),
        ),
      );
      expect(find.text('Mẹo nhớ'), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });
  });
}
