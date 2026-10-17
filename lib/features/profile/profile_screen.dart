import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../import/link_import_screen.dart';
import '../import/media_import_flow.dart';
import '../import/text_import_screen.dart';
import '../import/voice_import_screen.dart';
import 'notification_settings_screen.dart';

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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Người học MindKeeper',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
            const SizedBox(height: AppSpacing.xl),
            Text('Học tập', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Mục tiêu học mỗi ngày'),
                    trailing: Text('${prefs.dailyGoal} mục tiêu'),
                    onTap: () => _editDailyGoal(context, prefs),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.explore_outlined),
                    title: const Text('Số chủ đề mới mỗi ngày'),
                    trailing: Text('${prefs.newTopicsPerDay}'),
                    onTap: () => _editNewTopics(context, prefs),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Lĩnh vực yêu thích'),
                    trailing: Text(
                      prefs.favoriteCategories.isEmpty
                          ? 'Chưa đặt'
                          : '${prefs.favoriteCategories.length}',
                    ),
                    onTap: () => _editCategories(context, prefs),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Thông báo & AI', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Bật thông báo'),
                    value: prefs.notificationsEnabled,
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.alarm_outlined),
                    title: const Text('Giờ nhắc ôn tập'),
                    trailing: Text(
                      '${prefs.reminderHour.toString().padLeft(2, '0')}:${prefs.reminderMinute.toString().padLeft(2, '0')}',
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: const Text('Cấu hình AI'),
                    subtitle: Text(
                      context.read<AppServices>().ai.isRealProvider
                          ? 'Đang dùng AI thật (${prefs.aiModel})'
                          : 'Đang dùng mock AI — chưa cấu hình key',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editAi(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: const Text('Nhập văn bản'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TextImportScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.link_outlined),
                    title: const Text('Nhập từ liên kết web'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LinkImportScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Nhập từ ảnh (OCR)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => MediaImportFlow.fromImage(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: const Text('Nhập từ PDF'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => MediaImportFlow.fromPdf(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mic_none_outlined),
                    title: const Text('Nhập bằng giọng nói'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VoiceImportScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Cài đặt thông báo chi tiết'),
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
            const SizedBox(height: AppSpacing.xl),
            Text('Về ứng dụng', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'MindKeeper AI',
                    style: Theme.of(context).textTheme.titleSmall,
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
    final TextEditingController controller =
        TextEditingController(text: '${prefs.dailyGoal}');
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Lưu'),
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
    final TextEditingController controller =
        TextEditingController(text: '${prefs.newTopicsPerDay}');
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Lưu'),
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
        builder: (
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
                      final bool on = selected.contains(c);
                      return FilterChip(
                        label: Text(c),
                        selected: on,
                        onSelected: (bool value) {
                          setModalState(() {
                            if (value) {
                              selected.add(c);
                            } else {
                              selected.remove(c);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await prefs.setFavoriteCategories(selected);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Lưu'),
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
    final TextEditingController baseUrl =
        TextEditingController(text: prefs.aiBaseUrl);
    final TextEditingController apiKey =
        TextEditingController(text: prefs.aiApiKey);
    final TextEditingController model =
        TextEditingController(text: prefs.aiModel);
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cấu hình AI'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Để trống để dùng mock AI (nội dung mẫu, không gọi dịch vụ thật). '
                'Không lưu key vào mã nguồn.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: baseUrl,
                label: 'Base URL (OpenAI-compatible)',
                hint: 'https://api.openai.com/v1',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: apiKey,
                label: 'API key',
                obscureText: true,
                hint: 'sk-...',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: model, label: 'Model', hint: 'gpt-4o-mini'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await prefs.setAiConfig(
        baseUrl: baseUrl.text,
        apiKey: apiKey.text,
        model: model.text,
      );
      services.ai.configureFromSettings(
        baseUrl: prefs.aiBaseUrl,
        apiKey: prefs.aiApiKey,
        model: prefs.aiModel,
      );
      if (context.mounted) {
        showAppSnack(
          context,
          message: services.ai.isRealProvider
              ? 'Đã bật AI thật.'
              : 'Chưa có cấu hình AI — tiếp tục dùng mock.',
        );
      }
    }
    baseUrl.dispose();
    apiKey.dispose();
    model.dispose();
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
