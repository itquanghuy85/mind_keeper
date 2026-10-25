import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/notification_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../data/models/study_feed_item.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/topic_repository.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/knowledge/knowledge_detail_screen.dart';
import '../../features/lessons/lesson_discover_screen.dart';
import '../../features/lessons/lesson_reader_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/study/study_plan_service.dart';
import '../../features/topics/topic_detail_screen.dart';
import '../../core/theme/app_palette.dart';

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
  bool _loading = true;
  String? _error;
  int _dueCount = 0;
  int _reviewsToday = 0;
  int _dailyGoal = 10;
  List<Topic> _recentTopics = const <Topic>[];
  Map<String, TopicStats> _topicStats = <String, TopicStats>{};

  /// Nội dung hôm nay từ kế hoạch học (chỉ phần đã lưu xong) + tiêu đề đã
  /// phân giải sẵn.
  List<StudyFeedItem> _feedItems = const <StudyFeedItem>[];
  List<String> _feedTitles = const <String>[];
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

  Future<void> _load() async {
    final AppServices services = context.read<AppServices>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DateTime now = DateTime.now();
      final int due = await services.cards.countDue(now: now);
      final int reviews = await services.stats.reviewsToday(now: now);
      final int goal = services.prefs.dailyGoal;
      final List<Topic> all = await services.topics.list(limit: 20);
      all.sort((Topic a, Topic b) => b.updatedAt.compareTo(a.updatedAt));
      final Map<String, TopicStats> stats = await services.topics
          .statsForTopics(all.map((Topic t) => t.id).toList());
      if (!mounted) return;
      setState(() {
        _dueCount = due;
        _reviewsToday = reviews;
        _dailyGoal = goal;
        _recentTopics = all.take(3).toList(growable: false);
        _topicStats = stats;
        _loadedAt = now;
        _loading = false;
      });
      // Tải nội dung kế hoạch học RIÊNG bước sau: không giữ spinner chính
      // chờ thêm truy vấn (màn hình hiện ra trước, phần này tự điền sau).
      unawaited(_loadFeed(now));
      await _handlePendingNotification();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<String> _resolveFeedTitle(
    AppServices services,
    StudyFeedItem row,
  ) async {
    try {
      if (row.kind == StudyFeedKind.quick) {
        final item = await services.knowledge.getById(row.refId!);
        return item == null ? row.topicName : item.title;
      }
      final lesson = await services.lessons.getById(row.refId!);
      return lesson == null ? row.topicName : lesson.title;
    } catch (_) {
      return row.topicName;
    }
  }

  /// Tải nội dung hôm nay từ kế hoạch học (chỉ phần đã lưu xong — đọc được
  /// offline). Lỗi giữ nguyên danh sách cũ, không phá màn hình chính.
  Future<void> _loadFeed(DateTime now) async {
    try {
      final AppServices services = context.read<AppServices>();
      final List<StudyFeedItem> rows = (await services.studyPlan.listDay(now))
          .where((StudyFeedItem r) => r.status.hasContent && r.refId != null)
          .toList(growable: false);
      final List<String> titles = <String>[];
      for (final StudyFeedItem row in rows) {
        titles.add(await _resolveFeedTitle(services, row));
      }
      if (!mounted) return;
      setState(() {
        _feedItems = rows;
        _feedTitles = titles;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Tải nội dung hôm nay lỗi: $e');
    }
  }

  /// Kéo để làm mới: tải lại ngay + chạy đối soát kế hoạch học ở nền
  /// (khi đối soát xong tự tải lại lần nữa để hiện nội dung mới).
  Future<void> _refresh() async {
    final StudyPlanService plan = context.read<AppServices>().studyPlan;
    if (!plan.isSyncing) {
      plan.sync().then((_) {
        if (mounted) _load();
      }, onError: (_) {});
    }
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
    return '${weekdays[local.weekday - 1]}, ${local.day} tháng ${local.month}';
  }

  Future<void> _startReview() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ReviewScreen()));
    if (AppBootstrap.instance.isReady &&
        AppBootstrap.instance.services.prefs.notificationsEnabled) {
      unawaited(AppBootstrap.instance.refreshReminderSchedule());
    }
    if (mounted) await _load();
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

    final double goalProgress = _dailyGoal == 0
        ? 0
        : (_reviewsToday / _dailyGoal).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        // Header
        Text(
          'Chào bạn',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mỗi ngày nhớ thêm một chút',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Icon(
              Icons.event_rounded,
              size: AppSizes.iconSm,
              color: context.appColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                _formatDate(_loadedAt ?? DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        // 1. Kiến thức đến hạn — ưu tiên cao nhất
        AppSectionHeader(
          title: 'Ôn kiến thức đến hạn',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          semanticsLabel: '$_dueCount thẻ đến hạn',
          onTap: _startReview,
          child: Row(
            children: <Widget>[
              const AppIconBadge(
                icon: Icons.schedule_rounded,
                tone: AppIconTone.warning,
                size: 48,
                radius: AppRadius.xl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _dueCount == 0
                          ? 'Không có thẻ nào đến hạn'
                          : 'Dành 5–10 phút để củng cố trí nhớ',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _dueCount == 0
                          ? 'Tuyệt vời! Hãy quay lại sau khi có thẻ đến hạn.'
                          : '$_dueCount thẻ đang chờ bạn ôn tập.',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Số thẻ đến hạn là điểm nhấn — luôn giữ trên một dòng, không bị
              // nội dung bên trái đè lên (Row xếp widget non-flex trước).
              Text(
                '$_dueCount',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: context.appColors.primary,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: _dueCount == 0 ? 'Ôn lại ngẫu nhiên' : 'Bắt đầu ôn tập',
          icon: Icons.play_arrow_rounded,
          onPressed: _startReview,
        ),

        const SizedBox(height: AppSpacing.xxl),

        // 2. Tiến độ hôm nay
        AppSectionHeader(
          title: 'Tiến độ hôm nay',
          actionLabel: '$_reviewsToday/$_dailyGoal mục tiêu',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: LinearProgressIndicator(
            value: goalProgress,
            minHeight: 10,
            backgroundColor: context.appColors.surfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${(goalProgress * 100).round()}% đã hoàn thành',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFeatures: AppTheme.tabularFigures,
          ),
          textAlign: TextAlign.right,
        ),

        const SizedBox(height: AppSpacing.xxl),

        // 3. Nội dung hôm nay (kế hoạch học — bài đã lưu sẵn, đọc offline)
        if (_feedItems.isNotEmpty) ...<Widget>[
          AppSectionHeader(
            title: 'Nội dung hôm nay',
            actionLabel: '${_feedItems.length} mục',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._feedItems.asMap().entries.map(
            (MapEntry<int, StudyFeedItem> entry) {
              final StudyFeedItem row = entry.value;
              final String title = _feedTitles[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  semanticsLabel: title,
                  onTap: () => _openFeedItem(row),
                  child: Row(
                    children: <Widget>[
                      AppIconBadge(
                        icon: row.kind == StudyFeedKind.quick
                            ? Icons.bolt_rounded
                            : Icons.article_rounded,
                        tone: row.kind == StudyFeedKind.quick
                            ? AppIconTone.warning
                            : AppIconTone.primary,
                        size: AppSizes.badgeSm,
                        radius: AppRadius.md,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${row.kind == StudyFeedKind.quick ? 'Thông tin nhanh' : 'Bài viết'} · ${_feedStatusText(row)}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],

        // 4. Nhanh tập trung — 3 hành động chính
        AppSectionHeader(title: 'Nhanh tập trung', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.sm),
        // IntrinsicHeight + stretch: ba thẻ luôn cao bằng nhau dù mô tả dài
        // ngắn khác nhau hoặc font scale lớn (trước đây mỗi thẻ một chiều cao).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _QuickActionCard(
                  semanticsLabel: 'Bài học AI',
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppColors.info,
                  iconBg: context.appColors.infoSoft,
                  title: 'Bài học AI',
                  subtitle: 'Soạn bài + quiz',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LessonDiscoverScreen(),
                      ),
                    );
                    if (mounted) await _load();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionCard(
                  semanticsLabel: 'Tạo chủ đề của tôi',
                  icon: Icons.add_rounded,
                  iconColor: AppColors.success,
                  iconBg: context.appColors.successSoft,
                  title: 'Tạo chủ đề',
                  subtitle: 'Từ ghi chú của bạn',
                  onTap: widget.onCreateTopic,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionCard(
                  semanticsLabel: 'Khám phá chủ đề mới',
                  icon: Icons.explore_rounded,
                  iconColor: context.appColors.primary,
                  iconBg: context.appColors.primarySoft,
                  title: 'Khám phá',
                  subtitle: 'Lĩnh vực mới mỗi ngày',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiscoverScreen(),
                      ),
                    );
                    if (mounted) await _load();
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // 5. Chủ đề gần đây
        AppSectionHeader(title: 'Chủ đề gần đây', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.sm),
        if (_recentTopics.isEmpty)
          AppCard(
            semanticsLabel: 'Không có chủ đề',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bạn chưa có chủ đề nào.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tạo chủ đề đầu tiên để bắt đầu ghi nhớ kiến thức.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Tạo chủ đề đầu tiên',
                  icon: Icons.add_rounded,
                  onPressed: widget.onCreateTopic,
                ),
              ],
            ),
          )
        else
          ..._recentTopics.map(
            (Topic topic) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                semanticsLabel: 'Mở chủ đề ${topic.name}',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TopicDetailScreen(topicId: topic.id),
                    ),
                  );
                  if (mounted) await _load();
                },
                child: Row(
                  children: <Widget>[
                    const AppIconBadge(
                      icon: Icons.folder_rounded,
                      tone: AppIconTone.primary,
                      size: AppSizes.badgeSm,
                      radius: AppRadius.md,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            topic.name,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _statsForTopic(topic.id),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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
            ),
          ),
      ],
    );
  }

  String _feedStatusText(StudyFeedItem row) {
    if (row.status == StudyFeedStatus.delivered ||
        row.status == StudyFeedStatus.opened) {
      return 'Đã phát hành';
    }
    final DateTime at = context.read<AppServices>().studyPlan.slotTimeFor(row);
    final DateTime local = at.toLocal();
    return 'Dự kiến ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openFeedItem(StudyFeedItem row) async {
    final AppServices services = context.read<AppServices>();
    final String? refId = row.refId;
    if (refId == null) return;
    await services.studyPlan.markOpened(refId);
    if (!mounted) return;
    if (row.kind == StudyFeedKind.quick) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KnowledgeDetailScreen(itemId: refId),
        ),
      );
    } else {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => LessonReaderScreen(lessonId: refId)));
    }
    if (mounted) await _load();
  }

  String _statsForTopic(String topicId) {
    final s = _topicStats[topicId];
    if (s == null) return '';
    if (s.dueCount > 0) {
      return '${s.knowledgeCount} kiến thức · ${s.dueCount} đến hạn';
    }
    return '${s.knowledgeCount} kiến thức';
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.semanticsLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String semanticsLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Bố cục dọc: chịu được 3 card chia 1/3 màn hình + font scale lớn,
    // không tràn ngang như Row (icon + text + chevron) trước đây.
    return AppCard(
      semanticsLabel: semanticsLabel,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: AppIconBadge(
              icon: icon,
              color: iconColor,
              background: iconBg,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Tiêu đề cho phép 2 dòng: "Bài học AI" không bị cắt cụt ở font scale lớn.
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Mô tả: tối đa 2 dòng, giãn dòng nhẹ cho dễ đọc, câu chữ đã rút gọn
          // ở call site để không phải ellipsis ở cỡ chữ thường.
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.25),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
