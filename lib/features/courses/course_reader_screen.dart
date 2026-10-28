import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/memory_tip_card.dart';
import '../../data/models/course.dart';
import '../../data/models/knowledge_item.dart';
import 'course_service.dart';

/// Đọc một mẩu của khóa học. Bấm "Đã hiểu" để ghi nhận và đưa vào lịch ôn.
class CourseReaderScreen extends StatefulWidget {
  const CourseReaderScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<CourseReaderScreen> createState() => _CourseReaderScreenState();
}

class _CourseReaderScreenState extends State<CourseReaderScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Course? _course;
  CourseItem? _item;
  KnowledgeItem? _knowledge;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final AppServices services = context.read<AppServices>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final CourseItem? item = await services.courseRepo.getItem(widget.itemId);
      if (item == null) {
        throw StateError('Mẩu kiến thức không tồn tại.');
      }
      final Course? course = await services.courseRepo.getById(item.courseId);
      final KnowledgeItem? knowledge = item.knowledgeItemId == null
          ? null
          : await services.knowledge.getById(item.knowledgeItemId!);
      if (!mounted) return;
      setState(() {
        _item = item;
        _course = course;
        _knowledge = knowledge;
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

  Future<void> _markRead() async {
    final AppServices services = context.read<AppServices>();
    setState(() => _busy = true);
    try {
      await services.courseService.markRead(widget.itemId);
      if (AppBootstrap.instance.isReady &&
          services.prefs.notificationsEnabled) {
        unawaited(AppBootstrap.instance.refreshReminderSchedule());
      }
      AppBootstrap.instance.bumpDataVersion();
      if (!mounted) return;
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sinh và mở ngay mẩu kế tiếp của khóa (đọc trước, không chờ giờ phát hành).
  Future<void> _readNext() async {
    final AppServices services = context.read<AppServices>();
    final NavigatorState nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final CourseItem? next = await services.courseService.generateNext(
        _item!.courseId,
      );
      AppBootstrap.instance.bumpDataVersion();
      if (!mounted) return;
      if (next == null) {
        nav.pop();
        return;
      }
      await nav.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CourseReaderScreen(itemId: next.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busy = false);
    }
  }

  /// Báo nội dung AI sai/không phù hợp: sao chép báo cáo để gửi cho nhà phát
  /// triển và tạm dừng ôn mẩu này (không đưa kiến thức sai vào lịch ôn).
  Future<void> _reportContent() async {
    final KnowledgeItem? k = _knowledge;
    final CourseItem item = _item!;
    if (k == null) return;
    final AppServices services = context.read<AppServices>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    const List<String> reasons = <String>[
      'Kiến thức sai hoặc gây hiểu lầm',
      'Nội dung không phù hợp',
      'Khác',
    ];
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => SimpleDialog(
        title: const Text('Báo nội dung'),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Nội dung do AI soạn. Chọn lý do, báo cáo sẽ được sao chép để '
              'bạn gửi cho nhà phát triển; mẩu này sẽ tạm dừng ôn tập.',
            ),
          ),
          for (final String r in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(r),
              child: Text(r),
            ),
        ],
      ),
    );
    if (reason == null) return;
    final String report =
        'Báo nội dung MindKeeper\n'
        'Khóa học: ${_course?.name ?? ''} (${_course?.level.label ?? ''})\n'
        'Mẩu ${item.position + 1}: ${item.title}\n'
        'Lý do: $reason';
    await Clipboard.setData(ClipboardData(text: report));
    await services.knowledge.setPaused(k.id, paused: true);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép báo cáo và tạm dừng ôn mẩu này.'),
        behavior: SnackBarBehavior.floating,
        // Nổi phía trên nút "Đã hiểu" ở đáy, không che nút hành động.
        margin: EdgeInsets.fromLTRB(16, 0, 16, 96),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _course?.name ?? 'Mẩu kiến thức',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          if (_knowledge != null)
            IconButton(
              tooltip: 'Báo nội dung',
              onPressed: _reportContent,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const AppLoading(label: 'Đang tải...');
    if (_error != null) return AppErrorState(message: _error, onRetry: _load);
    final CourseItem item = _item!;
    final KnowledgeItem? knowledge = _knowledge;
    final TextTheme text = Theme.of(context).textTheme;
    final bool isRead = item.status == CourseItemStatus.read;
    final List<String> detailBlocks = (knowledge?.details ?? '')
        .split(RegExp(r'\n\s*\n'))
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);

    final Widget content = ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Text(
          'Mẩu ${item.position + 1}/${_course?.totalItems ?? '?'}'
          '${_course == null ? '' : ' · ${_course!.level.label}'}',
          style: text.labelMedium?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(item.title, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        if (knowledge == null)
          const AppCard(
            child: Text('Mẩu này chưa được soạn nội dung. Hãy quay lại sau.'),
          )
        else ...<Widget>[
          Text(
            knowledge.content,
            style: text.bodyLarge?.copyWith(height: 1.55),
          ),
          for (final String block in detailBlocks) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Text(block, style: text.bodyMedium?.copyWith(height: 1.5)),
            ),
          ],
          if (item.memoryTip.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            MemoryTipCard(tip: item.memoryTip),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                size: AppSizes.iconSm,
                color: context.appColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'AI tự soạn · $courseUnverifiedLabel',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
    // Nút hành động luôn hiện ở đáy (không phải cuộn mới thấy).
    final List<Widget> actions = <Widget>[
      if (knowledge != null && !isRead)
        AppButton(
          label: 'Đã hiểu',
          icon: Icons.check_rounded,
          loading: _busy,
          onPressed: _markRead,
        ),
      if (isRead) ...<Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Đã hiểu · kiến thức này sẽ quay lại để bạn ôn sau 1 ngày',
                style: text.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Đọc mẩu tiếp theo',
          icon: Icons.arrow_forward_rounded,
          variant: AppButtonVariant.tonal,
          loading: _busy,
          onPressed: _readNext,
        ),
      ],
    ];
    return Column(
      children: <Widget>[
        Expanded(child: content),
        if (actions.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ),
      ],
    );
  }
}
