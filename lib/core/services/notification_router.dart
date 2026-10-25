import 'package:flutter/material.dart';

import '../../core/services/app_services.dart';
import '../../core/services/notification_service.dart';
import '../../features/knowledge/knowledge_detail_screen.dart';
import '../../features/lessons/lesson_reader_screen.dart';
import '../../features/review/review_screen.dart';

/// Router tập trung cho tất cả điều hướng từ thông báo (push/local).
///
/// Xử lý payload theo loại (type) và định hướng đến màn hình phù hợp,
/// đồng thời biết app đang ở trạng thái nào (cold start / warm start) để
/// chọn thời điểm navigator an toàn.
class NotificationRouter {
  const NotificationRouter._();

  /// Xử lý payload thông báo và điều hướng đến màn hình tương ứng.
  ///
  /// - [payload]: payload đã parse từ thông báo.
  /// - [services]: AppServices để truy cập repository khi cần.
  /// - [context]: BuildContext để gọi Navigator (phải có scaffold navigator).
  /// - [isColdStart]: true nếu app vừa khởi động từ thông báo (terminated).
  ///   Khi true, điều hướng được gọi sau frame đầu tiên để tránh lỗi
  ///   navigator chưa sẵn sàng.
  static Future<void> handle({
    required BuildContext context,
    required AppServices services,
    required NotificationPayload payload,
    required bool isColdStart,
  }) async {
    final Future<void> Function() action;

    switch (payload.type) {
      case NotificationPayload.kindCard:
        action = () => _openCardReview(context, payload.cardId ?? payload.id!);
      case NotificationPayload.kindLesson:
        action = () => _openLesson(context, services, payload.lessonId ?? payload.id!);
      case NotificationPayload.kindQuick:
        action = () => _openKnowledge(context, payload.knowledgeItemId ?? payload.id!);
      case NotificationPayload.kindArticle:
      case NotificationPayload.kindQuickInfo:
        action = () => _openKnowledge(context, payload.id!);
      case NotificationPayload.kindReviewDue:
      case NotificationPayload.kindReview:
        action = () => _openReviewSession(context);
      default:
        action = () => _openReviewSession(context);
    }

    if (isColdStart) {
      // Đợi frame đầu tiên rồi mới push route (tránh navigator chưa ready).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) action();
      });
    } else {
      await action();
    }
  }

  static Future<void> _openCardReview(
    BuildContext context,
    String cardId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewScreen(targetCardId: cardId),
      ),
    );
  }

  static Future<void> _openLesson(
    BuildContext context,
    AppServices services,
    String lessonId,
  ) async {
    await services.studyPlan.markOpened(lessonId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonReaderScreen(lessonId: lessonId),
      ),
    );
  }

  static Future<void> _openKnowledge(
    BuildContext context,
    String itemId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KnowledgeDetailScreen(itemId: itemId),
      ),
    );
  }

  static Future<void> _openReviewSession(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReviewScreen()),
    );
  }
}
