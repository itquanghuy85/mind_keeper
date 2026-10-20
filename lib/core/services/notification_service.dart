import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Payload mở khi người dùng chạm thông báo.
/// - `card:<cardId>` → mở đúng ReviewCard
/// - `review` → mở phiên ôn tập chung
class NotificationPayload {
  const NotificationPayload._({this.cardId, this.lessonId, this.kind = kindReview});

  final String? cardId;
  final String? lessonId;
  final String kind;

  static const String kindCard = 'card';
  static const String kindReview = 'review';
  static const String kindLesson = 'lesson';

  static NotificationPayload parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const NotificationPayload._(kind: kindReview);
    }
    if (raw.startsWith('$kindCard:')) {
      final String id = raw.substring(kindCard.length + 1);
      // Payload thiếu cardId (vd. 'card:') là không hợp lệ — bỏ qua review
      // thay vì mở màn hình sai.
      if (id.isNotEmpty) {
        return NotificationPayload._(kind: kindCard, cardId: id);
      }
    }
    if (raw.startsWith('$kindLesson:')) {
      final String id = raw.substring(kindLesson.length + 1);
      if (id.isNotEmpty) {
        return NotificationPayload._(kind: kindLesson, lessonId: id);
      }
    }
    return const NotificationPayload._(kind: kindReview);
  }
}

/// Interface để test không cần plugin thật.
abstract class NotificationService {
  Future<bool> initialize();
  Future<bool> requestPermissions();

  /// Kiểm tra trạng thái HIỆN TẠI của quyền thông báo (không prompt).
  /// - `true`: thông báo được phép hiển thị.
  /// - `false`: hệ thống chặn — cần người dùng mở Cài đặt để bật.
  /// - `null`: nền tảng không có API đọc trạng thái (vd. iOS) — không đoán.
  Future<bool?> areNotificationsEnabled();

  /// Mở màn hình cài đặt thông báo của app trong Cài đặt hệ thống.
  /// Trả `true` nếu mở được. Không tự bật quyền thay người dùng.
  Future<bool> openNotificationSettings();

  Future<void> cancelAll();
  Future<void> cancelDailyReminder();
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String payload,
  });
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String payload,
  });
  Future<void> showCardDue({
    required String cardId,
    required String title,
    required String body,
  });

  /// Lập lịch thông báo MỘT LẦN vào thời điểm [at] với payload `card:<cardId>`
  /// (mở đúng câu hỏi khi người dùng chạm). Bỏ qua nếu [at] đã qua.
  Future<void> scheduleCardDueAt({
    required String cardId,
    required String title,
    required String body,
    required DateTime at,
  });

  /// Hủy lịch thông báo của thẻ (idempotent).
  Future<void> cancelCardNotification(String cardId);

  /// Lập lịch thông báo kiến thức theo chủ đề (payload `lesson:<id>`).
  Future<void> scheduleKnowledgeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String payload = 'lesson:',
  });

  /// Hủy một thông báo kiến thức theo id.
  Future<void> cancelKnowledgeReminder(int id);

  /// Lập lịch nhắc đọc kiến thức theo ngày/lịch tuần.
  /// [days] là danh sách ngày trong tuần (1=Thứ 2, ..., 7=Chủ Nhật).
  /// [frequency] = 1: hàng ngày, 2: cách ngày, 3: 3 ngày/lần, ...
  Future<void> scheduleKnowledgeReadingReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> days,
    required int frequency,
    String payload = 'knowledge_reading',
  });

  /// Hủy lịch nhắc đọc kiến thức.
  Future<void> cancelKnowledgeReadingReminder();

  void setOnNotificationOpened(void Function(NotificationPayload payload) cb);
}

/// Fake dùng cho widget/unit test: ghi lại lịch gọi, không gọi plugin.
class FakeNotificationService implements NotificationService {
  final List<String> calls = <String>[];
  final List<int> shownIds = <int>[];

  /// cardId → thời điểm thông báo đến giờ ôn đã lập (assert trong test).
  final Map<String, DateTime> scheduledCards = <String, DateTime>{};
  final List<String> cancelledCards = <String>[];
  void Function(NotificationPayload payload)? onOpened;
  bool permissionsGranted = true;

