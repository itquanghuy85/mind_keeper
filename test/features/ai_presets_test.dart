import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/features/ai/ai_presets.dart';

void main() {
  test('mỗi preset có Base URL https và model mặc định (trừ Tùy chỉnh)', () {
    for (final AiPreset p in AiPresets.all) {
      if (p.isCustom) continue;
      expect(p.baseUrl, startsWith('https://'), reason: p.id);
      expect(p.models, isNotEmpty, reason: p.id);
      expect(p.hasModel(p.defaultModel), isTrue);
    }
    expect(AiPresets.all.map((AiPreset p) => p.id).toSet().length,
        AiPresets.all.length);
  });

  test('match nhận diện nhà cung cấp từ Base URL đã lưu', () {
    expect(AiPresets.match('https://api.deepseek.com/v1/')?.id, 'deepseek');
    expect(AiPresets.match('https://api.openai.com/v1')?.id, 'openai');
    expect(AiPresets.match('http://127.0.0.1:8765/v1')?.isCustom, isTrue);
    expect(AiPresets.match(''), isNull);
  });
}
