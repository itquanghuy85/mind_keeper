import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/app_bootstrap.dart';
import 'core/services/app_services.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intake.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final AppServices services = await AppBootstrap.instance.initialize();
  await FirebaseMessagingService.instance.initialize(
    services: services,
    onNotificationOpened: (NotificationPayload payload) {
      AppBootstrap.instance.pendingNotificationPayload = payload;
      AppBootstrap.instance.onNotificationOpened?.call(payload);
    },
  );
  // Nhận văn bản/liên kết từ share sheet (cold + warm start).
  await ShareIntake.instance.initialize();
  runApp(MindKeeperApp(services: services));
}
