import '../models/knowledge_item.dart';
import '../models/review_card.dart';
import '../models/topic.dart';

/// Dữ liệu thẻ ôn kèm ngữ cảnh kiến thức/chủ đề cho phiên ôn và thông báo.
class DueReviewItem {
  const DueReviewItem({
    required this.card,
    required this.knowledge,
    required this.topic,
  });

  final ReviewCard card;
  final KnowledgeItem knowledge;
  final Topic topic;

  factory DueReviewItem.fromRows({
    required Map<String, Object?> cardRow,
    required Map<String, Object?> knowledgeRow,
    required Map<String, Object?> topicRow,
  }) {
    return DueReviewItem(
      card: ReviewCard.fromMap(cardRow),
      knowledge: KnowledgeItem.fromMap(knowledgeRow),
      topic: Topic.fromMap(topicRow),
    );
  }

  String get shortLabel => topic.name.isEmpty ? knowledge.title : topic.name;
}
