import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/notification_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/models/course.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/lesson.dart';
import '../../data/models/study_feed_item.dart';
import '../../features/courses/add_course_screen.dart';
import '../../features/courses/course_detail_screen.dart';
import '../../features/courses/course_reader_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/knowledge/knowledge_detail_screen.dart';
import '../../features/lessons/lesson_discover_screen.dart';
import '../../features/lessons/lesson_reader_screen.dart';
import '../../features/review/review_screen.dart';

/// Một mục "chưa đọc" trên trang chủ (mẩu khóa học hoặc nội dung kế hoạch cũ).
class _UnreadEntry {
  const _UnreadEntry({
    required this.topic,
    required this.title,
    required this.minutes,
    required this.open,
    this.level,
  });

  final String topic;
  final String? level;
  final String title;
  final int minutes;
  final Future<void> Function() open;
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.onCreateTopic, this.reloadListenable});

  /// Điều hướng tạo chủ đề (shell xử lý — tránh Navigator lồng tab).
  final VoidCallback? onCreateTopic;

  /// Nâng giá trị để yêu cầu reload khi dữ liệu đổi từ tab khác.
  final Listenable? reloadListenable;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  static const int _collapsedUnread = 3;

  bool _loading = true;
  String? _error;
  int _dueCount = 0;
  List<_UnreadEntry> _unread = const <_UnreadEntry>[];
  List<CourseProgress> _courses = const <CourseProgress>[];
  bool _showAllUnread = false;
  bool _readingAhead = false;
  DateTime? _loadedAt;
  bool _handledNotification = false;

  @override
  void initState() {
    super.initState();
    widget.reloadListenable?.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.reloadListenable?.removeListener(_load);
    super.dispose();
  }

  static int _minutesFor(String text) {
    final int words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final int minutes = (words / 160).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  Future<void> _load() async {
    final AppServices services = context.read<AppServices>();
    if (_loadedAt == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final DateTime now = DateTime.now();
      final int due = await services.cards.countDue(now: now);
      final List<CourseProgress> courses = await services.courseService
          .progress();
      final List<_UnreadEntry> unread = await _loadUnread(services, now);
      if (!mounted) return;
      setState(() {
        _dueCount = due;
        _courses = courses;
        _unread = unread;
        _loadedAt = now;
        _loading = false;
        _error = null;
      });
      await _handlePendingNotification();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Mẩu khóa học đã đến giờ + nội dung kế hoạch cũ đã phát hành mà chưa mở.
  Future<List<_UnreadEntry>> _loadUnread(
    AppServices services,
    DateTime now,
  ) async {
    final List<_UnreadEntry> entries = <_UnreadEntry>[];
    for (final CourseItemEntry e in await services.courseService.unread(
      now: now,
    )) {
      final KnowledgeItem? k = e.item.knowledgeItemId == null
          ? null
          : await services.knowledge.getById(e.item.knowledgeItemId!);
      entries.add(
        _UnreadEntry(
          topic: e.course.name,
          level: e.course.level.label,
          title: e.item.title,
          minutes: _minutesFor(k?.content ?? e.item.summary),
          open: () => _openRoute(CourseReaderScreen(itemId: e.item.id)),
        ),
      );
    }
    try {
      final List<StudyFeedItem> rows = await services.studyPlan.listDay(now);
      for (final StudyFeedItem row in rows) {
        if (row.status != StudyFeedStatus.delivered || row.refId == null) {
          continue;
        }
        final String refId = row.refId!;
        if (row.kind == StudyFeedKind.quick) {
          final KnowledgeItem? k = await services.knowledge.getById(refId);
          if (k == null) continue;
          entries.add(
            _UnreadEntry(
              topic: row.topicName,
              title: k.title,
              minutes: _minutesFor(k.content),
              open: () async {
                await services.studyPlan.markOpened(refId);
                if (!mounted) return;
                await _openRoute(KnowledgeDetailScreen(itemId: refId));
              },
            ),
          );
        } else {
          final Lesson? l = await services.lessons.getById(refId);
          if (l == null) continue;
          entries.add(
            _UnreadEntry(
              topic: row.topicName,
              title: l.title,
              minutes: l.wordCount > 0 ? _minutesFor('x ' * l.wordCount) : 4,
              open: () async {
                await services.studyPlan.markOpened(refId);
                if (!mounted) return;
                await _openRoute(LessonReaderScreen(lessonId: refId));
              },
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Tải nội dung kế hoạch lỗi: $e');
    }
    return entries;
  }

  Future<void> _openRoute(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _load();
  }

  /// Kéo để làm mới: tải lại ngay + đối soát kế hoạch/khóa học ở nền.
  Future<void> _refresh() async {
    unawaited(
      AppBootstrap.instance.refreshStudyPlan().then((_) {
        if (mounted) _load();
      }, onError: (_) {}),
    );
    await _load();
  }

  Future<void> _handlePendingNotification() async {
    if (_handledNotification || !mounted) return;
    final payload = AppBootstrap.instance.pendingNotificationPayload;
    if (payload == null) return;
    AppBootstrap.instance.pendingNotificationPayload = null;
    _handledNotification = true;
    final AppServices services = context.read<AppServices>();
    await NotificationRouter.handle(
      context: context,
      services: services,
      payload: payload,
      isColdStart: true,
    );
    if (mounted) await _load();
  }

  String _formatDate(DateTime date) {
    const List<String> weekdays = <String>[
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final DateTime local = date.toLocal();
    return '${weekdays[local.weekday - 1]}, ${local.day}/${local.month}';
  }

  Future<void> _startReview() => _openRoute(const ReviewScreen()).then((_) {
    if (AppBootstrap.instance.isReady &&
        AppBootstrap.instance.services.prefs.notificationsEnabled) {
      unawaited(AppBootstrap.instance.refreshReminderSchedule());
    }
  });

  /// Nút chính: đi lần lượt — mẩu mới trước, hết thì sang ôn tập.
  Future<void> _startNext() async {
    if (_unread.isNotEmpty) {
      await _unread.first.open();
    } else if (_dueCount > 0) {
      await _startReview();
    }
  }

  /// Đọc trước: sinh ngay mẩu kế tiếp của khóa chưa xong (không chờ giờ).
  Future<void> _readAhead() async {
    final AppServices services = context.read<AppServices>();
    CourseProgress? target;
    for (final CourseProgress p in _courses) {
      if (!p.isDone && p.course.status == CourseStatus.active) {
        target = p;
        break;
      }
    }
    if (target == null) return;
    setState(() => _readingAhead = true);
    try {
      final CourseItem? item = await services.courseService.generateNext(
        target.course.id,
      );
      if (!mounted) return;
      if (item != null) {
        await _openRoute(CourseReaderScreen(itemId: item.id));
      } else {
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _readingAhead = false);
    }
  }

  Future<void> _addCourse() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddCourseScreen()),
    );
    if (created == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _refresh, child: _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const AppLoading(label: 'Đang tải hôm nay...');
    }
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }
    final TextTheme text = Theme.of(context).textTheme;
    final List<CourseProgress> ordered = <CourseProgress>[
      ..._courses.where((CourseProgress p) => !p.isDone),
      ..._courses.where((CourseProgress p) => p.isDone),
    ];
    final List<_UnreadEntry> shown = _showAllUnread
        ? _unread
        : _unread.take(_collapsedUnread).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _formatDate(_loadedAt ?? DateTime.now()),
                style: text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _AddMenu(
              onAddCourse: _addCourse,
              onLessons: () => _openRoute(const LessonDiscoverScreen()),
              onCreateTopic: widget.onCreateTopic,
              onDiscover: () => _openRoute(const DiscoverScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _mainCard(context),
        if (_unread.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxl),
          AppSectionHeader(
            title: 'Chưa đọc',
            actionLabel: _unread.length > _collapsedUnread
                ? (_showAllUnread ? 'Thu gọn' : 'Xem tất cả (${_unread.length})')
                : null,
            onAction: _unread.length > _collapsedUnread
                ? () => setState(() => _showAllUnread = !_showAllUnread)
                : null,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final _UnreadEntry entry in shown) _unreadTile(context, entry),
        ],
        if (ordered.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxl),
          AppSectionHeader(title: 'Đang theo', padding: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.sm),
          for (final CourseProgress p in ordered) _courseTile(context, p),
        ],
      ],
    );
  }

  Widget _mainCard(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int unread = _unread.length;
    final int minutes =
        _unread.fold<int>(0, (int sum, _UnreadEntry e) => sum + e.minutes) +
        (_dueCount * 0.5).ceil();
    final bool hasWork = unread > 0 || _dueCount > 0;
    final bool hasActiveCourse = _courses.any(
      (CourseProgress p) =>
          !p.isDone && p.course.status == CourseStatus.active,
    );

    if (hasWork) {
      final List<String> parts = <String>[
        if (unread > 0) '$unread mẩu mới',
        if (_dueCount > 0) '$_dueCount thẻ ôn',
      ];
      return AppCard(
        elevated: true,
        semanticsLabel: 'Hôm nay bạn còn ${parts.join(' và ')}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'HÔM NAY BẠN CÒN',
              style: text.labelMedium?.copyWith(
                color: context.appColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              parts.join(' · '),
              style: text.headlineSmall?.copyWith(
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('≈ $minutes phút', style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Bắt đầu',
              icon: Icons.play_arrow_rounded,
              onPressed: _startNext,
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return AppCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Học một chủ đề mới', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chọn chủ đề và cấp độ, AI sẽ soạn lộ trình rồi nhắc bạn đọc '
              'từng mẩu mỗi ngày.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Thêm khóa học',
              icon: Icons.add_rounded,
              onPressed: _addCourse,
            ),
          ],
        ),
      );
    }

    return AppCard(
      elevated: true,
      semanticsLabel: 'Xong cho hôm nay',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Xong cho hôm nay', style: text.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasActiveCourse
                ? 'Mẩu kế tiếp sẽ đến theo giờ đã đặt.'
                : 'Các khóa học đã hoàn thành hoặc đang tạm dừng.',
            style: text.bodyMedium,
          ),
          if (hasActiveCourse) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Đọc trước mẩu kế tiếp',
              icon: Icons.fast_forward_rounded,
              variant: AppButtonVariant.tonal,
              loading: _readingAhead,
              onPressed: _readAhead,
            ),
          ] else ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Thêm khóa học',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.tonal,
              onPressed: _addCourse,
            ),
          ],
        ],
      ),
    );
  }

  Widget _unreadTile(BuildContext context, _UnreadEntry entry) {
    final TextTheme text = Theme.of(context).textTheme;
    final String header = entry.level == null
        ? entry.topic
        : '${entry.topic} · ${entry.level}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        semanticsLabel: '$header. ${entry.title}. ${entry.minutes} phút',
        onTap: () => entry.open(),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    header,
                    style: text.labelMedium?.copyWith(
                      color: context.appColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.title,
                    style: text.titleSmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${entry.minutes} phút', style: text.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseTile(BuildContext context, CourseProgress p) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool paused = p.course.status == CourseStatus.paused;
    final String progress = '${p.readCount}/${p.total}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        semanticsLabel:
            'Khóa ${p.course.name}, ${p.course.level.label}, đã đọc $progress',
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        onTap: () => _openRoute(CourseDetailScreen(courseId: p.course.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    p.course.name,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  paused
                      ? 'Tạm dừng'
                      : (p.isDone ? 'Hoàn thành' : p.course.level.label),
                  style: text.labelMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.pillAll,
                    child: LinearProgressIndicator(
                      value: p.fraction,
                      minHeight: 8,
                      backgroundColor: context.appColors.surfaceMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  progress,
                  style: text.labelMedium?.copyWith(
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút [+] ở đầu trang: gom các lối tắt ít dùng hằng ngày vào một menu.
class _AddMenu extends StatelessWidget {
  const _AddMenu({
    required this.onAddCourse,
    required this.onLessons,
    required this.onCreateTopic,
    required this.onDiscover,
  });

  final VoidCallback onAddCourse;
  final VoidCallback onLessons;
  final VoidCallback? onCreateTopic;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Thêm',
      icon: const Icon(Icons.add_circle_rounded, size: 32),
      color: context.appColors.surface,
      onSelected: (int value) {
        switch (value) {
          case 0:
            onAddCourse();
          case 1:
            onLessons();
          case 2:
            onCreateTopic?.call();
          case 3:
            onDiscover();
        }
      },
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<int>>[
        PopupMenuItem<int>(value: 0, child: Text('Thêm khóa học')),
        PopupMenuItem<int>(value: 1, child: Text('Bài học AI')),
        PopupMenuItem<int>(value: 2, child: Text('Tạo chủ đề')),
        PopupMenuItem<int>(value: 3, child: Text('Khám phá')),
      ],
    );
  }
}
