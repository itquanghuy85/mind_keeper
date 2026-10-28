import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_dialog.dart';
import '../../data/models/course.dart';
import '../discover/discovery_catalog.dart';
import 'onboarding_service.dart';

/// Onboarding 3 bước (~60 giây): giá trị → chủ đề + cấp độ → giờ nhắc + quyền.
///
/// - [review] = true: "Xem lại giới thiệu" từ Hồ sơ — chỉ cập nhật cấp độ/giờ
///   nhắc, KHÔNG tạo lại dữ liệu mẫu.
/// - Có "Bỏ qua" ở mọi bước: đánh dấu đã onboarding, không tạo dữ liệu.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onDone,
    this.review = false,
  });

  final VoidCallback onDone;
  final bool review;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final Set<String> _categories = <String>{};
  CourseLevel _level = CourseLevel.basic;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _remind = true;

  /// null = chưa xin; true = đã cấp; false = bị từ chối / chưa được cấp.
  bool? _permission;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.review) {
      final AppServices services = context.read<AppServices>();
      _level = CourseLevel.fromDb(services.prefs.defaultCourseLevel);
      _time = TimeOfDay(
        hour: services.prefs.reminderHour,
        minute: services.prefs.reminderMinute,
      );
      _remind = services.prefs.notificationsEnabled;
    }
  }

  OnboardingService _service(AppServices s) => OnboardingService(
    topics: s.topics,
    discovery: s.discovery,
    prefs: s.prefs,
  );

  void _toggleCategory(String category) {
    setState(() {
      if (_categories.contains(category)) {
        _categories.remove(category);
      } else if (_categories.length >= OnboardingService.maxCategories) {
        showAppSnack(
          context,
          message: 'Chọn tối đa ${OnboardingService.maxCategories} chủ đề.',
        );
      } else {
        _categories.add(category);
      }
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _requestPermission() async {
    final AppServices services = context.read<AppServices>();
    final bool granted = await services.notifications.requestPermissions();
    if (mounted) setState(() => _permission = granted);
  }

  Future<void> _skip() async {
    if (_busy) return;
    final AppServices services = context.read<AppServices>();
    setState(() => _busy = true);
    if (!widget.review) {
      await services.prefs.setOnboardingCompleted(true);
    }
    if (mounted) widget.onDone();
  }

  Future<void> _finish() async {
    if (_busy) return;
    final AppServices services = context.read<AppServices>();
    final OnboardingService onboarding = _service(services);
    setState(() => _busy = true);
    try {
      bool granted = _permission ?? false;
      if (_remind && _permission == null) {
        granted = await services.notifications.requestPermissions();
        _permission = granted;
      }
      await onboarding.savePreferences(
        courseLevelId: _level.dbValue,
        reminderHour: _time.hour,
        reminderMinute: _time.minute,
        notificationsEnabled: _remind && granted,
      );
      if (!widget.review) {
        await onboarding.seedFor(_categories.toList());
        await services.prefs.setOnboardingCompleted(true);
      }
      if (mounted && _remind && !granted) {
        showAppSnack(
          context,
          message:
              'Chưa có quyền thông báo nên chưa nhắc được. Bật sau ở Hồ sơ → '
              'Cài đặt thông báo.',
          duration: const Duration(seconds: 5),
        );
      }
      AppBootstrap.instance.bumpDataVersion();
      if (_remind && granted && AppBootstrap.instance.isReady) {
        await AppBootstrap.instance.refreshReminderSchedule();
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, message: 'Không hoàn tất được: $e', error: true);
        setState(() => _busy = false);
      }
      return;
    }
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool canContinue =
        widget.review || _categories.length >= OnboardingService.minCategories;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (_step > 0)
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: _busy ? null : () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Text('Bước ${_step + 1}/3', style: text.labelMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: _busy ? null : _skip,
                    child: Text(widget.review ? 'Đóng' : 'Bỏ qua'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  child: switch (_step) {
                    0 => _buildIntro(text),
                    1 => _buildChoose(text),
                    _ => _buildReminder(text),
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_step == 0)
                AppButton(
                  label: 'Bắt đầu',
                  onPressed: () => setState(() => _step = 1),
                )
              else if (_step == 1)
                AppButton(
                  label: canContinue
                      ? 'Tiếp tục'
                      : 'Chọn ${OnboardingService.minCategories}–'
                            '${OnboardingService.maxCategories} chủ đề',
                  onPressed: canContinue
                      ? () => setState(() => _step = 2)
                      : null,
                )
              else
                AppButton(
                  label: 'Xong',
                  icon: Icons.check_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : _finish,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.psychology_alt_rounded,
          size: 64,
          color: context.appColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Nhớ lâu hơn, mỗi ngày một chút', style: text.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Text(
          'MindKeeper nhắc bạn đọc từng mẩu kiến thức ngắn và ôn lại đúng lúc '
          'bằng thuật toán FSRS — nhớ lâu mà không tốn nhiều thời gian.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        const _ValueRow(
          icon: Icons.menu_book_rounded,
          title: 'Mẩu ngắn, đọc ngay trên thông báo',
        ),
        const _ValueRow(
          icon: Icons.event_repeat_rounded,
          title: 'Ôn đúng lúc sắp quên',
        ),
        const _ValueRow(
          icon: Icons.lock_outline_rounded,
          title: 'Dữ liệu nằm trên máy bạn, dùng được offline',
        ),
      ],
    );
  }

  Widget _buildChoose(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Bạn muốn học gì?', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.review
              ? 'Chỉ đổi cấp độ mặc định — không tạo lại nội dung mẫu.'
              : 'Chọn ${OnboardingService.minCategories}–'
                    '${OnboardingService.maxCategories} chủ đề, chúng tôi tạo sẵn '
                    'nội dung offline để bạn học ngay.',
          style: text.bodyMedium,
        ),
        if (!widget.review) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final String category in DiscoveryCatalog.categories)
                AppChip(
                  label: category,
                  selected: _categories.contains(category),
                  onTap: () => _toggleCategory(category),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Đã chọn ${_categories.length}/${OnboardingService.maxCategories}',
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Cấp độ mặc định cho khóa học mới', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final CourseLevel level in CourseLevel.values)
              AppChip(
                label: level.label,
                selected: _level == level,
                onTap: () => setState(() => _level = level),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(_level.hint, style: text.bodySmall),
      ],
    );
  }

  Widget _buildReminder(TextTheme text) {
    final String time = _time.format(context);
    final String status = !_remind
        ? 'Nhắc hằng ngày đang tắt.'
        : switch (_permission) {
            true => 'Quyền thông báo: đã cấp.',
            false =>
              'Quyền thông báo: chưa được cấp. Bạn vẫn dùng app bình thường; bật '
                  'sau ở Hồ sơ → Cài đặt thông báo.',
            null => 'Quyền thông báo: chưa xin — sẽ xin khi bạn bấm Xong.',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Nhắc học mỗi ngày', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Chọn giờ nhận nhắc ôn tập. Bạn có thể đổi sau trong Hồ sơ.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Nhắc ôn tập mỗi ngày'),
                value: _remind,
                onChanged: (bool v) => setState(() => _remind = v),
              ),
              if (_remind) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Giờ nhắc: $time',
                  icon: Icons.schedule_rounded,
                  variant: AppButtonVariant.tonal,
                  onPressed: _pickTime,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(status, style: text.bodyMedium),
        ),
        if (_remind && _permission != true) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Cho phép thông báo',
            icon: Icons.notifications_active_outlined,
            variant: AppButtonVariant.tonal,
            onPressed: _requestPermission,
          ),
        ],
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(icon, color: context.appColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
