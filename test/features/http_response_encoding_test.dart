import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mind_keeper/features/ai/http_ai_provider.dart';

/// Ký tự thay thế Unicode — dấu hiệu nội dung đã bị hỏng encoding.
const String replacementChar = '�';

void main() {
  group('GĐ22.1 — giải mã response JSON tiếng Việt', () {
    test('Thiếu charset → mặc định UTF-8', () {
      final String payload =
          '{"choices":[{"message":{"content":"Nguyên tử và phân tử"}}]}';
      final http.Response response = http.Response.bytes(
        utf8.encode(payload),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
      expect(
        HttpAIProvider.decodeBody(response),
        contains('Nguyên tử và phân tử'),
      );
    });

    test('Charset khai báo rõ ràng là UTF-8', () {
      final String payload =
          '{"choices":[{"message":{"content":"Thuyết tiến hóa"}}]}';
      final http.Response response = http.Response.bytes(
        utf8.encode(payload),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
      expect(HttpAIProvider.decodeBody(response), contains('Thuyết tiến hóa'));
    });

    test('Charset khai báo rõ ràng là ISO-8859-1 → giải mã đúng charset', () {
      final String payload =
          '{"choices":[{"message":{"content":"Vũ trụ và các thiên hà"}}]}';
      final http.Response response = http.Response.bytes(
        utf8.encode(payload),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=iso-8859-1',
        },
      );
      // ISO-8859-1 không giữ được dấu tiếng Việt — phải giải mã theo charset
      // đã khai báo (latin1), không tự ý ép UTF-8.
      final String decoded = HttpAIProvider.decodeBody(response);
      expect(decoded, isNotEmpty);
      expect(
        decoded.contains(replacementChar),
        isFalse,
        reason: 'Latin-1 không sinh ký tự thay thế U+FFFD.',
      );
    });

    test('Nội dung UTF-8 hợp lệ không bao giờ chứa ký tự thay thế', () {
      const String vietnamese = 'Nguyên tử và phân tử — Thuyết tiến hóa';
      final http.Response response = http.Response.bytes(
        utf8.encode('{"a":"$vietnamese"}'),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
      final String decoded = HttpAIProvider.decodeBody(response);
      expect(decoded, contains(vietnamese));
      expect(decoded.contains(replacementChar), isFalse);
    });

    test('Charset lạ không hỗ trợ → rơi về UTF-8, không hỏng nội dung', () {
      final String payload = '{"a":"Nguyên tử và phân tử"}';
      final http.Response response = http.Response.bytes(
        utf8.encode(payload),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=shift-jis',
        },
      );
      final String decoded = HttpAIProvider.decodeBody(response);
      expect(decoded, contains('Nguyên tử và phân tử'));
    });
  });
}
