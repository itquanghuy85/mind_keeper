/// Nhà cung cấp AI dựng sẵn: người dùng chỉ chọn nhà cung cấp + model rồi dán
/// API key, không phải gõ Base URL hay tên model.
library;

class AiModelOption {
  const AiModelOption(this.id, this.label);

  final String id;
  final String label;
}

class AiPreset {
  const AiPreset({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.models,
    required this.keyHint,
    this.keyGuide = '',
  });

  /// Id đặc biệt: người dùng tự nhập Base URL/model (vd. proxy riêng).
  static const String customId = 'custom';

  final String id;
  final String name;
  final String baseUrl;
  final List<AiModelOption> models;

  /// Gợi ý định dạng key (vd. `sk-...`).
  final String keyHint;

  /// Nơi lấy key, hiển thị dưới ô dán key.
  final String keyGuide;

  bool get isCustom => id == customId;

  String get defaultModel => models.isEmpty ? '' : models.first.id;

  bool hasModel(String model) =>
      models.any((AiModelOption m) => m.id == model);
}

abstract final class AiPresets {
  static const List<AiPreset> all = <AiPreset>[
    AiPreset(
      id: 'openai',
      name: 'OpenAI (ChatGPT)',
      baseUrl: 'https://api.openai.com/v1',
      keyHint: 'sk-...',
      keyGuide: 'Lấy key tại platform.openai.com → API keys.',
      models: <AiModelOption>[
        AiModelOption('gpt-4o-mini', 'GPT-4o mini · nhanh, rẻ'),
        AiModelOption('gpt-4.1-mini', 'GPT-4.1 mini · cân bằng'),
        AiModelOption('gpt-4o', 'GPT-4o · chất lượng cao'),
      ],
    ),
    AiPreset(
      id: 'gemini',
      name: 'Google Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      keyHint: 'AIza...',
      keyGuide: 'Lấy key miễn phí tại aistudio.google.com → Get API key.',
      models: <AiModelOption>[
        AiModelOption('gemini-2.5-flash', 'Gemini 2.5 Flash · nhanh'),
        AiModelOption('gemini-2.5-pro', 'Gemini 2.5 Pro · chất lượng cao'),
      ],
    ),
    AiPreset(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      keyHint: 'sk-...',
      keyGuide: 'Lấy key tại platform.deepseek.com → API keys.',
      models: <AiModelOption>[
        AiModelOption('deepseek-chat', 'DeepSeek Chat · rẻ'),
        AiModelOption('deepseek-reasoner', 'DeepSeek Reasoner · suy luận'),
      ],
    ),
    AiPreset(
      id: 'groq',
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      keyHint: 'gsk_...',
      keyGuide: 'Lấy key tại console.groq.com → API Keys.',
      models: <AiModelOption>[
        AiModelOption('llama-3.3-70b-versatile', 'Llama 3.3 70B'),
        AiModelOption('llama-3.1-8b-instant', 'Llama 3.1 8B · rất nhanh'),
      ],
    ),
    AiPreset(
      id: 'openrouter',
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      keyHint: 'sk-or-...',
      keyGuide: 'Lấy key tại openrouter.ai → Keys. Một key dùng nhiều model.',
      models: <AiModelOption>[
        AiModelOption('openai/gpt-4o-mini', 'GPT-4o mini'),
        AiModelOption('anthropic/claude-3.5-haiku', 'Claude 3.5 Haiku'),
        AiModelOption('google/gemini-2.5-flash', 'Gemini 2.5 Flash'),
        AiModelOption('deepseek/deepseek-chat', 'DeepSeek Chat'),
      ],
    ),
    AiPreset(
      id: 'mistral',
      name: 'Mistral',
      baseUrl: 'https://api.mistral.ai/v1',
      keyHint: 'API key',
      keyGuide: 'Lấy key tại console.mistral.ai → API keys.',
      models: <AiModelOption>[
        AiModelOption('mistral-small-latest', 'Mistral Small · nhanh'),
        AiModelOption('mistral-large-latest', 'Mistral Large · chất lượng cao'),
      ],
    ),
    AiPreset(
      id: AiPreset.customId,
      name: 'Tùy chỉnh (nâng cao)',
      baseUrl: '',
      keyHint: 'sk-...',
      models: <AiModelOption>[],
    ),
  ];

  static AiPreset byId(String id) =>
      all.firstWhere((AiPreset p) => p.id == id, orElse: () => all.last);

  /// Nhận diện preset từ Base URL đã lưu; không khớp → Tùy chỉnh.
  /// Chưa lưu gì (URL rỗng) → null để hộp thoại chọn mặc định.
  static AiPreset? match(String baseUrl) {
    final String url = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (url.isEmpty) return null;
    for (final AiPreset p in all) {
      if (!p.isCustom && p.baseUrl == url) return p;
    }
    return byId(AiPreset.customId);
  }
}
