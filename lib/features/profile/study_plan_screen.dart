import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/study_feed_item.dart';
import '../../data/models/topic.dart';
import '../../features/study/study_plan_service.dart';

/// Cài đặt Kế hoạch học chủ động (GĐ17): quota nội dung mới hằng ngày,
/// khung giờ phát hành, chủ đề theo dõi, thông báo bài mới, tạo trước.
class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  StudyPlanSummary? _summary;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  StudyPlanService get _plan => context.read<AppServices>().studyPlan;

  Future<void> _reload() async {
    final StudyPlanSummary summary = await _plan.summary();
    if (!mounted) return;
    setState(() => _summary = summary);
  }

  /// Đối soát lại toàn bộ (lập lịch + sinh nội dung + lên lịch thông báo).
  Future<void> _sync() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final StudyPlanSyncResult result = await _plan.sync();
      if (!mounted) return;
      setState(() => _summary = result.summary ?? _summary);
      if (result.summary == null) {
        await _reload();
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _hhmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _pickWindowTime({required bool start}) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final TimeOfDay initial = TimeOfDay(
      hour: start ? prefs.studyPlanStartHour : prefs.studyPlanEndHour,
      minute: start ? prefs.studyPlanStartMinute : prefs.studyPlanEndMinute,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;
    await prefs.setStudyPlanWindow(
      startHour: start ? picked.hour : prefs.studyPlanStartHour,
      startMinute: start ? picked.minute : prefs.studyPlanStartMinute,
      endHour: start ? prefs.studyPlanEndHour : picked.hour,
      endMinute: start ? prefs.studyPlanEndMinute : picked.minute,
    );
    await _sync();
  }

  Future<void> _pickQuota({required StudyFeedKind kind}) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final int max = kind == StudyFeedKind.quick ? 20 : 10;
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(
          kind == StudyFeedKind.quick
              ? 'Thông tin nhanh mỗi ngày'
              : 'Bài viết mỗi ngày',
        ),
        children: <Widget>[
          for (int i = 0; i <= max; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(i),
              child: Text('$i'),
            ),
        ],
      ),
    );
    if (value == null || !mounted) return;
    if (kind == StudyFeedKind.quick) {
      await prefs.setStudyPlanQuickPerDay(value);
    } else {
      await prefs.setStudyPlanLessonPerDay(value);
    }
    await _sync();
  }

  Future<void> _pickPrefetchDays() async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Tạo trước (số ngày)'),
        children: <Widget>[
          for (int i = 0; i <= 7; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(i),
              child: Text('$i ngày'),
            ),
        ],
      ),
    );
    if (value == null || !mounted) return;
    await prefs.setStudyPlanPrefetchDays(value);
    await _sync();
  }

  Future<void> _addCustomSlot() async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    final String slot = _hhmm(picked.hour, picked.minute);
    final List<String> slots = List<String>.from(prefs.studyPlanSlots);
    if (slots.contains(slot)) return;
    slots.add(slot);
    slots.sort();
    await prefs.setStudyPlanSlots(slots);
    await _sync();
  }

  Future<void> _removeCustomSlot(String slot) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final List<String> slots = List<String>.from(prefs.studyPlanSlots)
      ..remove(slot);
    await prefs.setStudyPlanSlots(slots);
    await _sync();
  }

  Future<void> _togglePaused(bool value) async {
    final PreferencesService prefs = context.read<PreferencesService>();
    await prefs.setStudyPlanPaused(value);
    await _sync();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Đã tạm dừng — không phát hành bài mới, dữ liệu được giữ nguyên.'
              : 'Đã tiếp tục kế hoạch học.',
        ),
      ),
    );
  }

  Future<void> _toggleNewContentNotifications(bool value) async {
    final AppServices services = context.read<AppServices>();
    if (value) {
      final bool granted = await services.notifications.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quyền thông báo bị từ chối — không thể báo bài mới. Bật '
              'trong cài đặt hệ thống rồi thử lại.',
            ),
            action: SnackBarAction(
              label: 'Mở cài đặt',
              onPressed: () => services.notifications.openNotificationSettings(),
            ),
          ),
        );
        return;
      }
    }
    await services.studyPlan.setNewContentNotifications(value);
    await _reload();
  }

  Future<void> _pickExcludedTopics() async {
    final PreferencesService prefs = context.read<PreferencesService>();
    final AppServices services = context.read<AppServices>();
    final List<Topic> topics = await services.topics.list();
    if (!mounted) return;
    final List<String> current = List<String>.from(
      prefs.studyPlanExcludedTopics,
    );
    final List<String>? selected = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        final List<String> temp = List<String>.from(current);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Chủ đề theo dõi'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    if (topics.isEmpty)
                      const Text('Chưa có chủ đề nào.'),
                    for (final Topic topic in topics)
                      CheckboxListTile(
                        dense: true,
                        title: Text(topic.name),
                        value: !temp.contains(topic.id),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == false) {
                              temp.add(topic.id);
                            } else {
                              temp.remove(topic.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(temp),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null && mounted) {
      await prefs.setStudyPlanExcludedTopics(selected);
      await _sync();
    }
  }

  Future<void> _retryFailed() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await _plan.retryFailed();
      await _reload();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PreferencesService prefs = context.watch<PreferencesService>();
    final TextTheme text = Theme.of(context).textTheme;
    final StudyPlanSummary? summary = _summary;
    final bool hasCustomSlots = prefs.studyPlanSlots.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Kế hoạch học')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            // 1. Trạng thái hàng đợi
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Hôm nay', style: text.titleSmall),
                      ),
                      Text(
                        summary == null
                            ? '...'
                            : '${summary.todayReady}/${summary.todayPlanned} '
                                  'đã sẵn sàng',
                        style: text.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (summary != null) ...<Widget>[
                    Text(
                      'Đã phát hành ${summary.todayDelivered} · '
                      'Chờ khung giờ ${summary.todayPlanned - summary.todayDelivered} '
                      '· Tạo trước ${summary.queued} · Lỗi ${summary.errors}',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      summary.paused
                          ? 'Kế hoạch đang TẠM DỪNG — không phát hành bài mới.'
                          : summary.aiReady
                          ? 'AI đã cấu hình — nội dung được tạo trước khi tới giờ.'
                          : 'AI chưa cấu hình API key — chưa thể tạo nội dung mới.',
                      style: text.bodySmall?.copyWith(
                        color: summary.paused
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                    // Nguyên nhân lỗi thực tế — không có thì người dùng chỉ
                    // thấy "Lỗi N" mà không biết vì sao nội dung không tạo được.
                    if (summary.errorMessages.isNotEmpty)
                      ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        for (final String message in summary.errorMessages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $message',
                              style: text.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton(
                          label: _working ? 'Đang đối soát...' : 'Đối soát ngay',
                          icon: Icons.sync_rounded,
                          dense: true,
                          onPressed: _working ? null : _sync,
                        ),
                      ),
                      if ((summary?.errors ?? 0) > 0) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Thử lại lỗi',
                            icon: Icons.replay_rounded,
                            variant: AppButtonVariant.secondary,
                            dense: true,
                            onPressed: _working ? null : _retryFailed,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Nội dung hằng ngày
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Tạm dừng kế hoạch'),
                    subtitle: const Text(
                      'Ngừng phát hành bài mới. Dữ liệu và lịch ôn giữ nguyên.',
                    ),
                    value: prefs.studyPlanPaused,
                    onChanged: _working ? null : _togglePaused,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Thông tin nhanh mỗi ngày'),
                    subtitle: Text('${prefs.studyPlanQuickPerDay} mục'),
                    trailing: const Icon(Icons.bolt_rounded),
                    onTap: () => _pickQuota(kind: StudyFeedKind.quick),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Bài viết mỗi ngày'),
                    subtitle: Text('${prefs.studyPlanLessonPerDay} bài'),
                    trailing: const Icon(Icons.article_rounded),
                    onTap: () => _pickQuota(kind: StudyFeedKind.lesson),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Tạo trước'),
                    subtitle: Text(
                      '${prefs.studyPlanPrefetchDays} ngày (nội dung lưu sẵn '
                      'trong máy)',
                    ),
                    trailing: const Icon(Icons.download_rounded),
                    onTap: _pickPrefetchDays,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Khung giờ phát hành
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: const Text('Bắt đầu khung giờ'),
                    subtitle: Text(
                      _hhmm(
                        prefs.studyPlanStartHour,
                        prefs.studyPlanStartMinute,
                      ),
                    ),
                    trailing: const Icon(Icons.schedule_rounded),
                    onTap: () => _pickWindowTime(start: true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Kết thúc khung giờ'),
                    subtitle: Text(
                      _hhmm(prefs.studyPlanEndHour, prefs.studyPlanEndMinute),
                    ),
                    trailing: const Icon(Icons.schedule_rounded),
                    onTap: () => _pickWindowTime(start: false),
                  ),
                  if (hasCustomSlots) ...<Widget>[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Khung giờ cố định', style: text.titleSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Dùng thay cho chia đều trong khoảng bên trên.',
                            style: text.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: <Widget>[
                              for (final String slot in prefs.studyPlanSlots)
                                Chip(
                                  label: Text(slot),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removeCustomSlot(slot),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Thêm khung giờ cố định'),
                    subtitle: const Text('Chọn giờ cụ thể cho từng bài mới'),
                    trailing: const Icon(Icons.add_circle_outline_rounded),
                    onTap: _addCustomSlot,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Thông báo bài mới
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Thông báo bài mới'),
                    subtitle: const Text(
                      'Báo khi tới khung giờ — chỉ khi nội dung đã lưu xong.',
                    ),
                    value: prefs.studyPlanNewContentNotifications,
                    onChanged: _working ? null : _toggleNewContentNotifications,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Chủ đề theo dõi'),
                    subtitle: Text(
                      summary == null
                          ? '...'
                          : '${summary.activeTopics} chủ đề đang theo dõi',
                    ),
                    trailing: const Icon(Icons.tune_rounded),
                    onTap: _pickExcludedTopics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppCard(
              child: Text(
                'Nội dung mới được sinh và LƯU vào máy trước khi tới giờ, nên '
                'bài vẫn đọc được khi ngoại tuyến. Thông báo có payload '
                'quick:<id> / lesson:<id> để mở đúng nội dung. Kế hoạch học '
                'hoàn toàn độc lập với lịch ôn FSRS — không ảnh hưởng thẻ đến '
                'hạn.',
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
