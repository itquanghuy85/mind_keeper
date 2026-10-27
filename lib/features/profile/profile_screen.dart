import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../core/widgets/app_text_field.dart';
import '../../features/knowledge/learned_library_screen.dart';
import '../ai/ai_presets.dart';
import '../import/link_import_screen.dart';
import '../import/media_import_flow.dart';
import '../import/text_import_screen.dart';
import '../import/voice_import_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_screen.dart';
import 'study_plan_screen.dart';
import '../../core/theme/app_palette.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PreferencesService prefs = context.watch<PreferencesService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            AppCard(
              child: Row(
                children: <Widget>[
                  const AppIconBadge(
                    icon: Icons.person_rounded,
                    tone: AppIconTone.primary,
                    size: 56,
                    radius: AppRadius.xl,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Người học MindKeeper',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Học ít nhưng đều đặn',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppSectionHeader(
              title: 'Học tập',
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _SettingsTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: 'Mục tiêu học mỗi ngày',
                    trailing: Text(
                      '${prefs.dailyGoal} mục tiêu',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    onTap: () => _editDailyGoal(context, prefs),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.explore_outlined),
                    title: 'Số chủ đề mới mỗi ngày',
                    trailing: Text(
                      '${prefs.newTopicsPerDay}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    onTap: () => _editNewTopics(context, prefs),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.category_outlined),
                    title: 'Lĩnh vực yêu thích',
                    trailing: Text(
                      prefs.favoriteCategories.isEmpty
                          ? 'Chưa đặt'
                          : '${prefs.favoriteCategories.length}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    onTap: () => _editCategories(context, prefs),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: 'Kế hoạch học',
                    subtitle: 'Bài mới mỗi ngày, khung giờ, chủ đề theo dõi',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StudyPlanScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppSectionHeader(
              title: 'Thông báo & AI',
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Bật thông báo'),
                    value: prefs.notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (bool value) async {
                      final AppServices services = context.read<AppServices>();
                      await prefs.setNotificationsEnabled(value);
                      if (value) {
                        await services.notifications.requestPermissions();
                        await AppBootstrap.instance.refreshReminderSchedule();
                      } else {
                        await services.notifications.cancelAll();
                      }
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.alarm_outlined),
                    title: 'Giờ nhắc ôn tập',
                    trailing: Text(
                      '${prefs.reminderHour.toString().padLeft(2, '0')}:${prefs.reminderMinute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
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
                      }
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: 'Cấu hình AI',
                    subtitle: context.read<AppServices>().ai.isRealProvider
                        ? 'Đang dùng AI thật (${prefs.aiModel})'
                        : 'Đang dùng mock AI — chưa cấu hình key',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editAi(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: 'Nhập văn bản',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TextImportScreen(),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.link_outlined),
                    title: 'Nhập từ liên kết web',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LinkImportScreen(),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: 'Nhập từ ảnh (OCR)',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => MediaImportFlow.fromImage(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: 'Nhập từ PDF',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => MediaImportFlow.fromPdf(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.mic_none_outlined),
                    title: 'Nhập bằng giọng nói',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VoiceImportScreen(),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.library_books_outlined),
                    title: 'Kho đã học',
                    subtitle: 'Danh sách bài đã mở đọc, ôn tập và tiến độ',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LearnedLibraryScreen(),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  _SettingsTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: 'Cài đặt thông báo chi tiết',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppSectionHeader(
              title: 'Về ứng dụng',
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'MindKeeper AI',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Lưu kiến thức, ôn theo FSRS, khám phá chủ đề mới. '
                    'Lịch ôn tính riêng cho từng thẻ ghi nhớ.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Phiên bản 1.0.0',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: 'Quyền riêng tư & điều khoản',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _editDailyGoal(
    BuildContext context,
    PreferencesService prefs,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: '${prefs.dailyGoal}',
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Mục tiêu học mỗi ngày'),
        content: AppTextField(
          controller: controller,
          keyboardType: TextInputType.number,
          hint: 'VD: 10',
        ),
        actions: <Widget>[
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.tonal,
            dense: true,
            expanded: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          AppButton(
            label: 'Lưu',
            variant: AppButtonVariant.primary,
            dense: true,
            expanded: false,
            onPressed: () => Navigator.of(context).pop('save'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      final int? value = int.tryParse(controller.text.trim());
      if (value != null) await prefs.setDailyGoal(value);
    }
    controller.dispose();
  }

  Future<void> _editNewTopics(
    BuildContext context,
    PreferencesService prefs,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: '${prefs.newTopicsPerDay}',
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Số chủ đề mới mỗi ngày'),
        content: AppTextField(
          controller: controller,
          keyboardType: TextInputType.number,
          hint: '0–5',
        ),
        actions: <Widget>[
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.tonal,
            dense: true,
            expanded: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          AppButton(
            label: 'Lưu',
            variant: AppButtonVariant.primary,
            dense: true,
            expanded: false,
            onPressed: () => Navigator.of(context).pop('save'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      final int? value = int.tryParse(controller.text.trim());
      if (value != null) await prefs.setNewTopicsPerDay(value);
    }
    controller.dispose();
  }

  Future<void> _editCategories(
    BuildContext context,
    PreferencesService prefs,
  ) async {
    final List<String> selected = List<String>.of(prefs.favoriteCategories);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder:
            (
              BuildContext context,
              void Function(void Function()) setModalState,
            ) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Lĩnh vực yêu thích',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Ưu tiên các lĩnh vực này khi khám phá chủ đề mới.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: DiscoveryCategory.all.map((String c) {
                          return AppChip(
                            label: c,
                            selected: selected.contains(c),
                            onTap: () {
                              // Note: multi-select toggle handled externally via prefs
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Lưu',
                          onPressed: () async {
                            await prefs.setFavoriteCategories(selected);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }

  Future<void> _editAi(BuildContext context) async {
    final AppServices services = context.read<AppServices>();
    final PreferencesService prefs = services.prefs;
    AiPreset preset =
        AiPresets.match(prefs.aiBaseUrl) ?? AiPresets.byId('openai');
    String modelId = preset.hasModel(prefs.aiModel)
        ? prefs.aiModel
        : preset.defaultModel;
    final TextEditingController baseUrl = TextEditingController(
      text: preset.isCustom ? prefs.aiBaseUrl : '',
    );
    final TextEditingController apiKey = TextEditingController(
      text: prefs.aiApiKey,
    );
    final TextEditingController model = TextEditingController(
      text: preset.isCustom ? prefs.aiModel : '',
    );
    bool proxyMode = prefs.aiProxyMode && preset.isCustom;
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: const Text('Cấu hình AI'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Chọn nhà cung cấp AI, dán API key là dùng được. '
                  'Để trống key thì app dùng nội dung mẫu (không gọi dịch vụ thật).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  key: const ValueKey<String>('ai-provider'),
                  initialValue: preset.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
                  items: <DropdownMenuItem<String>>[
                    for (final AiPreset p in AiPresets.all)
                      DropdownMenuItem<String>(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (String? id) {
                    if (id == null) return;
                    setDialogState(() {
                      preset = AiPresets.byId(id);
                      modelId = preset.defaultModel;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (!preset.isCustom) ...<Widget>[
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('ai-model-${preset.id}'),
                    initialValue: modelId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Model'),
                    items: <DropdownMenuItem<String>>[
                      for (final AiModelOption m in preset.models)
                        DropdownMenuItem<String>(
                          value: m.id,
                          child: Text(m.label, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (String? id) {
                      if (id != null) setDialogState(() => modelId = id);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...<Widget>[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.shield_outlined),
                    title: const Text('Gọi qua proxy backend'),
                    subtitle: const Text(
                      'Key nằm ở server, không lưu trên máy. '
                      'Base URL là endpoint proxy.',
                    ),
                    value: proxyMode,
                    onChanged: (bool value) =>
                        setDialogState(() => proxyMode = value),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: baseUrl,
                    label: 'Base URL (OpenAI-compatible)',
                    hint: 'https://api.openai.com/v1',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: model,
                    label: 'Model',
                    hint: 'gpt-4o-mini',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  controller: apiKey,
                  label: proxyMode
                      ? 'API key (để trống khi dùng proxy)'
                      : 'API key (dán vào đây)',
                  obscureText: true,
                  hint: preset.keyHint,
                ),
                if (preset.keyGuide.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    preset.keyGuide,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            AppButton(
              label: 'Hủy',
              variant: AppButtonVariant.tonal,
              dense: true,
              expanded: false,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'Lưu',
              variant: AppButtonVariant.primary,
              dense: true,
              expanded: false,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await prefs.setAiConfig(
        baseUrl: preset.isCustom ? baseUrl.text : preset.baseUrl,
        apiKey: apiKey.text,
        model: preset.isCustom ? model.text : modelId,
        proxyMode: preset.isCustom ? proxyMode : false,
      );
      services.ai.configureFromSettings(
        baseUrl: prefs.aiBaseUrl,
        apiKey: prefs.aiApiKey,
        model: prefs.aiModel,
        proxyMode: prefs.aiProxyMode,
      );
      if (context.mounted) {
        showAppSnack(
          context,
          message: services.ai.isRealProvider
              ? 'Đã bật AI thật (${preset.name}).'
              : 'Chưa có API key — tiếp tục dùng nội dung mẫu.',
        );
      }
    }
    baseUrl.dispose();
    apiKey.dispose();
    model.dispose();
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class DiscoveryCategory {
  static const List<String> all = <String>[
    'Khoa học',
    'Lịch sử',
    'Tâm lý',
    'Công nghệ',
    'Địa lý',
    'Kinh doanh',
    'Ngoại ngữ',
    'Đời sống',
  ];
}
