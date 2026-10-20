import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/features/ai/ai_provider.dart';
import 'package:mind_keeper/features/ai/mock_ai_provider.dart';
import 'package:mind_keeper/features/discover/domain_catalog.dart';
import 'package:mind_keeper/features/discover/topic_seed_catalog.dart';

/// Ký tự thay thế Unicode — dấu hiệu nội dung đã bị hỏng encoding.
const String replacementChar = '�';

bool containsReplacementChar(String value) => value.contains(replacementChar);

void main() {
  group('GĐ22.1 — danh sách chủ đề AI tiếng Việt không bị hỏng', () {
    test('MockAIProvider trả 20 chủ đề đọc được bằng tiếng Việt', () async {
      final MockAIProvider provider = MockAIProvider(latency: Duration.zero);
      final List<AiTopicSuggestion> topics = await provider.suggestTopics(
        domain: 'Khoa học',
        count: 20,
      );

      expect(topics, hasLength(20));
      for (final AiTopicSuggestion topic in topics) {
        expect(
          containsReplacementChar(topic.title),
          isFalse,
          reason: 'Tiêu đề chủ đề chứa ký tự hỏng: ${topic.title}',
        );
        expect(
          containsReplacementChar(topic.description),
          isFalse,
          reason: 'Mô tả chủ đề chứa ký tự hỏng: ${topic.description}',
        );
        expect(topic.title.trim(), isNotEmpty);
        expect(topic.description.trim(), isNotEmpty);
      }
    });

    test('Tiêu đề chủ đề giữ nguyên dấu tiếng Việt', () async {
      final MockAIProvider provider = MockAIProvider(latency: Duration.zero);
      final List<AiTopicSuggestion> topics = await provider.suggestTopics(
        domain: 'Khoa học',
        count: 20,
      );
      final List<String> titles = topics
          .map((AiTopicSuggestion t) => t.title)
          .toList(growable: false);

      // Fixture tiếng Việt hợp lệ — phải xuất hiện nguyên vẹn.
      expect(
        titles,
        contains('Nguyên tử và phân tử'),
        reason: 'Tiêu đề tiếng Việt có dấu phải xuất hiện nguyên vẹn.',
      );
      expect(titles, contains('Thuyết tiến hóa'));
      expect(titles, contains('Vũ trụ và các thiên hà'));
    });

    test('Không có tiêu đề chủ đề trùng lặp', () async {
      final MockAIProvider provider = MockAIProvider(latency: Duration.zero);
      for (final LearningDomain domain in LearningDomains.all) {
        final List<AiTopicSuggestion> topics = await provider.suggestTopics(
          domain: domain.name,
          count: 20,
        );
        final Set<String> unique = topics
            .map((AiTopicSuggestion t) => t.title.trim().toLowerCase())
            .toSet();
        expect(
          unique.length,
          topics.length,
          reason: 'Lĩnh vực ${domain.name} có chủ đề trùng tên.',
        );
      }
    });

    test('Chủ đề khác nhau về nội dung, không chỉ khác số thứ tự', () async {
      final MockAIProvider provider = MockAIProvider(latency: Duration.zero);
      final List<AiTopicSuggestion> topics = await provider.suggestTopics(
        domain: 'Khoa học',
        count: 20,
      );
      final Set<String> descriptions = topics
          .map((AiTopicSuggestion t) => t.description.trim().toLowerCase())
          .toSet();
      expect(
        descriptions.length,
        topics.length,
        reason: 'Mô tả phải khác nhau, không được chỉ đổi số thứ tự.',
      );
    });

    test('Mọi lĩnh vực đều sinh đủ 20 chủ đề hợp lệ', () async {
      final MockAIProvider provider = MockAIProvider(latency: Duration.zero);
      for (final LearningDomain domain in LearningDomains.all) {
        final List<AiTopicSuggestion> topics = await provider.suggestTopics(
          domain: domain.name,
          count: 20,
        );
        expect(
          topics,
          hasLength(20),
          reason: 'Lĩnh vực ${domain.name} phải có đủ 20 chủ đề.',
        );
        for (final AiTopicSuggestion topic in topics) {
          expect(containsReplacementChar(topic.title), isFalse);
          expect(containsReplacementChar(topic.description), isFalse);
        }
      }
    });
  });

  group('GĐ22.1 — catalog chủ đề offline', () {
    test('Lĩnh vực có catalog sinh đủ 20 chủ đề khác nhau', () {
      final List<TopicSeed> seeds = TopicSeedCatalog.forDomain(
        'Khoa học',
        LearningDomains.byName('Khoa học')!.sampleTopics,
        count: 20,
      );
      expect(seeds, hasLength(20));
      final Set<String> titles = seeds
          .map((TopicSeed s) => s.title.toLowerCase())
          .toSet();
      expect(titles, hasLength(20));
    });

    test('Lĩnh vực chưa có catalog vẫn sinh đủ chủ đề hợp lệ', () {
      final List<TopicSeed> seeds = TopicSeedCatalog.forDomain(
        'Lĩnh vực mới',
        const <String>['Chủ đề A', 'Chủ đề B'],
        count: 20,
      );
      expect(seeds, hasLength(20));
      for (final TopicSeed seed in seeds) {
        expect(containsReplacementChar(seed.title), isFalse);
        expect(containsReplacementChar(seed.description), isFalse);
        expect(seed.title.trim(), isNotEmpty);
      }
    });
  });
}
