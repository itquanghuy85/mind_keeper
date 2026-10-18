import 'dart:math';

import '../../core/services/preferences_service.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/topic_repository.dart';
import 'discovery_catalog.dart';

/// Một đề xuất khám phá trong ngày (chưa lưu vào chủ đề của người dùng).
class DiscoverySuggestion {
  const DiscoverySuggestion({
    required this.entry,
    required this.isSaved,
    required this.isStudied,
  });

  final DiscoveryEntry entry;
  final bool isSaved;
  final bool isStudied;
}

/// Service khám phá: chọn 1–3 chủ đề mới mỗi ngày từ catalog offline,
/// tránh lặp theo lịch sử đã lưu, hỗ trợ ẩn/yêu thích lĩnh vực.
class DiscoveryService {
  DiscoveryService({
    required this.topics,
    required this.knowledge,
    required this.cards,
    required this.prefs,
    Random? random,
  }) : _random = random ?? Random();

  final TopicRepository topics;
  final KnowledgeRepository knowledge;
  final ReviewRepository cards;
  final PreferencesService prefs;
  final Random _random;

  String _dayKey(DateTime now) {
    final DateTime local = now.toLocal();
    return '${local.year}-${local.month}-${local.day}';
  }

  /// Chọn gợi ý cho hôm nay: ưu tiên lĩnh vực yêu thích, loại lĩnh vực bị ẩn,
  /// tránh các entry đã lưu (id trong tên chủ đề dạng catalog entryId).
  Future<List<DiscoverySuggestion>> suggestionsForToday({
    DateTime? now,
    int? count,
  }) async {
    final DateTime moment = now ?? DateTime.now();
    final int wanted = count ?? prefs.newTopicsPerDay.clamp(1, 3);
    if (wanted == 0) return const <DiscoverySuggestion>[];

    final List<String> hidden = prefs.hiddenCategories;
    final List<String> favorites = prefs.favoriteCategories;

    final List<DiscoveryEntry> pool = DiscoveryCatalog.entries
        .where((DiscoveryEntry e) => !hidden.contains(e.category))
        .toList(growable: true);
    if (pool.isEmpty) return const <DiscoverySuggestion>[];

    final List<Topic> existing = await topics.list(
      activeOnly: false,
      limit: 500,
    );
    final Set<String> savedEntryIds = <String>{};
    for (final Topic t in existing) {
      if (t.description.startsWith('catalog:')) {
        savedEntryIds.add(t.description.substring('catalog:'.length));
      }
    }

    final String day = _dayKey(moment);
    final List<DiscoveryEntry> fresh = pool
        .where((DiscoveryEntry e) => !savedEntryIds.contains(e.id))
        .toList();
    final List<DiscoveryEntry> source = fresh.isNotEmpty
        ? fresh
        : pool.toList();

    // Ưu tiên lĩnh vực yêu thích.
    final List<DiscoveryEntry> preferred = source
        .where((DiscoveryEntry e) => favorites.contains(e.category))
        .toList();
    final List<DiscoveryEntry> rest = source
        .where((DiscoveryEntry e) => !favorites.contains(e.category))
        .toList();
    rest.shuffle(_random);
    preferred.shuffle(_random);
    final List<DiscoveryEntry> ordered = <DiscoveryEntry>[
      ...preferred,
      ...rest,
    ];

    final int take = wanted.clamp(1, ordered.length);
    // Deterministic theo ngày: xoay vòng nhẹ dựa trên hash ngày.
    final int shift = day.hashCode % ordered.length;
    final List<DiscoveryEntry> rotated = <DiscoveryEntry>[
      ...ordered.sublist(shift),
      ...ordered.sublist(0, shift),
    ];

    return rotated
        .take(take)
        .map(
          (DiscoveryEntry e) => DiscoverySuggestion(
            entry: e,
            isSaved: savedEntryIds.contains(e.id),
            isStudied: false,
          ),
        )
        .toList(growable: false);
  }

  /// Lưu chủ đề khám phá + kiến thức + thẻ ôn (lịch FSRS due ngay).
  Future<Topic> saveEntry(DiscoveryEntry entry, {DateTime? now}) async {
    final DateTime moment = (now ?? DateTime.now()).toUtc();
    final Topic topic = await topics.create(
      name: entry.title,
      description: 'catalog:${entry.id}',
      category: entry.category,
      origin: TopicOrigin.discovered,
      now: moment,
    );
    for (final DiscoveryKnowledge item in entry.items) {
      final KnowledgeItem created = await knowledge.create(
        topicId: topic.id,
        title: item.title,
        content: item.content,
        origin: KnowledgeOrigin.userConfirmed,
        now: moment,
      );
      if (item.question.isNotEmpty && item.answer.isNotEmpty) {
        await cards.create(
          knowledgeItemId: created.id,
          question: item.question,
          answer: item.answer,
          dueAt: moment,
          now: moment,
        );
      } else {
        await cards.create(
          knowledgeItemId: created.id,
          question: '${item.title} — nhớ được điều gì?',
          answer: item.content,
          dueAt: moment,
          now: moment,
        );
      }
    }
    return topic;
  }

  /// Đánh dấu entry đã học (lưu và nhớ ID theo ngày để tránh gợi ý lặp).
  String suggestionSeed(DateTime now) => _dayKey(now);

  Future<int> countSavedEntries() async {
    final List<Topic> all = await topics.list(activeOnly: false, limit: 1000);
    return all.where((Topic t) => t.description.startsWith('catalog:')).length;
  }

  static String newIdForEntry() => newId('tp');
}
