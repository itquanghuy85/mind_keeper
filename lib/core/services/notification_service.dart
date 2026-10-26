import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'course_background.dart';

/// Payload mở khi người dùng chạm thông báo.
///
/// Định dạng mới (JSON, từ FCM / payload mới):
///   {"type":"article","id":"<knowledge_item_id>"}
///   {"type":"quick_info","id":"<knowledge_item_id>"}
///   {"type":"review_due"}
///   {"type":"card","id":"<card_id>"}
///   {"type":"lesson","id":"<lesson_id>"}
///   {"type":"review"}
///
/// Định dạng legacy (chuỗi, tương thích ngược):
///   card:<cardId> → mở đúng ReviewCard
///   lesson:<lessonId> → mở đúng bài học
///   quick:<knowledgeItemId> → mở đúng thông tin nhanh (GĐ17)
///   review → mở phiên ôn tập chung
class NotificationPayload {
  const NotificationPayload({
    this.type = kindReview,
    this.id,
    this.cardId,
    this.lessonId,
    this.knowledgeItemId,
  });

  /// Loại nội dung: article | quick_info | review_due | card | lesson | quick | review
  final String type;

  /// ID đối tượng (bài viết / thẻ / bài học) khi type có id kèm theo.
  final String? id;

  /// Trường tương thích ngược với định dạng legacy.
  final String? cardId;

  /// Trường tương thích ngược với định dạng legacy.
  final String? lessonId;

  /// Trường tương thích ngược với định dạng legacy.
  final String? knowledgeItemId;

  static const String kindCard = 'card';
  static const String kindReview = 'review';
  static const String kindLesson = 'lesson';
  static const String kindQuick = 'quick';
  static const String kindArticle = 'article';
  static const String kindQuickInfo = 'quick_info';
  static const String kindCourse = 'course';
  static const String kindReviewDue = 'review_due';

