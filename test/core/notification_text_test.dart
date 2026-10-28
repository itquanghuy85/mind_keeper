import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/notification_text.dart';

void main() {
  group('truncateAtWord', () {
    test('văn bản ngắn giữ nguyên, gộp khoảng trắng', () {
      expect(truncateAtWord('  Xin   chào\nbạn ', 50), 'Xin chào bạn');
    });

    test('không cắt giữa từ và không vượt giới hạn', () {
      const String text =
          'Nhiều người học nhanh nhưng quên chậm vì chưa kết nối thông tin mới';
      for (int max = 10; max < text.length; max += 3) {
        final String out = truncateAtWord(text, max);
        expect(out.length, lessThanOrEqualTo(max), reason: 'max=$max');
        expect(out, endsWith('…'));
        final String body = out.substring(0, out.length - 1);
        // Phần giữ lại phải là tiền tố nguyên từ của văn bản gốc.
        expect(text.startsWith(body), isTrue, reason: out);
        expect(
          text.length == body.length || text[body.length] == ' ',
          isTrue,
          reason: 'cắt giữa từ: $out',
        );
      }
    });

    test('từ đơn dài hơn giới hạn vẫn cắt cứng, không rỗng', () {
      final String out = truncateAtWord('Pneumonoultramicroscopic', 8);
      expect(out.length, lessThanOrEqualTo(8));
      expect(out, isNotEmpty);
    });

    test('max <= 0 → rỗng', () {
      expect(truncateAtWord('abc', 0), isEmpty);
    });
  });

  group('leadSentences', () {
    test('lấy tối đa 2 câu đầu trong giới hạn', () {
      const String text =
          'Câu một nói ý chính. Câu hai bổ sung thêm. Câu ba không cần.';
      expect(
        leadSentences(text, maxSentences: 2, max: 180),
        'Câu một nói ý chính. Câu hai bổ sung thêm.',
      );
    });

    test('câu thứ hai làm vượt giới hạn thì chỉ giữ câu đầu', () {
      final String long2 = 'Hai ${'chữ ' * 60}.';
      final String out = leadSentences('Câu đầu ngắn. $long2', max: 50);
      expect(out, 'Câu đầu ngắn.');
    });

    test('câu đầu quá dài thì cắt theo từ', () {
      final String out = leadSentences('${'từ ' * 100}.', max: 40);
      expect(out.length, lessThanOrEqualTo(40));
      expect(out, endsWith('…'));
    });

    test('rỗng → rỗng', () {
      expect(leadSentences('   '), isEmpty);
    });
  });

  group('composeBigText', () {
    test('có mẹo nhớ → thêm dòng "Mẹo nhớ: ..."', () {
      expect(
        composeBigText('Tóm tắt.', 'Gắn với hình ảnh.'),
        'Tóm tắt.\nMẹo nhớ: Gắn với hình ảnh.',
      );
    });

    test('không có mẹo nhớ → chỉ tóm tắt', () {
      expect(composeBigText('Tóm tắt.', '  '), 'Tóm tắt.');
    });

    test('tóm tắt rỗng nhưng có mẹo nhớ', () {
      expect(composeBigText('', 'Mẹo'), 'Mẹo nhớ: Mẹo');
    });
  });

  test('notificationBody ≤ 180 ký tự', () {
    final String out = notificationBody('từ ' * 200);
    expect(out.length, lessThanOrEqualTo(notificationBodyMax));
  });
}
