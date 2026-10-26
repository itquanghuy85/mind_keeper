import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../data/models/course.dart';
import 'ai_provider.dart';
import 'course_ai.dart';

/// Provider HTTP thật (OpenAI-compatible).
/// Cấu hình baseUrl/apiKey/model từ cài đặt — KHÔNG nhúng key trong mã nguồn.
///
/// Hai chế độ:
/// - Trực tiếp (`proxyMode = false`): client giữ API key và gửi
///   `Authorization: Bearer <key>` tới `baseUrl`.
/// - Proxy (`proxyMode = true`): `baseUrl` là endpoint proxy của backend
///   (vd Cloud Functions). Client KHÔNG cần và KHÔNG gửi key DeepSeek;
///   backend giữ key trong secret và tự thêm header khi gọi DeepSeek.
class HttpAIProvider implements AIProvider, CourseAiProvider {
  static const String defaultBaseUrl = 'https://api.openai.com/v1';
  static const String defaultModel = 'gpt-4o-mini';

  HttpAIProvider({
    String? baseUrl,
    String? apiKey,
    String? model,
    this.proxyMode = false,
    String? clientToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _baseUrl = (baseUrl?.trim().isNotEmpty == true)
           ? baseUrl!.trim()
           : defaultBaseUrl,
       _apiKey = apiKey?.trim() ?? '',
       _model = (model?.trim().isNotEmpty == true)
           ? model!.trim()
           : defaultModel,
       _clientToken = clientToken?.trim() ?? '',
       _client = client ?? http.Client();

  final String _baseUrl;
  final String _apiKey;
  final String _model;
  final http.Client _client;

  /// True khi gọi qua proxy backend (key nằm ở server, không ở client).
  final bool proxyMode;

  /// Token định danh client gửi kèm khi dùng proxy (không phải API key DeepSeek).
  final String _clientToken;

  final Duration timeout;

  @override
  String get name => proxyMode ? 'deepseek-proxy' : 'deepseek';

  @override
  bool get isConfigured => proxyMode ? _baseUrl.isNotEmpty : _apiKey.isNotEmpty;

  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;
  String get model => _model;

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    if (!proxyMode && _apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
    if (proxyMode && _clientToken.isNotEmpty) 'X-Client-Token': _clientToken,
  };

  /// Giải mã body HTTP thành chuỗi, tôn trọng charset do server khai báo.
  ///
  /// Hợp đồng API hiện tại: OpenAI-compatible trả `application/json; charset=utf-8`.
  /// Nếu server khai báo charset khác (ví dụ `iso-8859-1`) thì decode theo charset
  /// đó; nếu **thiếu** charset thì mặc định UTF-8 (JSON theo RFC 8259 là UTF-8).
  /// Không dùng `response.body` vì package:http tự ý decode theo charset mặc
  /// định của locale (Latin-1 trên một số nền tảng) → tiếng Việt bị hỏng.
  static String decodeBody(http.Response response) {
    final String? contentType = response.headers['content-type'];
    final RegExpMatch? charsetMatch = contentType == null
        ? null
        : RegExp(
            r'charset\s*=\s*"?\s*([A-Za-z0-9_\-]+)\s*"?',
            caseSensitive: false,
          ).firstMatch(contentType);
    final String? charset = charsetMatch?.group(1)?.toLowerCase();
    if (charset != null && charset != 'utf-8' && charset != 'utf8') {
      // dart:convert chỉ có sẵn latin1; các charset khác cần thư viện ngoài.
      // Hợp đồng API hiện tại dùng UTF-8 → mọi charset lạ đều rơi về UTF-8.
      if (charset == 'iso-8859-1' || charset == 'latin1' || charset == 'latin-1') {
        return latin1.decode(response.bodyBytes);
      }
      return utf8.decode(response.bodyBytes);
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<String> _chat(String systemPrompt, String userPrompt) async {
    final Uri uri = Uri.parse('$_baseUrl/chat/completions');
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
    final String rawBody = decodeBody(response);
    final Map<String, Object?> body =
        jsonDecode(rawBody) as Map<String, Object?>;
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
      'Bạn là chuyên gia soạn thảo kiến thức. Hãy phân tích văn bản đầu vào và tách thành '
          'các đơn vị kiến thức độc lập, mỗi đơn vị đủ độ sâu để học và ghi nhớ. '
          'Trả về JSON: {"items":[{"title":"","content":"","details":""}]} '
          'Yêu cầu: tiêu đề rõ ràng, nội dung 150-300 từ, details là bối cảnh/ứng dụng/ví dụ.',
      'Tối đa $maxItems mục. Văn bản:\n${_clip(sourceText)}',
    );
    final Map<String, Object?> obj = _decodeObject(raw);
    final List<Object?> items =
        (obj['items'] as List<Object?>?) ?? const <Object?>[];
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
    final int maxQuestions = questionCount < 3
        ? 3
        : (questionCount > 5 ? 5 : questionCount);
    final String systemPrompt =
        '''Bạn là chuyên gia soạn thảo bài học chất lượng cao cho ứng dụng học tập chủ động. Hãy tạo bài học JSON tiếng Việt đầy đủ, có cấu trúc, độ dài 500-800 từ.

CẤU TRÚC BẮT BUỘC:
{
  "title": "Tiêu đề rõ ràng, hấp dẫn",
  "learningObjectives": ["Mục tiêu 1", "Mục tiêu 2", "Mục tiêu 3"],
  "introduction": "Mở đầu 100-150 từ: bối cảnh, tại sao quan trọng, người học sẽ đạt được gì",
  "concepts": [
    {"name": "Khái niệm 1", "explanation": "Giải thích chi tiết 150-200 từ"},
    {"name": "Khái niệm 2", "explanation": "Giải thích chi tiết 150-200 từ"}
  ],
  "sections": [
    {"heading": "Phần 1: Tên phần", "body": "Nội dung chi tiết 200-300 từ"}
  ],
  "keyPoints": ["Ý chính 1", "Ý chính 2", "Ý chính 3", "Ý chính 4", "Ý chính 5"],
  "examples": ["Ví dụ thực tế 1", "Ví dụ thực tế 2"],
  "commonMistakes": ["Sai lầm thường gặp 1", "Sai lầm thường gặp 2"],
  "summary": "Tóm tắt 3-5 ý quan trọng nhất, 100-150 từ",
  "questions": [
    {"question": "Câu hỏi 1", "answer": "Đáp án", "explanation": "Giải thích"}
  ],
  "sources": [{"title": "Nguồn", "url": "URL"}],
  "medical": false
}

NGUYÊN TẮC:
- Độ dài toàn bài: $wordMin-$wordMax từ
- Số câu hỏi: $maxQuestions (3-5)
- Không bịa nguồn - để mảng sources rỗng nếu không chắc chắn
- Nội dung y tế: medical=true + disclaimer
- Tiếng Việt tự nhiên, chính xác, không lặp ý''';

    final String userPrompt =
        'Lĩnh vực: $domain\nChủ đề: $topic\nChế độ: $mode';

    final String raw = await _chat(systemPrompt, userPrompt);
    return AiLessonDraft.fromMap(
      _decodeObject(raw),
      maxQuestions: maxQuestions,
    );
  }

  @override
  Future<List<AiTopicSuggestion>> suggestTopics({
    required String domain,
    int count = 20,
  }) async {
    final String raw = await _chat(
      'Generate a JSON object {"topics":[{"title":"","description":""}]} with distinct learning topics. '
          'Each title short, description one sentence.',
      'Domain: $domain\nCount: $count',
    );
    final Map<String, Object?> obj = _decodeObject(raw);
    final List<Object?> items =
        (obj['topics'] as List<Object?>?) ?? const <Object?>[];
    final List<AiTopicSuggestion> result = <AiTopicSuggestion>[];
    final Set<String> seen = <String>{};
    for (final Object? item in items) {
      if (item is! Map<String, Object?>) continue;
      try {
        final AiTopicSuggestion t = AiTopicSuggestion.fromMap(item);
        if (!seen.add(t.title.toLowerCase())) continue;
        result.add(t);
        if (result.length >= count) break;
      } on FormatException {
        continue;
      }
    }
    return result;
  }

  @override
  Future<List<String>> generateOutline({
    required String topic,
    required CourseLevel level,
    required int count,
  }) async {
    final String raw = await _chat(
      'Bạn là người thiết kế lộ trình học. Hãy lập đề cương gồm ĐÚNG $count mẩu '
          'kiến thức ngắn (mỗi mẩu đọc 1-3 phút) cho chủ đề được yêu cầu, sắp xếp '
          'từ dễ đến khó, mỗi mẩu một ý riêng biệt, không trùng lặp. '
          'Tiêu đề là một câu hỏi hoặc mệnh đề rõ ràng, dưới 90 ký tự. '
          'Độ khó: ${level.promptGuide} '
          'Trả về JSON: {"titles":["...","..."]}',
      'Chủ đề: $topic\nSố mẩu: $count',
    );
    final Map<String, Object?> obj = _decodeObject(raw);
    final Object? list = obj['titles'] ?? obj['items'] ?? obj['outline'];
    if (list is! List<Object?>) {
      throw const FormatException('Đề cương không đúng định dạng.');
    }
    final List<String> titles = cleanOutline(list, count);
    if (titles.isEmpty) {
      throw const FormatException('AI không trả về đề cương.');
    }
    return titles;
  }

  @override
  Future<AiBiteDraft> generateBite({
    required String topic,
    required CourseLevel level,
    required String title,
    required int index,
    required int total,
    List<String> previousTitles = const <String>[],
  }) async {
    final String previous = previousTitles.isEmpty
        ? 'Chưa có.'
        : previousTitles.take(40).join('; ');
    final String raw = await _chat(
      'Bạn là giáo viên soạn một mẩu kiến thức ngắn cho ứng dụng học mỗi ngày. '
          'Độ khó: ${level.promptGuide} '
          'Viết tiếng Việt tự nhiên, chính xác, KHÔNG lặp lại các mẩu đã học, '
          'không bịa số liệu. '
          'JSON: {"title":"","content":"150-250 từ, chia đoạn ngắn","summary":'
          '"2-3 câu nêu ý chính để đọc nhanh trong thông báo, dưới 280 ký tự",'
          '"example":"một ví dụ cụ thể","sources":["tên giáo trình hoặc từ khóa '
          'nên tra cứu, KHÔNG ghi đường link, để mảng rỗng nếu không chắc"],'
          '"question":"một câu hỏi tự kiểm tra","answer":"đáp án ngắn"}',
      'Chủ đề: $topic\nMẩu $index/$total: $title\nCác mẩu đã có: $previous',
    );
    return AiBiteDraft.fromMap(_decodeObject(raw));
  }
}

class AiProviderException implements Exception {
  const AiProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}
