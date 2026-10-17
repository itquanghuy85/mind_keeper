import 'package:flutter/foundation.dart';

import 'app_services.dart';
import 'notification_service.dart';

/// Bootstrap toàn cục: khởi tạo DB, prefs, services trước khi runApp.
class AppBootstrap {
  AppBootstrap._();

  static final AppBootstrap instance = AppBootstrap._();

  AppServices? _services;

  AppServices get services {
    final AppServices? value = _services;
    if (value == null) {
      throw StateError('AppBootstrap chưa được initialize().');
    }
    return value;
  }

  bool get isReady => _services != null;

  Future<AppServices> initialize({AppServices? override}) async {
    if (override != null) {
      _services = override;
      return override;
    }
    if (_services != null) return _services!;
    final AppServices services = await AppServices.initialize();
    _services = services;
    await _setupNotifications(services);
    return services;
  }

  Future<void> _setupNotifications(AppServices services) async {
    try {
      final bool ok = await services.notifications.initialize();
      if (!ok) return;
      if (services.prefs.notificationsEnabled) {
        await _scheduleReminder(services);
      }
      services.notifications.setOnNotificationOpened(
        (NotificationPayload payload) {
          pendingNotificationPayload = payload;
          onNotificationOpened?.call(payload);
        },
      );
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Khởi tạo thông báo thất bại: $e\n$s');
      }
    }
  }

  Future<void> _scheduleReminder(AppServices services) async {
    // Không lên lịch khi biết chắc quyền bị chặn (Android 13+ từ chối
    // POST_NOTIFICATIONS): alarm sẽ chạy mà không hiển thị được, dễ gây hiểu
    // nhầm "đã bật mà không thấy". Trạng thái null (nền tảng không đọc được)
    // → vẫn lên lịch. Được cấp lại → lịch tự lập ở lần mở app sau hoặc khi
    // quay về màn Cài đặt thông báo (resumed).
    final bool? granted = await services.notifications.areNotificationsEnabled();
    if (granted == false) {
      if (kDebugMode) {
        debugPrint('Bỏ qua lên lịch nhắc ôn: quyền thông báo bị chặn.');
      }
      return;
    }
    final String body = services.prefs.dailyGoal > 0
        ? 'Còn ${services.prefs.dailyGoal} mục tiêu học hôm nay. Chạm để kiểm tra kiến thức.'
        : 'Chạm để kiểm tra kiến thức bạn cần ôn.';
    await services.notifications.scheduleDailyReminder(
      title: 'Đến giờ ôn tập',
      body: body,
      hour: services.prefs.reminderHour,
      minute: services.prefs.reminderMinute,
    );
  }

  /// Đồng bộ lại lịch nhắc sau khi đổi giờ/tắt-bật trong cài đặt.
  Future<void> refreshReminderSchedule() async {
    if (!isReady) return;
    await _scheduleReminder(services);
  }

  /// Payload thông báo chờ xử lý khi app vừa khởi động từ notification.
  NotificationPayload? pendingNotificationPayload;

  void Function(NotificationPayload payload)? onNotificationOpened;

  /// Nâng giá trị khi dữ liệu chủ đề/kiến thức/thẻ đổi từ bất kỳ màn hình nào
  /// (shell lắng nghe để reload Today/Topics tab).
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  void bumpDataVersion() => dataVersion.value += 1;

  @visibleForTesting
  void resetForTest() {
    _services = null;
    pendingNotificationPayload = null;
    onNotificationOpened = null;
    dataVersion.value = 0;
  }
}
