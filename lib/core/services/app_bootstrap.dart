import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_services.dart';
import 'notification_service.dart';
import 'review_due_reminder.dart';

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
      // Đăng ký handler chạm thông báo TRƯỚC các bước lập lịch: lỗi lập lịch
      // không được làm mất điều hướng (cold start replay payload ở đây).
      services.notifications.setOnNotificationOpened((
        NotificationPayload payload,
      ) {
        pendingNotificationPayload = payload;
        onNotificationOpened?.call(payload);
      });
      if (services.prefs.notificationsEnabled) {
        await _guard('lập lịch nhắc ôn', () => _scheduleReminder(services));
      }
      if (services.prefs.knowledgeReminderEnabled) {
        await _guard(
          'lập lịch nhắc kiến thức',
          () => services.knowledgeReminders.sync(),
        );
      }
      // Đối soát kế hoạch học ở NỀN (không chặn khởi động UI): tạo đủ
      // nội dung còn thiếu, lên lịch bài mới. Idempotent nên chạy lại an toàn.
      unawaited(_syncStudyPlan(services));
      // Nút "Đã hiểu" trên thông báo khóa học (khi app đang chạy).
      services.notifications.setOnNotificationAction((
        String actionId,
        String payload,
      ) {
        final NotificationPayload parsed = NotificationPayload.parse(payload);
        if (actionId == courseActionMarkRead &&
            parsed.isCourse &&
            parsed.id != null) {
          unawaited(
            services.courseService.markRead(parsed.id!).then((_) {
              bumpDataVersion();
            }),
          );
        }
      });
      unawaited(_syncCourses(services));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Khởi tạo thông báo thất bại: $e\n$st');
      }
    }
  }

  Future<void> _guard(String what, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      if (kDebugMode) debugPrint('$what thất bại: $e\n$st');
    }
  }

  Future<void> _syncStudyPlan(AppServices services) async {
    try {
      await services.studyPlan.sync();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Đối soát kế hoạch học thất bại: $e\n$s');
      }
    }
  }

  Future<void> _syncCourses(AppServices services) async {
    try {
      await services.courseService.reconcile();
      await services.courseService.sync();
      bumpDataVersion();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Đối soát khóa học thất bại: $e\n$s');
      }
    }
  }

  /// Đồng bộ lại kế hoạch học khi mở app / resume / đổi cài đặt.
  Future<void> refreshStudyPlan() async {
    if (!isReady) return;
    await _syncStudyPlan(services);
    await _syncCourses(services);
  }

  Future<void> _scheduleReminder(AppServices services) async {
    // Không lên lịch khi biết chắc quyền bị chặn (Android 13+ từ chối
    // POST_NOTIFICATIONS): alarm sẽ chạy mà không hiển thị được, dễ gây hiểu
    // nhầm "đã bật mà không thấy". Trạng thái null (nền tảng không đọc được)
    // → vẫn lên lịch. Được cấp lại → lịch tự lập ở lần mở app sau hoặc khi
    // quay về màn Cài đặt thông báo (resumed).
    final bool? granted = await services.notifications
        .areNotificationsEnabled();
    if (granted == false) {
      if (kDebugMode) {
        debugPrint('Bỏ qua lên lịch nhắc ôn: quyền thông báo bị chặn.');
      }
      return;
    }
    // Nhắc ôn hằng ngày thay bằng thông báo gộp "Ôn kiến thức đến hạn" kèm
    // số lượng (xem ReviewDueReminder) — tránh hai thông báo trùng giờ.
    await services.notifications.cancelDailyReminder();
    await _guard('lập lịch ôn đến hạn', () => ReviewDueReminder.sync(services));
  }

  /// Đồng bộ lại lịch nhắc sau khi đổi giờ/tắt-bật trong cài đặt.
  Future<void> refreshReminderSchedule() async {
    if (!isReady) return;
    await _scheduleReminder(services);
  }

  Future<void> refreshKnowledgeReminderSchedule() async {
    if (!isReady) return;
    await services.knowledgeReminders.sync();
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
