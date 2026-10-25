import '../../data/models/review_card.dart';
import 'app_services.dart';
import 'notification_service.dart';

/// Thông báo "Ôn kiến thức đến hạn" hằng ngày, kèm số lượng.
///
/// Cách làm đơn giản, không cần WorkManager/service nền: mỗi lần app mở /
/// resume / đổi cài đặt, lập lịch MỘT lần cho [reviewDueSlots] ngày tới vào
/// giờ nhắc của người dùng. Số lượng tính sẵn theo `due_at <= giờ nhắc` —
/// chính xác nếu người dùng không ôn thêm (và nếu có ôn thì app mở nên lịch
/// được tính lại). Ngày không có mục đến hạn thì không lập → không spam.
class ReviewDueReminder {
  const ReviewDueReminder._();

  static const String title = 'Ôn kiến thức đến hạn';

  static Future<void> sync(AppServices services, {DateTime? now}) async {
    final NotificationService notifications = services.notifications;
    // Hủy cả thông báo đang hiển thị của ngày trước → không chồng chất.
    await notifications.cancelReviewDue();

    final DateTime base = now ?? DateTime.now();
    for (int i = 0; i < reviewDueSlots; i++) {
      final DateTime at = DateTime(
        base.year,
        base.month,
        base.day + i,
        services.prefs.reminderHour,
        services.prefs.reminderMinute,
      );
      if (!at.isAfter(base)) continue;
      final int count = await services.cards.countDue(now: at);
      if (count <= 0) continue;
      String payload = NotificationPayload.kindReviewDue;
      if (count == 1) {
        final List<ReviewCard> one = await services.cards.listDue(
          now: at,
          limit: 1,
        );
        if (one.isNotEmpty) {
          payload = '${NotificationPayload.kindCard}:${one.first.id}';
        }
      }
      await notifications.scheduleReviewDue(
        id: reviewDueBaseId + i,
        title: title,
        body: count == 1
            ? 'Bạn có 1 kiến thức đến hạn. Chạm để ôn ngay.'
            : 'Bạn có $count kiến thức đến hạn. Chạm để ôn ngay.',
        at: at,
        payload: payload,
      );
    }
  }
}