  /// Parse payload từ chuỗi. Thử JSON trước (định dạng mới), rồi legacy.
  static NotificationPayload parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const NotificationPayload(type: kindReview);
    }

    // Thử parse JSON (định dạng mới từ FCM).
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return fromJson(decoded);
      }
    } catch (_) {
      // Không phải JSON — tiếp tục định dạng legacy.
    }

    // Legacy: card:<id>, lesson:<id>, quick:<id>, review
    if (raw.startsWith('$kindCard:')) {
      final String id = raw.substring(kindCard.length + 1);
      if (id.isNotEmpty) {
        return NotificationPayload(type: kindCard, id: id, cardId: id);
      }
    }
    if (raw.startsWith('$kindLesson:')) {
      final String id = raw.substring(kindLesson.length + 1);
      if (id.isNotEmpty) {
        return NotificationPayload(type: kindLesson, id: id, lessonId: id);
      }
    }
    if (raw.startsWith('$kindCourse:')) {
      final String id = raw.substring(kindCourse.length + 1);
      if (id.isNotEmpty) {
        return NotificationPayload(type: kindCourse, id: id);
      }
    }
    if (raw.startsWith('$kindQuick:')) {
      final String id = raw.substring(kindQuick.length + 1);
      if (id.isNotEmpty) {
        return NotificationPayload(
          type: kindQuick,
          id: id,
          knowledgeItemId: id,
        );
      }
    }
    return const NotificationPayload(type: kindReview);
  }

  /// Parse từ Map JSON (vd. {"type":"article","id":"abc"}).
  static NotificationPayload fromJson(Map<String, dynamic> json) {
    final String type = (json['type'] ?? kindReview).toString();
    final String? id = json['id']?.toString();
    switch (type) {
      case kindArticle:
        return NotificationPayload(
          type: type,
          id: id,
          knowledgeItemId: id,
        );
      case kindQuickInfo:
        return NotificationPayload(
          type: type,
          id: id,
          knowledgeItemId: id,
        );
      case kindReviewDue:
        return const NotificationPayload(type: kindReviewDue);
      case kindCourse:
        return NotificationPayload(type: type, id: id);
      case kindCard:
        return NotificationPayload(type: type, id: id, cardId: id);
      case kindLesson:
        return NotificationPayload(type: type, id: id, lessonId: id);
      case kindQuick:
        return NotificationPayload(
          type: type,
          id: id,
          knowledgeItemId: id,
        );
      default:
        return NotificationPayload(type: type, id: id);
    }
  }

  /// Chuển payload sang chuỗi legacy (để lưu vào flutter_local_notifications).
  String toLegacyString() {
    switch (type) {
      case kindCard:
        return 'card:${id ?? ''}';
      case kindLesson:
        return 'lesson:${id ?? ''}';
      case kindCourse:
        return 'course:${id ?? ''}';
      case kindQuick:
        return 'quick:${id ?? ''}';
      case kindArticle:
        return 'quick:${id ?? ''}';
      case kindQuickInfo:
        return 'quick:${id ?? ''}';
      case kindReviewDue:
      case kindReview:
        return 'review';
      default:
        return 'review';
    }
  }

  /// Chuển payload sang chuỗi JSON (định dạng mới).
  String toJsonString() {
    return jsonEncode(<String, dynamic>{
      'type': type,
      if (id != null) 'id': id,
    });
  }

  /// Có phải payload hướng đến review session (ôn tập chung) không.
  bool get isReview => type == kindReview || type == kindReviewDue;

  /// Có phải payload hướng đến một mẩu của khóa học không.
  bool get isCourse => type == kindCourse;

  /// Có phải payload hướng đến một thẻ ôn cụ thể không.
  bool get isCard => type == kindCard;

  /// Có phải payload hướng đến kiến thức/bài viết không.
  bool get isKnowledge =>
      type == kindArticle ||
      type == kindQuickInfo ||
      type == kindLesson ||
      type == kindQuick;
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

  /// Lập lịch thông báo NỘI DUNG MỚI (GĐ17 — bài viết `lesson:<id>` /
  /// thông tin nhanh `quick:<id>`) vào thời điểm [at] với ID do caller chọn.
  ///
  /// KHÁC [scheduleKnowledgeReminder]: không ép prefix `lesson:` nên payload
  /// `quick:<id>` giữ nguyên để mở đúng mục kiến thức.
  Future<void> scheduleContentNotification({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  });

  /// Hủy một thông báo nội dung mới theo id (idempotent).
  Future<void> cancelContentNotification(int id);

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

  /// Lập lịch MỘT lần thông báo "Ôn kiến thức đến hạn" (gộp, kèm số lượng).
  /// [payload]: `card:<id>` khi chỉ có 1 mục, `review_due` khi nhiều mục.
  /// Dùng chung nhóm Android với thông báo từng thẻ để hệ thống gom lại.
  Future<void> scheduleReviewDue({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  });

  /// Hủy các thông báo "Ôn kiến thức đến hạn" đã lập/đang hiển thị (idempotent).
  Future<void> cancelReviewDue();

  void setOnNotificationOpened(void Function(NotificationPayload payload) cb);

  /// Lập lịch thông báo một mẩu khóa học: [bigText] hiển thị khi vuốt mở rộng
  /// (đọc nhanh không cần vào app), kèm nút "Đã hiểu" / "Đọc đầy đủ".
  Future<void> scheduleCourseNotification({
    required int id,
    required String title,
    required String body,
    required String bigText,
    String footer = '',
    required DateTime at,
    required String payload,
  });

  Future<void> cancelCourseNotification(int id);

  /// Đăng ký xử lý nút hành động trên thông báo (vd. `mark_read`).
  void setOnNotificationAction(
    void Function(String actionId, String payload) cb,
  );
}

