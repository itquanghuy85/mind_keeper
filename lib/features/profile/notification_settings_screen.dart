import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_card.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PreferencesService prefs = context.watch<PreferencesService>();
    final AppServices services = context.read<AppServices>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Bật thông báo nhắc ôn'),
                    subtitle: const Text(
                      'Nhận nhắc theo giờ bạn chọn mỗi ngày.',
                    ),
                    value: prefs.notificationsEnabled,
                    onChanged: (bool value) async {
                      await prefs.setNotificationsEnabled(value);
                      if (value) {
                        final bool granted =
                            await services.notifications.requestPermissions();
                        if (!granted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Quyền thông báo bị từ chối — vào cài đặt hệ thống để bật.',
                              ),
                            ),
                          );
                        }
                        await AppBootstrap.instance.refreshReminderSchedule();
                      } else {
                        await services.notifications.cancelAll();
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Giờ nhắc hằng ngày'),
                    subtitle: Text(
                      '${prefs.reminderHour.toString().padLeft(2, '0')}:${prefs.reminderMinute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.schedule_rounded),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: prefs.reminderHour,
                          minute: prefs.reminderMinute,
                        ),
                      );
                      if (picked != null) {
                        await prefs.setReminderTime(
                          hour: picked.hour,
                          minute: picked.minute,
                        );
                        await AppBootstrap.instance.refreshReminderSchedule();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã đặt giờ nhắc ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Text(
                'Khi chạm thông báo, ứng dụng mở đúng thẻ ôn được nhắc '
                '(payload card:<id>). Lịch thay đổi hoặc thẻ bị xoá sẽ không '
                'còn hiển thị thông báo cũ sau khi khởi động lại lịch.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Yêu cầu thông báo lần đầu',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Android 13+ cần người dùng cấp quyền. Nếu bị từ chối, '
                    'thông báo sẽ không hiển thị cho đến khi bật lại trong cài đặt hệ thống.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonal(
                    onPressed: () async {
                      final bool ok =
                          await services.notifications.requestPermissions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'Đã cấp quyền (hoặc đã có).' : 'Bị từ chối.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Yêu cầu quyền thông báo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
