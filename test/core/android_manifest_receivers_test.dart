import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hồi quy lỗi "thông báo hẹn giờ không bao giờ hiện": flutter_local_notifications
/// 22.x KHÔNG tự khai báo các receiver trong manifest của plugin. Thiếu khai báo
/// trong AndroidManifest của app thì AlarmManager gửi broadcast tới thành phần
/// không tồn tại và hệ thống bỏ qua (không log, không thông báo).
void main() {
  final String manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('khai báo ScheduledNotificationReceiver (hiện thông báo hẹn giờ)', () {
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      ),
    );
  });

  test('khai báo ScheduledNotificationBootReceiver (lập lại lịch sau khởi động)', () {
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
      ),
    );
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
  });

  test('khai báo ActionBroadcastReceiver (nút "Đã hiểu" trên thông báo)', () {
    expect(
      manifest,
      contains('com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver'),
    );
  });

  test('các receiver của plugin không được export ra ngoài', () {
    final RegExp re = RegExp(
      r'<receiver[^>]*com\.dexterous\.flutterlocalnotifications\.[A-Za-z]+Receiver[^>]*>',
    );
    final Iterable<RegExpMatch> found = re.allMatches(manifest);
    expect(found.length, greaterThanOrEqualTo(3));
    for (final RegExpMatch m in found) {
      expect(m.group(0), contains('android:exported="false"'));
    }
  });

  test('có quyền báo thức chính xác + thông báo', () {
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
  });
}
