import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/knowledge_reminder_scheduler.dart';
import '../../core/services/app_services.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/review_card.dart';
import '../../data/models/topic.dart';
import '../../core/theme/app_palette.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
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
      final bool? allowed = await services.notifications
          .areNotificationsEnabled();
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
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
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
      await services.notifications.cancelDailyReminder();
      await services.notifications.cancelReviewDue();
      if (!mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
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
    true => AppColors.success,
    false => AppColors.danger,
    null => context.appColors.textSecondary,
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
      final Topic topic =
          await services.topics.findByName('Kiểm thử thông báo') ??
          await services.topics.create(name: 'Kiểm thử thông báo');
      final KnowledgeItem item = await services.knowledge.create(
        topicId: topic.id,
        title: 'Thẻ kiểm thử GĐ15.1',
        content:
            'Nội dung riêng cho kiểm thử thông báo — không phải dữ liệu người dùng.',
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

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Mỗi ngày';
    const List<String> dayNames = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ Nhật',
    ];
    return days.map((d) => dayNames[d]).join(', ');
  }

  String _formatFrequency(int frequency) {
    switch (frequency) {
      case 1:
        return 'Hàng ngày';
      case 2:
        return 'Cách ngày';
      case 3:
        return '3 ngày/lần';
      case 4:
        return '4 ngày/lần';
      case 5:
        return '5 ngày/lần';
      case 6:
        return '6 ngày/lần';
      case 7:
        return 'Tuần một lần';
      default:
        return 'Hàng ngày';
    }
  }

  Future<void> _toggleKnowledgeReading(bool value) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final AppServices services = context.read<AppServices>();
    await prefs.setKnowledgeReadingEnabled(value);
    if (!mounted) return;
    if (value) {
      final bool granted = await services.notifications.requestPermissions();
      if (!mounted) return;
      setState(() => _notificationsAllowed = granted);
      if (granted) {
        await _refreshKnowledgeReadingSchedule();
      }
      if (!mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Đã bật nhắc đọc kiến thức.'
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
      await services.notifications.cancelKnowledgeReadingReminder();
      if (!mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã tắt nhắc đọc kiến thức và hủy lịch đã lên.'),
        ),
      );
    }
  }

  Future<void> _toggleKnowledgeReminder(bool value) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final AppServices services = context.read<AppServices>();
    await prefs.setKnowledgeReminderEnabled(value);
    if (!mounted) return;
    if (value) {
      if (await services.lessons.countAll() == 0) {
        await prefs.setKnowledgeReminderEnabled(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create lessons first before enabling reminders.'),
          ),
        );
        return;
      }
      final bool granted = await services.notifications.requestPermissions();
      if (!mounted) return;
      setState(() => _notificationsAllowed = granted);
      if (granted) {
        await AppBootstrap.instance.refreshKnowledgeReminderSchedule();
      } else {
        await prefs.setKnowledgeReminderEnabled(false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted ? 'Enabled proactive reminders.' : 'Notification permission denied.',
          ),
        ),
      );
    } else {
      await services.knowledgeReminders.cancel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disabled proactive reminders.')),
      );
    }
  }

  Future<void> _pickKnowledgeReminderTime({required bool start}) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final TimeOfDay initial = TimeOfDay(
      hour: start ? prefs.knowledgeReminderStartHour : prefs.knowledgeReminderEndHour,
      minute: start
          ? prefs.knowledgeReminderStartMinute
          : prefs.knowledgeReminderEndMinute,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;
    if (start) {
      await prefs.setKnowledgeReminderWindow(
        startHour: picked.hour,
        startMinute: picked.minute,
        endHour: prefs.knowledgeReminderEndHour,
        endMinute: prefs.knowledgeReminderEndMinute,
      );
    } else {
      await prefs.setKnowledgeReminderWindow(
        startHour: prefs.knowledgeReminderStartHour,
        startMinute: prefs.knowledgeReminderStartMinute,
        endHour: picked.hour,
        endMinute: picked.minute,
      );
    }
    await AppBootstrap.instance.refreshKnowledgeReminderSchedule();
  }

  Future<void> _previewKnowledgeReminder() async {
    final AppServices services = context.read<AppServices>();
    final List<KnowledgeReminderPreviewItem> items =
        await services.knowledgeReminders.buildSchedule();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Preview schedule'),
        content: SizedBox(
          width: double.maxFinite,
          child: items.isEmpty
              ? const Text('No lessons to schedule.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final KnowledgeReminderPreviewItem item = items[index];
                    return ListTile(
                      title: Text(item.lessonTitle),
                      subtitle: Text(
                        '${item.at.day}/${item.at.month} ${item.at.hour.toString().padLeft(2, '0')}:${item.at.minute.toString().padLeft(2, '0')}\n${item.snippet}',
                      ),
                    );
                  },
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickKnowledgeReminderSource() async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final AppServices services = context.read<AppServices>();
    final List<Topic> topics = await services.topics.list();
    if (!mounted) return;
    final List<String> current = List<String>.from(
      prefs.knowledgeReminderSelectedTopics,
    );
    final List<String>? selected = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        final List<String> temp = List<String>.from(current);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Select knowledge source'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    RadioListTile<String>(
                      title: const Text('All saved lessons'),
                      value: 'all',
                      groupValue: prefs.knowledgeReminderSource,
                      onChanged: (String? value) async {
                        await prefs.setKnowledgeReminderSource('all');
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Selected topics'),
                      value: 'selected',
                      groupValue: prefs.knowledgeReminderSource,
                      onChanged: (String? value) async {
                        await prefs.setKnowledgeReminderSource('selected');
                        setState(() {});
                      },
                    ),
                    if (prefs.knowledgeReminderSource == 'selected') ...<Widget>[
                      for (final Topic topic in topics)
                        CheckboxListTile(
                          title: Text(topic.name),
                          value: temp.contains(topic.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                temp.add(topic.id);
                              } else {
                                temp.remove(topic.id);
                              }
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(temp),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null && mounted) {
      await prefs.setKnowledgeReminderSelectedTopics(selected);
      await AppBootstrap.instance.refreshKnowledgeReminderSchedule();
    }
  }

  Future<void> _pickDays() async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final List<int> currentDays = List<int>.from(prefs.knowledgeReadingDays);

    if (!mounted) return;
    final List<int>? selected = await showDialog<List<int>>(
      context: context,
      builder: (BuildContext context) {
        List<int> tempDays = List<int>.from(currentDays);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Chọn ngày trong tuần'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (int i = 1; i <= 7; i++) ...[
                      CheckboxListTile(
                        title: Text(_dayName(i)),
                        value: tempDays.contains(i),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              tempDays.add(i);
                            } else {
                              tempDays.remove(i);
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(tempDays),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      await prefs.setKnowledgeReadingDays(selected);
      await _refreshKnowledgeReadingSchedule();
    }
  }

  Future<void> _pickFrequency() async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final int current = prefs.knowledgeReadingFrequency;

    if (!mounted) return;
    final int? selected = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return RadioGroup<int>(
          groupValue: current,
          onChanged: (int? value) {
            if (value != null) {
              Navigator.of(context).pop(value);
            }
          },
          child: SimpleDialog(
            title: const Text('Chọn tần suất nhắc'),
            children: <Widget>[
              for (int i = 1; i <= 7; i++) ...[
                RadioListTile<int>(title: Text(_formatFrequency(i)), value: i),
              ],
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await prefs.setKnowledgeReadingFrequency(selected);
      await _refreshKnowledgeReadingSchedule();
    }
  }

  Future<void> _refreshKnowledgeReadingSchedule() async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final AppServices services = context.read<AppServices>();

    if (!prefs.knowledgeReadingEnabled) {
      await services.notifications.cancelKnowledgeReadingReminder();
      return;
    }

    final bool? allowed = await services.notifications
        .areNotificationsEnabled();
    if (allowed == false) {
      if (kDebugMode) {
        debugPrint('Bỏ qua lên lịch nhắc đọc: quyền thông báo bị chặn.');
      }
      return;
    }

    await services.notifications.scheduleKnowledgeReadingReminder(
      title: 'Đến giờ đọc kiến thức',
      body: 'Mở app để học bài mới hoặc ôn tập.',
      hour: prefs.knowledgeReadingHour,
      minute: prefs.knowledgeReadingMinute,
      days: prefs.knowledgeReadingDays,
      frequency: prefs.knowledgeReadingFrequency,
    );
  }

  String _dayName(int day) {
    const List<String> names = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ Nhật',
    ];
    return names[day];
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
                      Icon(_statusIcon, size: 18, color: _statusColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('Trạng thái quyền', style: text.titleSmall),
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
                    onPressed: _sendingTest
                        ? null
                        : _requestPermissionAndSchedule,
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
            const SizedBox(height: AppSpacing.lg),
            // Knowledge Reading Notifications
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Bật nhắc đọc kiến thức'),
                    subtitle: const Text(
                      'Nhận nhắc học bài mới theo lịch bạn chọn.',
                    ),
                    value: prefs.knowledgeReadingEnabled,
                    onChanged: _toggleKnowledgeReading,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Giờ nhắc'),
                    subtitle: Text(
                      '${prefs.knowledgeReadingHour.toString().padLeft(2, '0')}:${prefs.knowledgeReadingMinute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.schedule_rounded),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: prefs.knowledgeReadingHour,
                          minute: prefs.knowledgeReadingMinute,
                        ),
                      );
                      if (picked != null) {
                        await prefs.setKnowledgeReadingTime(
                          hour: picked.hour,
                          minute: picked.minute,
                        );
                        await _refreshKnowledgeReadingSchedule();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã đặt giờ nhắc đọc ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Ngày trong tuần'),
                    subtitle: Text(_formatDays(prefs.knowledgeReadingDays)),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickDays,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Tần suất'),
                    subtitle: Text(
                      _formatFrequency(prefs.knowledgeReadingFrequency),
                    ),
                    trailing: const Icon(Icons.repeat_rounded),
                    onTap: _pickFrequency,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Proactive knowledge reminders'),
                    subtitle: const Text(
                      'Receive multiple knowledge snippets per day.',
                    ),
                    value: prefs.knowledgeReminderEnabled,
                    onChanged: _toggleKnowledgeReminder,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Start time'),
                    subtitle: Text(
                      '${prefs.knowledgeReminderStartHour.toString().padLeft(2, '0')}:${prefs.knowledgeReminderStartMinute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.schedule_rounded),
                    onTap: () => _pickKnowledgeReminderTime(start: true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('End time'),
                    subtitle: Text(
                      '${prefs.knowledgeReminderEndHour.toString().padLeft(2, '0')}:${prefs.knowledgeReminderEndMinute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.schedule_rounded),
                    onTap: () => _pickKnowledgeReminderTime(start: false),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Notifications per day'),
                    subtitle: Text('${prefs.knowledgeReminderCountPerDay}'),
                    trailing: const Icon(Icons.repeat_rounded),
                    onTap: () async {
                      final int? value = await showDialog<int>(
                        context: context,
                        builder: (BuildContext context) => SimpleDialog(
                          title: const Text('Notifications per day'),
                          children: <Widget>[
                            for (int i = 1; i <= 10; i++)
                              SimpleDialogOption(
                                onPressed: () => Navigator.of(context).pop(i),
                                child: Text('$i'),
                              ),
                          ],
                        ),
                      );
                      if (value != null) {
                        await prefs.setKnowledgeReminderCountPerDay(value);
                        await AppBootstrap.instance
                            .refreshKnowledgeReminderSchedule();
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Knowledge source'),
                    subtitle: Text(
                      prefs.knowledgeReminderSource == 'all'
                          ? 'All saved lessons'
                          : 'Selected topics',
                    ),
                    trailing: const Icon(Icons.source_rounded),
                    onTap: _pickKnowledgeReminderSource,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Preview schedule'),
                    trailing: const Icon(Icons.preview_rounded),
                    onTap: _previewKnowledgeReminder,
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
              AppButton(
                label: 'Gửi ngay',
                variant: AppButtonVariant.secondary,
                dense: true,
                expanded: false,
                icon: Icons.notifications_active_rounded,
                onPressed: sending ? null : onSendNow,
              ),
              AppButton(
                label: 'Lên lịch +2 phút',
                variant: AppButtonVariant.secondary,
                dense: true,
                expanded: false,
                icon: Icons.schedule_rounded,
                onPressed: sending ? null : onSchedule,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
