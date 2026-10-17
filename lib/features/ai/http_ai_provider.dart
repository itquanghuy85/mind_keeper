import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

/// Provider HTTP thật (OpenAI-compatible).
/// Cấu hình baseUrl/apiKey/model từ cài đặt — KHÔNG nhúng key trong mã nguồn.
class HttpAIProvider implements AIProvider {
  HttpAIProvider({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    http.Client? client,
    this.timeout = const Duration(seconds: 45),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final String model;
  final http.Client _client;
  final Duration timeout;

  @override
  String get name => 'http';

  @override
  bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;

  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  Future<String> _chat(String systemPrompt, String userPrompt) async {
    final Uri uri = Uri.parse(
      baseUrl.endsWith('/chat/completions')
          ? baseUrl
          : '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
    );
    final http.Response response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(<String, Object?>{
            'model': model,
            'temperature': 0.2,
            'response_format': <String, String>{'type': 'json_object'},
            'messages': <Map<String, String>>[
              <String, String>{
                'role': 'system',
                'content': '$systemPrompt Trả về JSON hợp lệ, tiếng Việt.',
              },
              <String, String>{'role': 'user', 'content': userPrompt},
            ],
          }),
        )
        .timeout(timeout);
    if (response.statusCode == HttpStatus.unauthorized ||
        response.statusCode == HttpStatus.forbidden) {
      throw const AiProviderException('API key không hợp lệ hoặc bị từ chối.');
    }
    if (response.statusCode == HttpStatus.tooManyRequests) {
      throw const AiProviderException('Đã đạt giới hạn quota AI. Thử lại sau.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiProviderException(
        'Lỗi AI HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );
    }
    final Map<String, Object?> body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
    final Object? choices = body['choices'];
    String content = '';
    if (choices is List && choices.isNotEmpty) {
      final Object? first = choices.first;
      if (first is Map) {
        final Object? message = first['message'];
        if (message is Map) {
          content = (message['content'] ?? '').toString();
        }
      }
    }
    if (content.isEmpty) {
      throw const AiProviderException('AI trả về nội dung rỗng.');
    }
    return content;
  }

  Map<String, Object?> _decodeObject(String raw) {
    String text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      text = text.replaceFirst(RegExp(r'\n?```$'), '');
    }
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Đầu ra không phải JSON object.');
    }
    return decoded;
  }

  static const int _maxInputChars = 12000;

  String _clip(String text) =>
      text.length <= _maxInputChars ? text : text.substring(0, _maxInputChars);

  @override
  Future<List<AiKnowledgeDraft>> draftKnowledge({
    required String sourceText,
    int maxItems = 5,
  }) async {
    final String raw = await _chat(
      'Bạn tóm tắt văn bản thành các đơn vị kiến thức ngắn (1-3 câu mỗi ý), JSON: {"items":[{"title":"","content":"","details":""}]}',
      'Tối đa $maxItems mục.\n\n${_clip(sourceText)}',
    );
    final Map<String, Object?> obj = _decodeObject(raw);
    final List<Object?> items = (obj['items'] as List<Object?>?) ?? const <Object?>[];
    final List<AiKnowledgeDraft> drafts = <AiKnowledgeDraft>[];
    for (final Object? item in items) {
      if (item is! Map<String, Object?>) continue;
      try {
        drafts.add(AiKnowledgeDraft.fromMap(item));
      } on FormatException {
        continue;
      }
      if (drafts.length >= maxItems) break;
    }
    return drafts;
  }

  @override
  Future<List<AiQuestionDraft>> draftQuestions({
    required String knowledgeContent,
    int count = 2,
  }) async {
    final String raw = await _chat(
      'Tạo câu hỏi tự kiểm tra (một ý mỗi câu), JSON: {"questions":[{"question":"","answer":"","explanation":""}]}',
      'Số câu tối đa $count. Nội dung:\n${_clip(knowledgeContent)}',
    );
    final Map<String, Object?> obj = _decodeObject(raw);
    final List<Object?> items =
        (obj['questions'] as List<Object?>?) ?? const <Object?>[];
    final List<AiQuestionDraft> drafts = <AiQuestionDraft>[];
    for (final Object? item in items) {
      if (item is! Map<String, Object?>) continue;
      try {
        drafts.add(AiQuestionDraft.fromMap(item));
      } on FormatException {
        continue;
      }
      if (drafts.length >= count) break;
    }
    return drafts;
  }

  @override
  Future<AiTutorExplanation> explain({
    required String question,
    required String answer,
    String? userAnswer,
  }) async {
    final String raw = await _chat(
      'Giải thích ngắn gọn đáp án, JSON: {"explanation":"","example":""}',
      'Câu hỏi: $question\nĐáp án: $answer\n${userAnswer == null ? '' : 'Câu trả lời người dùng: $userAnswer'}',
    );
    return AiTutorExplanation.fromMap(_decodeObject(raw));
  }

  @override
  Future<AiAnswerEvaluation> gradeAnswer({
    required String question,
    required String referenceAnswer,
    required String userAnswer,
  }) async {
    final String raw = await _chat(
      'Chấm câu trả lời, JSON: {"verdict":"correct|partial|wrong","comment":"","score":0.0}',
      'Câu hỏi: $question\nĐáp án đúng: $referenceAnswer\nTrả lời: $userAnswer',
    );
    return AiAnswerEvaluation.fromMap(_decodeObject(raw));
  }

  @override
  Future<AiLessonDraft> generateLesson({
    required String domain,
    required String topic,
    required String mode,
    required int wordMin,
    required int wordMax,
    required int questionCount,
  }) async {
    final int maxQuestions = questionCount < 3 ? 3 : (questionCount > 5 ? 5 : questionCount);
    final String raw = await _chat(
      'Bạn soạn bài học JSON tiếng Việt cho ứng dụng học tập. '
      'NGUYÊN TẮC NGUỒN: chỉ ghi nguồn vào mảng "sources" nếu bạn chắc chắn '
      'nội dung đó tồn tại và chính xác; nếu không chắc, để mảng rỗng — '
      'tuyệt đối không bịa nguồn. Nếu nội dung liên quan đến y tế, đặt "medical": true. '
      'JSON bắt buộc: {"title":"","introduction":"",'
      '"sections":[{"heading":"","body":""}],"key_points":[""],'
      '"examples":[""],"summary":"",'
      '"questions":[{"question":"","answer":"","explanation":""}],'
      '"sources":[{"title":"","url":""}],"medical":false}',
      'Lĩnh vực: $domain\nChủ đề: $topic\nChế độ học: $mode\n'
      'Yêu cầu: toàn bài nằm trong khoảng $wordMin-$wordMax từ; '
      'đúng $maxQuestions câu hỏi ghi nhớ; tiếng Việt chính xác; '
      'bài có mở đầu, phần chính, điểm cốt lõi, ví dụ và tóm tắt.',
    );
    return AiLessonDraft.fromMap(
      _decodeObject(raw),
      maxQuestions: maxQuestions,
    );
  }
}

class AiProviderException implements Exception {
  const AiProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}
