import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../data/models/lesson.dart';
import '../discover/domain_catalog.dart';
import 'lesson_reader_screen.dart';
import 'lesson_service.dart';
import 'topic_picker_sheet.dart';
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
    final TopicPickerResult? result = await showTopicPickerSheet(
      context: context,
      domain: domain,
      initialMode: _defaultMode,
    );
    if (result == null || !mounted) return;
    await _generateBatch(domain, result);
  }


  /// Tạo nhiều bài học cho các chủ đề đã chọn, có báo tiến độ từng bài.
  Future<void> _generateBatch(
    LearningDomain domain,
    TopicPickerResult selection,
  ) async {
    final AppServices services = context.read<AppServices>();
    final List<String> topics = selection.topics;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: AppLoading(label: 'Đang sinh bài học...'),
      ),
    );
    try {
      final List<BatchLessonResult> results = await services.lessonService
          .generateBatch(
            domain: domain,
            topics: topics,
            mode: selection.mode,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      final int ok = results.where((BatchLessonResult r) => r.success).length;
      final int failed = results.length - ok;
      showAppSnack(
        context,
        message: failed == 0
            ? 'Đã tạo $ok bài học.'
            : 'Đã tạo $ok bài học, $failed chủ đề lỗi.',
        success: failed == 0,
      );
      await _load();
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
