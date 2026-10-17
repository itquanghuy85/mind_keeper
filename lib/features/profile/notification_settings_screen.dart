import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/review_card.dart';
import '../../data/models/topic.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  /// Trạng thái quyền HIỆN TẠI đọc từ hệ thống.
  /// `null` = đang kiểm tra hoặc nền tảng không có API đọc trạng thái (iOS).
  bool? _notificationsAllowed;
  bool _checkingPermission = false;
  bool _sendingTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quay lại từ Cài đặt hệ thống → đọc trạng thái thật; nếu người dùng đã
  /// cấp quyền và switch đang bật thì tự lập lịch nhắc (idempotent).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatus(resyncSchedule: true);
    }
  }

  Future<void> _refreshPermissionStatus({bool resyncSchedule = false}) async {
    if (_checkingPermission) return;
    _checkingPermission = true;
    try {
      final AppServices services = context.read<AppServices>();
      final bool? allowed =
          await services.notifications.areNotificationsEnabled();
      if (!mounted) return;
      setState(() => _notificationsAllowed = allowed);
      if (resyncSchedule && allowed == true) {
        final PreferencesService prefs = context.read<PreferencesService>();
        if (prefs.notificationsEnabled) {
          await AppBootstrap.instance.refreshReminderSchedule();
        }
      }
    } finally {
      _checkingPermission = false;
    }
  }

  /// Xin quyền và CHỈ lên lịch khi hệ thống thật sự cấp.
  Future<void> _requestPermissionAndSchedule() async {
    final AppServices services = context.read<AppServices>();
    final bool granted = await services.notifications.requestPermissions();
    if (!mounted) return;
    setState(() => _notificationsAllowed = granted);
    final PreferencesService prefs = context.read<PreferencesService>();
    if (granted && prefs.notificationsEnabled) {
      await AppBootstrap.instance.refreshReminderSchedule();
    }
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã cho phép thông báo — lịch nhắc được lập.'),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Quyền thông báo bị từ chối. Bật quyền cho MindKeeper trong '
            'cài đặt hệ thống để nhận nhắc ôn.',
          ),
          action: SnackBarAction(
            label: 'Mở cài đặt',
            onPressed: () => services.notifications.openNotificationSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final AppServices services = context.read<AppServices>();
    await prefs.setNotificationsEnabled(value);
    if (!mounted) return;
    if (value) {
      final bool granted = await services.notifications.requestPermissions();
      if (!mounted) return;
      setState(() => _notificationsAllowed = granted);
      if (granted) {
        await AppBootstrap.instance.refreshReminderSchedule();
      }
      if (!mounted) return;
      final ScaffoldMessengerState messenger =
          ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Đã bật nhắc ôn.'
                : 'Đã ghi nhận yêu cầu, nhưng quyền thông báo bị từ chối. '
                    'Bật trong cài đặt hệ thống để nhận nhắc.',
          ),
          action: granted
              ? null
              : SnackBarAction(
                  label: 'Mở cài đặt',
                  onPressed: () =>
                      services.notifications.openNotificationSettings(),
                ),
        ),
      );
    } else {
      await services.notifications.cancelAll();
      if (!mounted) return;
      final ScaffoldMessengerState messenger =
          ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã tắt thông báo và hủy các lịch đã lên.'),
        ),
      );
    }
  }

  String get _statusLabel => switch (_notificationsAllowed) {
        true => 'Đã cho phép',
        false => 'Bị từ chối',
        null => 'Chưa rõ',
      };

  String get _statusHint => switch (_notificationsAllowed) {
        true =>
          'Thông báo được phép hiển thị. Bật công tắc bên trên để nhận nhắc '
              'theo giờ bạn chọn.',
        false =>
          'Hệ thống đang chặn thông báo của MindKeeper. Cho phép quyền trong '
              'cài đặt hệ thống (nút bên dưới) hoặc bấm "Yêu cầu quyền thông báo" '
              'để hệ thống hỏi lại.',
        null =>
          'Nền tảng này không hỗ trợ đọc trạng thái tự động. Bấm "Yêu cầu '
              'quyền thông báo" nếu hệ thống có hộp thoại cấp quyền.',
      };

  Color get _statusColor => switch (_notificationsAllowed) {
        true => Theme.of(context).colorScheme.primary,
        false => Theme.of(context).colorScheme.error,
        null => Theme.of(context).colorScheme.onSurfaceVariant,
      };

  IconData get _statusIcon => switch (_notificationsAllowed) {
        true => Icons.check_circle_rounded,
        false => Icons.block_rounded,
        null => Icons.help_outline_rounded,
      };

  Future<void> _sendTestNotification({required bool scheduled}) async {
    if (_sendingTest) return;
    setState(() => _sendingTest = true);
    try {
      final AppServices services = context.read<AppServices>();
      final DateTime now = DateTime.now().toUtc();
      final Topic topic = await services.topics.findByName(
            'Kiểm thử thông báo',
          ) ??
          await services.topics.create(name: 'Kiểm thử thông báo');
      final KnowledgeItem item = await services.knowledge.create(
        topicId: topic.id,
        title: 'Thẻ kiểm thử GĐ15.1',
        content: 'Nội dung riêng cho kiểm thử thông báo — không phải dữ liệu người dùng.',
      );
      final ReviewCard card = await services.cards.create(
        knowledgeItemId: item.id,
        question: 'TEST-GD151: Chạm thông báo này mở đúng câu hỏi chứ?',
        answer: 'Đúng — payload card:<id> mở ReviewCard tương ứng.',
        dueAt: now,
      );
      if (scheduled) {
        await services.notifications.scheduleCardDueAt(
          cardId: card.id,
          title: 'Kiểm thử nhắc ôn (GĐ15.1)',
          body: card.question,
          at: now.add(const Duration(minutes: 2)),
        );
      } else {
        await services.notifications.showCardDue(
          cardId: card.id,
          title: 'Kiểm thử thông báo ngay (GĐ15.1)',
          body: card.question,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scheduled
                ? 'Đã lên lịch thẻ test sau 2 phút — chờ thông báo rồi chạm.'
                : 'Đã gửi thông báo test — chạm để mở đúng thẻ.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PreferencesService prefs = context.watch<PreferencesService>();
    final AppServices services = context.read<AppServices>();
    final TextTheme text = Theme.of(context).textTheme;
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
                    onChanged: _toggleNotifications,
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
                style: text.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        _statusIcon,
                        size: 18,
                        color: _statusColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Trạng thái quyền',
                          style: text.titleSmall,
                        ),
                      ),
                      Text(
                        _statusLabel,
                        style: text.labelLarge?.copyWith(color: _statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_statusHint, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonal(
                    onPressed:
                        _sendingTest ? null : _requestPermissionAndSchedule,
                    child: const Text('Yêu cầu quyền thông báo'),
                  ),
                  if (_notificationsAllowed == false) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () =>
                          services.notifications.openNotificationSettings(),
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('Mở cài đặt hệ thống'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Android 13+ cần người dùng cấp quyền. Nếu bị từ chối, '
                    'thông báo sẽ không hiển thị cho đến khi bật lại trong cài '
                    'đặt hệ thống.',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _DebugNotificationCard(
                sending: _sendingTest,
                onSendNow: () => _sendTestNotification(scheduled: false),
                onSchedule: () => _sendTestNotification(scheduled: true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Công cụ kiểm thử THÔNG BÁO (chỉ render trong bản Debug; release ẩn).
/// Tạo dữ liệu test riêng — không xoá hoặc sửa dữ liệu người dùng.
class _DebugNotificationCard extends StatelessWidget {
  const _DebugNotificationCard({
    required this.sending,
    required this.onSendNow,
    required this.onSchedule,
  });

  final bool sending;
  final VoidCallback onSendNow;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Kiểm thử thông báo (Debug)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tạo một thẻ test riêng rồi gửi/lên lịch thông báo với payload '
            'card:<id>. Dữ liệu test nằm trong chủ đề "Kiểm thử thông báo".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: sending ? null : onSendNow,
                icon: const Icon(Icons.notifications_active_rounded, size: 18),
                label: const Text('Gửi ngay'),
              ),
              FilledButton.tonalIcon(
                onPressed: sending ? null : onSchedule,
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('Lên lịch +2 phút'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