  /// Trạng thái giả lập cho [areNotificationsEnabled] (mặc định: cho phép;
  /// `null` = nền tảng không đọc được).
  bool? notificationsEnabledStatus = true;

  /// Ghi nhận lần gọi [openNotificationSettings] (assert trong test).
  bool openSettingsCalled = false;

  /// Giả lập payload khi app được mở từ thông báo (test cold start).
  String? pendingLaunchPayload;

  @override
  Future<bool> initialize() async {
    calls.add('initialize');
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    calls.add('requestPermissions');
    return permissionsGranted;
  }

  @override
  Future<bool?> areNotificationsEnabled() async {
    calls.add('areNotificationsEnabled');
    return notificationsEnabledStatus;
  }

  @override
  Future<bool> openNotificationSettings() async {
    calls.add('openNotificationSettings');
    openSettingsCalled = true;
    return true;
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
  }

  @override
  Future<void> cancelDailyReminder() async {
    calls.add('cancelDailyReminder');
  }

  @override
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String payload = 'review',
  }) async {
    calls.add('scheduleDailyReminder:$hour:$minute:$payload');
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String payload = 'review',
  }) async {
    calls.add('showNow:$id:$payload');
    shownIds.add(id);
  }

  @override
  Future<void> showCardDue({
    required String cardId,
    required String title,
    required String body,
  }) async {
    calls.add('showCardDue:$cardId');
  }

  @override
  Future<void> scheduleCardDueAt({
    required String cardId,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (!at.toUtc().isAfter(DateTime.now().toUtc())) return;
    scheduledCards[cardId] = at.toUtc();
    calls.add('scheduleCardDueAt:$cardId');
  }

  @override
  Future<void> cancelCardNotification(String cardId) async {
    cancelledCards.add(cardId);
    scheduledCards.remove(cardId);
    calls.add('cancelCard:$cardId');
  }

  final Map<int, DateTime> scheduledKnowledgeReminders = <int, DateTime>{};

  @override
  Future<void> scheduleKnowledgeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String payload = 'lesson:',
  }) async {
    scheduledKnowledgeReminders[id] = at.toUtc();
    calls.add('scheduleKnowledgeReminder:$id:$payload');
  }

  @override
  Future<void> cancelKnowledgeReminder(int id) async {
    scheduledKnowledgeReminders.remove(id);
    calls.add('cancelKnowledgeReminder:$id');
  }

  @override
  Future<void> scheduleKnowledgeReadingReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> days,
    required int frequency,
    String payload = 'knowledge_reading',
  }) async {
    calls.add(
      'scheduleKnowledgeReadingReminder:$hour:$minute:$days:$frequency:$payload',
    );
  }

  @override
  Future<void> cancelKnowledgeReadingReminder() async {
    calls.add('cancelKnowledgeReadingReminder');
  }

  @override
  void setOnNotificationOpened(void Function(NotificationPayload payload) cb) {
    onOpened = cb;
    final String? launch = pendingLaunchPayload;
    if (launch != null) {
      pendingLaunchPayload = null;
      cb(NotificationPayload.parse(launch));
    }
  }
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  void Function(NotificationPayload payload)? _onOpened;
  bool _initialized = false;

  /// Payload từ lần mở app bằng thông báo (cold start) — replay khi
  /// setOnNotificationOpened được đăng ký.
  String? _launchPayload;

  static const int _dailyReminderId = 1001;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'mind_keeper_review',
        'Nhắc ôn tập',
        channelDescription: 'Thông báo nhắc đến giờ ôn kiến thức',
        importance: Importance.high,
        priority: Priority.high,
      );

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    tz_data.initializeTimeZones();
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onOpened?.call(NotificationPayload.parse(response.payload));
      },
    );
    _initialized = true;
    try {
      final NotificationAppLaunchDetails? details = await _plugin
          .getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        _launchPayload = details.notificationResponse?.payload;
      }
    } catch (_) {
      // Plattform chưa sẵn sàng — bỏ qua, không chặn khởi động.
    }
    return true;
  }

  /// Xin quyền hiển thị thông báo và trả KẾT QUẢ THẬT từ hệ thống.
  ///
  /// - Android 13+ (API 33): gọi `requestNotificationsPermission()` của
  ///   flutter_local_notifications v22 → hộp thoại POST_NOTIFICATIONS;
  ///   Android < 13: no-op, trả `true` (không có quyền runtime).
  /// - iOS: `requestPermissions(alert/badge/sound)`.
  /// - Không tuyên bố đã có quyền khi API lỗi: trả `false`.
  @override
  Future<bool> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final bool? granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final IOSFlutterLocalNotificationsPlugin? ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final bool? granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      // Desktop/web không có quyền runtime cho thông báo cục bộ.
      return true;
    } catch (_) {
      // Plugin chưa sẵn sàng (môi trường test / chưa đăng ký) — coi như
      // CHƯA được cấp để UI không hiển thị trạng thái sai.
      return false;
    }
  }

  @override
  Future<bool?> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled();
      }
      // iOS/macOS: plugin không cung cấp API đọc trạng thái → trung thực
      // trả null (không đoán "đã có quyền").
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openNotificationSettings() async {
    try {
      final bool? ok = await _plugin.openAppNotificationSettings();
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
  }

  @override
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String payload = 'review',
  }) async {
    final tz.TZDateTime next = _nextInstanceOfTime(hour, minute);
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: title,
      body: body,
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String payload = 'review',
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> showCardDue({
    required String cardId,
    required String title,
    required String body,
  }) async {
    final int id = cardId.hashCode & 0x7fffffff;
    await showNow(
      id: id,
      title: title,
      body: body,
      payload: '${NotificationPayload.kindCard}:$cardId',
    );
  }

  @override
  Future<void> scheduleCardDueAt({
    required String cardId,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    final DateTime utc = at.toUtc();
    if (!utc.isAfter(DateTime.now().toUtc())) return;
    await _plugin.zonedSchedule(
      id: cardNotificationId(cardId),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(utc, tz.local),
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '${NotificationPayload.kindCard}:$cardId',
    );
  }

  @override
  Future<void> cancelCardNotification(String cardId) async {
    await _plugin.cancel(id: cardNotificationId(cardId));
  }

  @override
  Future<void> scheduleKnowledgeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String payload = 'lesson:',
  }) async {
    final DateTime utc = at.toUtc();
    if (!utc.isAfter(DateTime.now().toUtc())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(utc, tz.local),
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload.startsWith('lesson:') ? payload : 'lesson:$payload',
    );
  }

  @override
  Future<void> cancelKnowledgeReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> scheduleKnowledgeReadingReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> days,
    required int frequency,
    String payload = 'knowledge_reading',
  }) async {
    // Hủy lịch cũ trước
    await _plugin.cancel(id: _knowledgeReadingReminderId);

    // Lập lịch cho từng ngày trong tuần
    for (final int day in days) {
      if (day < 1 || day > 7) continue;

      final tz.TZDateTime next = _nextInstanceOfWeekday(day, hour, minute);
      await _plugin.zonedSchedule(
        id: _knowledgeReadingReminderId + day,
        title: title,
        body: body,
        scheduledDate: next,
        notificationDetails: const NotificationDetails(
          android: _androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '$payload:day=$day',
      );
    }
  }

  @override
  Future<void> cancelKnowledgeReadingReminder() async {
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(id: _knowledgeReadingReminderId + day);
    }
    await _plugin.cancel(id: _knowledgeReadingReminderId);
  }

  static const int _knowledgeReadingReminderId = 1002;

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // weekday: 1=Monday, 7=Sunday
    int daysToAdd = weekday - now.weekday;
    if (daysToAdd < 0) daysToAdd += 7;
    if (daysToAdd == 0) {
      final tz.TZDateTime today = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (today.isBefore(now)) daysToAdd = 7;
    }
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    scheduled = scheduled.add(Duration(days: daysToAdd));
    return scheduled;
  }

  @override
  void setOnNotificationOpened(void Function(NotificationPayload payload) cb) {
    _onOpened = cb;
    final String? launch = _launchPayload;
    if (launch != null) {
      _launchPayload = null;
      cb(NotificationPayload.parse(launch));
    }
  }
}

@visibleForTesting
int cardNotificationId(String cardId) => cardId.hashCode & 0x7fffffff;
