import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'notification_service.dart';

/// Xử lý nút "Đã hiểu" trên thông báo khóa học khi app KHÔNG chạy (isolate
/// nền). Chỉ ghi `status = read` vào SQLite; thẻ ôn FSRS được kích hoạt sau
/// bởi `CourseService.reconcile()` lần mở app kế tiếp.
@pragma('vm:entry-point')
Future<void> courseNotificationBackground(NotificationResponse response) async {
  if (response.actionId != courseActionMarkRead) return;
  final String payload = response.payload ?? '';
  final NotificationPayload parsed = NotificationPayload.parse(payload);
  if (!parsed.isCourse || parsed.id == null) return;
  try {
    DartPluginRegistrant.ensureInitialized();
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final Database db = await openDatabase(
      p.join(dir, 'mind_keeper.db'),
      singleInstance: false,
    );
    try {
      final int now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.update(
        'course_items',
        <String, Object?>{'status': 'read', 'read_at': now, 'updated_at': now},
        where: "id = ? AND status = 'ready'",
        whereArgs: <Object>[parsed.id!],
      );
    } finally {
      await db.close();
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Nút Đã hiểu (nền) lỗi: $e');
  }
}
