import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_services.dart';
import 'notification_router.dart';
import 'notification_service.dart';

/// Dịch vụ Firebase Cloud Messaging (FCM) cho Mind Keeper.
///
/// Nhiệm vụ:
/// - Khởi tạo Firebase + FCM.
/// - Lắng nghe `onMessageOpenedApp`: người dùng chạm thông báo khi app đang
///   background → điều hướng theo payload.
/// - Đọc `getInitialMessage`: app khởi động từ terminated state → xử lý payload
///   cold-start sau khi navigator sẵn sàng.
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  FirebaseMessaging? _messaging;
  bool _initialized = false;
  bool _available = false;

  /// Khởi tạo Firebase + FCM, đăng ký các listener.
  /// Phải gọi sau khi [AppBootstrap.instance.initialize()] hoàn tất (để có
  /// AppServices và navigator context).
  Future<void> initialize({
    required AppServices services,
    required void Function(NotificationPayload payload) onNotificationOpened,
  }) async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase.initializeApp thất bại (thiếu google-services.json?): $e');
      return;
    }
    _available = true;
    _messaging = FirebaseMessaging.instance;

    // Quyền thông báo (iOS / Android).
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token FCM (để gửi push từ server).
    final String? token = await _messaging!.getToken();
    if (kDebugMode && token != null) {
      debugPrint('FCM Token: $token');
    }

    // Foreground message (app đang mở): chỉ log, không can thiệp UI.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('FCM onMessage: ${message.notification?.title} / '
            '${message.notification?.body}');
      }
    });

    // Background message: người dùng chạm thông báo khi app đang background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final NotificationPayload payload = _parse(message);
      onNotificationOpened(payload);
    });

    // Cold start: app bị terminate, người dùng chạm thông báo để mở app.
    final RemoteMessage? initial = await _messaging!.getInitialMessage();
    if (initial != null) {
      final NotificationPayload payload = _parse(initial);
      onNotificationOpened(payload);
    }
  }

  /// Parse payload từ RemoteMessage (data hoặc notification).
  NotificationPayload _parse(RemoteMessage message) {
    // Ưu tiên data payload (JSON).
    if (message.data.isNotEmpty) {
      final dynamic type = message.data['type'];
      final dynamic id = message.data['id'];
      if (type != null) {
        return NotificationPayload.fromJson(<String, dynamic>{
          'type': type,
          if (id != null) 'id': id,
        });
      }
    }
    // Fallback: thử parse từ notification body / title nếu có.
    return const NotificationPayload(type: 'review');
  }
}
