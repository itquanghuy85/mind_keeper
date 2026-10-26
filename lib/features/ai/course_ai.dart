/// AI cho khóa học: dựng đề cương và sinh từng mẩu kiến thức theo cấp độ.
///
/// Tách khỏi [AIProvider] để các provider/fake cũ không phải thay đổi:
/// provider nào hỗ trợ khóa học thì implement thêm [CourseAiProvider].
library;

import '../../data/models/course.dart';

/// Một mẩu kiến thức đã soạn: bản đầy đủ + bản tóm tắt cho thông báo.
class AiBiteDraft {
  const AiBiteDraft({
    required this.title,
    required this.content,
    required this.summary,
    this.example = '',
    this.sources = const <String>[],
    this.question = '',
    this.answer = '',
  });

  final String title;

  /// Nội dung đầy đủ (đọc trong app).
  final String content;

  /// 2–3 câu: ý chính để đọc ngay trong thông báo.
  final String summary;
  final String example;

  /// Tên giáo trình / từ khóa nên tra — KHÔNG ghi link.
  final List<String> sources;
  final String question;
  final String answer;

  factory AiBiteDraft.fromMap(Map<String, Object?> map) {
    String pick(List<String> keys) {
      for (final String key in keys) {
        final Object? value = map[key];
        if (value == null) continue;
        final String text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final String title = pick(<String>['title']);
    final String content = pick(<String>['content']);
    if (title.isEmpty || content.isEmpty) {
      throw const FormatException('Thiếu title hoặc content của mẩu');
    }
    String summary = pick(<String>['summary']);
    if (summary.isEmpty) summary = shortSummary(content);
    final List<String> sources = <String>[];
    final Object? rawSources = map['sources'];
    if (rawSources is List<Object?>) {
      for (final Object? s in rawSources) {
        final String text = (s is Map ? (s['title'] ?? '') : s ?? '')
            .toString()
            .trim();
        if (text.isNotEmpty) sources.add(text);
      }
    } else if (rawSources is String && rawSources.trim().isNotEmpty) {
      sources.add(rawSources.trim());
    }
    return AiBiteDraft(
      title: title,
      content: content,
      summary: summary,
      example: pick(<String>['example']),
      sources: sources,
      question: pick(<String>['question']),
      answer: pick(<String>['answer']),
    );
  }

  /// Cắt [text] thành tối đa ~3 câu / 280 ký tự (dùng khi AI bỏ trống summary).
  static String shortSummary(String text) {
    final String flat = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final List<String> sentences = flat.split(RegExp(r'(?<=[.!?])\s+'));
    final StringBuffer out = StringBuffer();
    int count = 0;
    for (final String s in sentences) {
      if (count >= 3 || out.length + s.length > 280) break;
      if (out.isNotEmpty) out.write(' ');
      out.write(s);
      count++;
    }
    final String result = out.toString().trim();
    if (result.isNotEmpty) return result;
    return flat.length <= 280 ? flat : '${flat.substring(0, 277)}…';
  }
}

abstract class CourseAiProvider {
  /// Dựng đề cương: đúng [count] tiêu đề, từ dễ đến khó, không trùng ý.
  Future<List<String>> generateOutline({
    required String topic,
    required CourseLevel level,
    required int count,
  });

  /// Soạn một mẩu theo tiêu đề trong đề cương.
  Future<AiBiteDraft> generateBite({
    required String topic,
    required CourseLevel level,
    required String title,
    required int index,
    required int total,
    List<String> previousTitles = const <String>[],
  });
}

/// Lọc tiêu đề đề cương: bỏ trống/trùng, giữ thứ tự, cắt tối đa [count].
List<String> cleanOutline(Iterable<Object?> raw, int count) {
  final List<String> titles = <String>[];
  final Set<String> seen = <String>{};
  for (final Object? entry in raw) {
    final String text = (entry is Map ? (entry['title'] ?? '') : entry ?? '')
        .toString()
        .trim();
    if (text.isEmpty) continue;
    if (!seen.add(text.toLowerCase())) continue;
    titles.add(text);
    if (titles.length >= count) break;
  }
  return titles;
}