/// ID nút hành động trên thông báo khóa học.
const String courseActionMarkRead = 'course_mark_read';
const String courseActionOpen = 'course_open';

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

  /// Lịch thông báo nội dung mới (GĐ17): id → thời điểm + payload đã dùng.
  final Map<int, DateTime> scheduledContent = <int, DateTime>{};
  final Map<int, String> contentPayloads = <int, String>{};
  final List<int> cancelledContent = <int>[];

  @override
  Future<void> scheduleContentNotification({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  }) async {
    if (!at.toUtc().isAfter(DateTime.now().toUtc())) return;
    scheduledContent[id] = at.toUtc();
    contentPayloads[id] = payload;
    calls.add('scheduleContentNotification:$id:$payload');
  }

  @override
  Future<void> cancelContentNotification(int id) async {
    scheduledContent.remove(id);
    contentPayloads.remove(id);
    cancelledContent.add(id);
    calls.add('cancelContentNotification:$id');
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

  /// Lịch "Ôn kiến thức đến hạn": id → (thời điểm, nội dung, payload).
  final Map<int, DateTime> scheduledReviewDue = <int, DateTime>{};
  final Map<int, String> reviewDuePayloads = <int, String>{};
  final Map<int, String> reviewDueBodies = <int, String>{};

  @override
  Future<void> scheduleReviewDue({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  }) async {
    if (!at.toUtc().isAfter(DateTime.now().toUtc())) return;
    scheduledReviewDue[id] = at.toUtc();
    reviewDuePayloads[id] = payload;
    reviewDueBodies[id] = body;
    calls.add('scheduleReviewDue:$id:$payload');
  }

  @override
  Future<void> cancelReviewDue() async {
    scheduledReviewDue.clear();
    reviewDuePayloads.clear();
    reviewDueBodies.clear();
    calls.add('cancelReviewDue');
  }

  /// Thông báo khóa học đã lập: id -> (giờ, payload, bigText).
  final Map<int, DateTime> scheduledCourse = <int, DateTime>{};
  final Map<int, String> coursePayloads = <int, String>{};
  final Map<int, String> courseBigTexts = <int, String>{};
  final Map<int, String> courseTitles = <int, String>{};
  final List<int> cancelledCourse = <int>[];
  void Function(String actionId, String payload)? onAction;

  @override
  Future<void> scheduleCourseNotification({
    required int id,
    required String title,
    required String body,
    required String bigText,
    String footer = '',
    required DateTime at,
    required String payload,
  }) async {
    if (!at.toUtc().isAfter(DateTime.now().toUtc())) return;
    scheduledCourse[id] = at.toUtc();
    coursePayloads[id] = payload;
    courseBigTexts[id] = bigText;
    courseTitles[id] = title;
    calls.add('scheduleCourseNotification:$id:$payload');
  }

  @override
  Future<void> cancelCourseNotification(int id) async {
    scheduledCourse.remove(id);
    coursePayloads.remove(id);
    courseBigTexts.remove(id);
    cancelledCourse.add(id);
    calls.add('cancelCourseNotification:$id');
  }

  @override
  void setOnNotificationAction(
    void Function(String actionId, String payload) cb,
  ) {
    onAction = cb;
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
  void Function(String actionId, String payload)? _onAction;
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

  /// Nhóm Android cho thông báo ôn tập (từng thẻ + gộp theo ngày) để hệ thống
  /// gom lại thay vì xếp chồng.
  static const String _reviewGroup = 'mind_keeper_review_due';

  static const AndroidNotificationDetails _reviewGroupDetails =
      AndroidNotificationDetails(
        'mind_keeper_review',
        'Nhắc ôn tập',
        channelDescription: 'Thông báo nhắc đến giờ ôn kiến thức',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: _reviewGroup,
      );

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    tz_data.initializeTimeZones();
    final DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _courseCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(courseActionMarkRead, 'Đã hiểu'),
            DarwinNotificationAction.plain(
              courseActionOpen,
              'Đọc đầy đủ',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    final InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveBackgroundNotificationResponse:
          courseNotificationBackground,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == courseActionMarkRead) {
          // Nút "Đã hiểu": ghi nhận, KHÔNG mở màn hình.
          _onAction?.call(courseActionMarkRead, response.payload ?? '');
          return;
        }
        final void Function(NotificationPayload payload)? cb = _onOpened;
        if (cb == null) {
          // Handler chưa đăng ký (đang khởi động) → giữ lại, replay sau.
          _launchPayload = response.payload ?? 'review';
          return;
        }
        cb(NotificationPayload.parse(response.payload));
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
        android: _reviewGroupDetails,
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

  /// Channel riêng cho thông báo bài mới — tách biệt với "Nhắc ôn tập" để
  /// người dùng phân biệt bài mới / ôn tập ở cài đặt hệ thống.
  static const AndroidNotificationDetails _articleDetails =
      AndroidNotificationDetails(
        'mind_keeper_new_content',
        'Bài học mới',
        channelDescription: 'Thông báo nội dung mới theo kế hoạch học hằng ngày',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: 'mind_keeper_group_article',
      );

  static const AndroidNotificationDetails _quickDetails =
      AndroidNotificationDetails(
        'mind_keeper_new_content',
        'Bài học mới',
        channelDescription: 'Thông báo nội dung mới theo kế hoạch học hằng ngày',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: 'mind_keeper_group_quick',
      );

  @override
  Future<void> scheduleContentNotification({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  }) async {
    final DateTime utc = at.toUtc();
    // Không lên lịch trong quá khứ — không bao giờ bịa thông báo giả.
    if (!utc.isAfter(DateTime.now().toUtc())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(utc, tz.local),
      notificationDetails: NotificationDetails(
        // Gom theo loại: bài viết với bài viết, thông tin nhanh với nhau.
        android: payload.startsWith('${NotificationPayload.kindQuick}:')
            ? _quickDetails
            : _articleDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancelContentNotification(int id) async {
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

  @override
  Future<void> scheduleReviewDue({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
  }) async {
    final DateTime utc = at.toUtc();
    if (!utc.isAfter(DateTime.now().toUtc())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(utc, tz.local),
      notificationDetails: const NotificationDetails(
        android: _reviewGroupDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancelReviewDue() async {
    for (int i = 0; i < reviewDueSlots; i++) {
      await _plugin.cancel(id: reviewDueBaseId + i);
    }
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

  static const String _courseCategory = 'mind_keeper_course_bite';

  @override
  Future<void> scheduleCourseNotification({
    required int id,
    required String title,
    required String body,
    required String bigText,
    String footer = '',
    required DateTime at,
    required String payload,
  }) async {
    final DateTime utc = at.toUtc();
    if (!utc.isAfter(DateTime.now().toUtc())) return;
    // Báo thức chính xác nếu hệ thống cho phép; không thì báo thức không chính
    // xác (Android có thể lùi tới ~1 giờ).
    final bool exact =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.canScheduleExactNotifications() ??
        false;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(utc, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'mind_keeper_course',
          'Khóa học',
          channelDescription:
              'Mẩu kiến thức theo khóa học, đọc nhanh ngay trên thông báo',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: 'mind_keeper_group_course',
          styleInformation: BigTextStyleInformation(
            bigText,
            contentTitle: title,
            summaryText: footer.isEmpty ? null : footer,
          ),
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              courseActionMarkRead,
              'Đã hiểu',
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              courseActionOpen,
              'Đọc đầy đủ',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: _courseCategory,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancelCourseNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  @override
  void setOnNotificationAction(
    void Function(String actionId, String payload) cb,
  ) {
    _onAction = cb;
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

/// ID thông báo "Ôn kiến thức đến hạn": [reviewDueBaseId] … +[reviewDueSlots]-1
/// (một ID mỗi ngày, lập trước vài ngày).
const int reviewDueBaseId = 1101;
const int reviewDueSlots = 3;

@visibleForTesting
int cardNotificationId(String cardId) => cardId.hashCode & 0x7fffffff;
