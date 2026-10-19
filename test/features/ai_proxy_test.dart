import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mind_keeper/features/ai/ai_service.dart';
import 'package:mind_keeper/features/ai/http_ai_provider.dart';
import 'package:mind_keeper/features/ai/mock_ai_provider.dart';

/// Trả về MockClient ghi lại request cuối cùng để kiểm tra header/URL.
({MockClient client, List<http.Request> requests}) _recordingClient() {
  final List<http.Request> requests = <http.Request>[];
  final MockClient client = MockClient((http.Request request) async {
    requests.add(request);
    return http.Response(
      jsonEncode(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{
              'content': jsonEncode(<String, Object?>{
                'questions': <Object?>[
                  <String, Object?>{
                    'question': 'Q',
                    'answer': 'A',
                    'explanation': 'E',
                  },
                ],
              }),
            },
          },
        ],
      }),
      200,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
  return (client: client, requests: requests);
}

void main() {
  group('HttpAIProvider — chế độ proxy an toàn', () {
    test(
      'proxy mode: KHÔNG gửi Authorization, vẫn gọi đúng endpoint',
      () async {
        final recorded = _recordingClient();
        final HttpAIProvider provider = HttpAIProvider(
          baseUrl: 'https://example.functions.net/deepseekChat',
          apiKey: '',
          model: 'deepseek-chat',
          proxyMode: true,
          client: recorded.client,
        );

        expect(provider.isConfigured, isTrue);
        expect(provider.name, 'deepseek-proxy');

        final drafts = await provider.draftQuestions(
          knowledgeContent: 'Nội dung',
          count: 1,
        );
        expect(drafts, hasLength(1));

        expect(recorded.requests, hasLength(1));
        final http.Request request = recorded.requests.single;
        expect(
          request.url.toString(),
          'https://example.functions.net/deepseekChat/chat/completions',
        );
        expect(request.headers.containsKey('Authorization'), isFalse);
      },
    );

    test('proxy mode + clientToken: gửi X-Client-Token thay vì key', () async {
      final recorded = _recordingClient();
      final HttpAIProvider provider = HttpAIProvider(
        baseUrl: 'https://example.functions.net/deepseekChat',
        model: 'deepseek-chat',
        proxyMode: true,
        clientToken: 'device-abc',
        client: recorded.client,
      );

      await provider.draftQuestions(knowledgeContent: 'x', count: 1);

      final http.Request request = recorded.requests.single;
      expect(request.headers['X-Client-Token'], 'device-abc');
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('chế độ trực tiếp: vẫn gửi Authorization Bearer', () async {
      final recorded = _recordingClient();
      final HttpAIProvider provider = HttpAIProvider(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'sk-test',
        model: 'deepseek-chat',
        client: recorded.client,
      );

      expect(provider.name, 'deepseek');
      expect(provider.isConfigured, isTrue);

      await provider.draftQuestions(knowledgeContent: 'x', count: 1);

      final http.Request request = recorded.requests.single;
      expect(request.headers['Authorization'], 'Bearer sk-test');
    });

    test('thiếu key ở chế độ trực tiếp → isConfigured false', () {
      final HttpAIProvider provider = HttpAIProvider(
        baseUrl: 'https://api.deepseek.com',
        apiKey: '',
      );
      expect(provider.isConfigured, isFalse);
    });
  });

  group('AiService — cấu hình proxy', () {
    test('configureFromSettings(proxyMode: true) không cần key', () {
      final AiService service = AiService(provider: MockAIProvider());
      service.configureFromSettings(
        baseUrl: 'https://example.functions.net/ai',
        apiKey: '',
        model: 'deepseek-chat',
        proxyMode: true,
      );

      expect(service.isRealProvider, isTrue);
      expect(service.provider.name, 'deepseek-proxy');
    });

    test('proxyMode nhưng thiếu baseUrl ⇒ vẫn dùng mock', () {
      final AiService service = AiService(provider: MockAIProvider());
      service.configureFromSettings(
        baseUrl: '',
        apiKey: '',
        model: 'deepseek-chat',
        proxyMode: true,
      );
      expect(service.isRealProvider, isFalse);
    });

    test('configureDeepSeekDefault(proxyMode) bật provider khi có baseUrl', () {
      final AiService service = AiService(provider: MockAIProvider());
      final bool ok = service.configureDeepSeekDefault(
        apiKey: '',
        baseUrl: 'https://example.functions.net/ai',
        proxyMode: true,
      );
      expect(ok, isTrue);
      expect(service.provider.name, 'deepseek-proxy');
    });

    test(
      'configureDeepSeekDefault(proxyMode) thiếu baseUrl ⇒ false + mock',
      () {
        final AiService service = AiService(provider: MockAIProvider());
        final bool ok = service.configureDeepSeekDefault(
          apiKey: 'sk-x',
          baseUrl: '',
          proxyMode: true,
        );
        expect(ok, isFalse);
        expect(service.isRealProvider, isFalse);
      },
    );
  });
}
