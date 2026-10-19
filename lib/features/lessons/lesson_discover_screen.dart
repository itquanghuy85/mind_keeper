import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/lesson.dart';
import '../discover/domain_catalog.dart';
import 'lesson_reader_screen.dart';
import 'lesson_service.dart';
import '../../core/theme/app_palette.dart';

/// Khám phá kiến thức bằng bài học AI: chọn lĩnh vực → chủ đề → chế độ,
/// AI sinh bài trọn gói rồi mở màn đọc + quiz ghi nhớ.
class LessonDiscoverScreen extends StatefulWidget {
  const LessonDiscoverScreen({super.key});

  @override
  State<LessonDiscoverScreen> createState() => _LessonDiscoverScreenState();
}

class _LessonDiscoverScreenState extends State<LessonDiscoverScreen> {
  bool _loading = true;
  String? _error;
  List<Lesson> _lessons = const <Lesson>[];
  LessonMode _defaultMode = LessonMode.defaultMode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppServices services = context.read<AppServices>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Lesson> lessons = await services.lessons.list(limit: 100);
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _defaultMode = services.lessonService.defaultMode;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openDomain(LearningDomain domain) async {
    final TextEditingController topicCtrl = TextEditingController(
      text: domain.randomTopic(),
    );
    LessonMode mode = _defaultMode;

    final bool? confirmed = await showAppSheet<bool>(
      context: context,
      builder: (BuildContext sheetCtx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AppIconBadge(icon: domain.icon, radius: AppRadius.md),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        domain.name,
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                if (domain.isHealth) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    color: context.appColors.warningSoft,
                    border: AppColors.warning.withValues(alpha: 0.45),
                    child: Text(
                      'Nội dung về sức khỏe chỉ mang tính tham khảo, '
                      'không thay thế tư vấn y tế chuyên môn.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: context.appColors.warningText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: topicCtrl,
                  label: 'Chủ đề',
                  required: true,
                  hint: 'Ví dụ: ${domain.sampleTopics.first}',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Chủ đề ngẫu nhiên',
                    variant: AppButtonVariant.ghost,
                    dense: true,
                    expanded: false,
                    icon: Icons.shuffle_rounded,
                    onPressed: () =>
                        setSheet(() => topicCtrl.text = domain.randomTopic()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chế độ bài học',
                  style: Theme.of(ctx).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...LessonMode.values.map(
                  (LessonMode m) => _ModeTile(
                    mode: m,
                    selected: mode == m,
                    onTap: () => setSheet(() => mode = m),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton(
                        label: 'Hủy',
                        variant: AppButtonVariant.tonal,
                        dense: true,
                        onPressed: () => Navigator.of(sheetCtx).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: 'Tạo bài học',
                        icon: Icons.auto_awesome_rounded,
                        dense: true,
                        onPressed: () => Navigator.of(sheetCtx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final String topic = topicCtrl.text.trim();
    if (topic.isEmpty) {
      showAppSnack(
        context,
        message: 'Chủ đề không được để trống.',
        error: true,
      );
      return;
    }
    await _generate(domain, topic, mode);
  }

  Future<void> _generate(
    LearningDomain domain,
    String topic,
    LessonMode mode,
  ) async {
    final AppServices services = context.read<AppServices>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Dialog(child: AppLoading(label: 'Đang sinh bài học...')),
    );
    try {
      final GeneratedLesson result = await services.lessonService.generate(
        domain: domain,
        topic: topic,
        mode: mode,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LessonReaderScreen(lessonId: result.lesson.id),
        ),
      );
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, message: e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài học AI')),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(label: 'Đang tải...');
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        Text(
          'Chọn lĩnh vực để AI soạn bài học',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Bài được sinh trọn gói và lưu lại — cùng chủ đề không sinh lặp. '
          'Sau khi đọc, làm quiz ghi nhớ để đưa vào lịch ôn.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.05,
          children: <Widget>[
            for (final LearningDomain domain in LearningDomains.all)
              _DomainTile(domain: domain, onTap: () => _openDomain(domain)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: 'Bài học của tôi'),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            '${_lessons.length} bài đã lưu',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        if (_lessons.isEmpty)
          AppEmptyState(
            title: 'Chưa có bài học nào',
            message: 'Chọn một lĩnh vực ở trên để bắt đầu.',
            icon: Icons.menu_book_outlined,
          )
        else
          ..._lessons.map(
            (Lesson lesson) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LessonTile(
                lesson: lesson,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonReaderScreen(lessonId: lesson.id),
                    ),
                  );
                  if (mounted) await _load();
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _DomainTile extends StatelessWidget {
  const _DomainTile({required this.domain, required this.onTap});

  final LearningDomain domain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      semanticsLabel: 'Mở lĩnh vực ${domain.name}',
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIconBadge(
                icon: domain.icon,
                size: AppSizes.badgeSm,
                radius: AppRadius.md,
              ),
              const Spacer(),
              if (domain.isHealth)
                const Icon(
                  Icons.health_and_safety_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            domain.name,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Text(
              domain.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.onTap});

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      semanticsLabel: 'Mở bài học ${lesson.title}',
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lesson.isFavorite) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${lesson.mode.label} · ${lesson.domainName}'
                  '${lesson.isRead ? '' : ' · Chưa đọc'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            lesson.isRead ? Icons.chevron_right_rounded : Icons.circle_rounded,
            size: 18,
            color: lesson.isRead
                ? context.appColors.textTertiary
                : context.appColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final LessonMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        color: selected
            ? context.appColors.primarySoft
            : context.appColors.surface,
        border: selected ? context.appColors.primary : context.appColors.border,
        radius: AppRadius.lg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected
                    ? context.appColors.primary
                    : context.appColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mode.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
