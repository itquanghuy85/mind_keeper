import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/models/course.dart';
import 'course_reader_screen.dart';

/// Chi tiết một khóa học: tiến độ, đề cương, đổi cấp độ, tạm dừng, xóa.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _loading = true;
  String? _error;
  Course? _course;
  List<CourseItem> _items = const <CourseItem>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final AppServices services = context.read<AppServices>();
    try {
      final Course? course = await services.courseRepo.getById(
        widget.courseId,
      );
      final List<CourseItem> items = course == null
          ? const <CourseItem>[]
          : await services.courseRepo.listItems(course.id);
      if (!mounted) return;
      setState(() {
        _course = course;
        _items = items;
        _loading = false;
        _error = course == null ? 'Khóa học không tồn tại.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeLevel(CourseLevel level) async {
    final AppServices services = context.read<AppServices>();
    await services.courseService.changeLevel(widget.courseId, level);
    AppBootstrap.instance.bumpDataVersion();
    await _load();
  }

  Future<void> _togglePause() async {
    final AppServices services = context.read<AppServices>();
    final Course c = _course!;
    await services.courseService.setStatus(
      c.id,
      c.status == CourseStatus.paused
          ? CourseStatus.active
          : CourseStatus.paused,
    );
    if (c.status == CourseStatus.paused) {
      unawaited(services.courseService.sync());
    }
    AppBootstrap.instance.bumpDataVersion();
    await _load();
  }

  Future<void> _delete() async {
    final NavigatorState nav = Navigator.of(context);
    final AppServices services = context.read<AppServices>();
    final bool ok = await showAppConfirmDialog(
      context,
      title: 'Xóa khóa học?',
      message:
          'Xóa đề cương và tiến độ khóa học này. Kiến thức đã lưu trong chủ đề '
          'vẫn được giữ lại.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    await services.courseService.deleteCourse(widget.courseId);
    AppBootstrap.instance.bumpDataVersion();
    nav.pop();
  }

  Future<void> _open(CourseItem item) async {
    if (!item.hasContent) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourseReaderScreen(itemId: item.id),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.name ?? 'Khóa học'),
        actions: <Widget>[
          if (_course != null)
            IconButton(
              tooltip: 'Xóa khóa học',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const AppLoading(label: 'Đang tải...');
    if (_error != null) return AppErrorState(message: _error, onRetry: _load);
    final Course c = _course!;
    final TextTheme text = Theme.of(context).textTheme;
    final int read = _items
        .where((CourseItem i) => i.status == CourseItemStatus.read)
        .length;
    final bool paused = c.status == CourseStatus.paused;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Đã đọc $read/${c.totalItems} mẩu', style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.pillAll,
                child: LinearProgressIndicator(
                  value: c.totalItems == 0 ? 0 : read / c.totalItems,
                  minHeight: 8,
                  backgroundColor: context.appColors.surfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Cấp độ', style: text.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final CourseLevel l in CourseLevel.values)
                    AppChip(
                      label: l.label,
                      selected: c.level == l,
                      onTap: () => _changeLevel(l),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Đổi cấp độ chỉ áp dụng cho các mẩu chưa được soạn.',
                style: text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: switch (c.status) {
                  CourseStatus.paused => 'Tiếp tục khóa học',
                  CourseStatus.done => 'Đã hoàn thành',
                  CourseStatus.active => 'Tạm dừng khóa học',
                },
                icon: paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                variant: AppButtonVariant.tonal,
                onPressed: c.status == CourseStatus.done ? null : _togglePause,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Đề cương', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final CourseItem item in _items)
          _itemTile(context, item),
      ],
    );
  }

  Widget _itemTile(BuildContext context, CourseItem item) {
    final TextTheme text = Theme.of(context).textTheme;
    final (IconData icon, Color color, String label) = switch (item.status) {
      CourseItemStatus.read => (
        Icons.check_circle_rounded,
        AppColors.success,
        'Đã đọc',
      ),
      CourseItemStatus.ready => (
        Icons.menu_book_rounded,
        AppColors.info,
        'Chưa đọc',
      ),
      CourseItemStatus.pending => (
        Icons.radio_button_unchecked_rounded,
        context.appColors.textTertiary,
        'Chưa soạn',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(
          '${item.position + 1}. ${item.title}',
          style: text.bodyMedium,
        ),
        subtitle: Text(label, style: text.bodySmall),
        trailing: item.hasContent
            ? const Icon(Icons.chevron_right_rounded)
            : null,
        onTap: item.hasContent ? () => _open(item) : null,
      ),
    );
  }
}
