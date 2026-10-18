import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/topic_repository.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/lessons/lesson_discover_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/topics/topic_detail_screen.dart';

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
      final Map<String, TopicStats> stats = await services.topics.statsForTopics(
        all.map((Topic t) => t.id).toList(),
      );
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
      await _handlePendingNotification();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handlePendingNotification() async {
    if (_handledNotification || !mounted) return;
    final payload = AppBootstrap.instance.pendingNotificationPayload;
    if (payload == null) return;
    AppBootstrap.instance.pendingNotificationPayload = null;
    _handledNotification = true;
    if (payload.kind == 'card' && payload.cardId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewScreen(targetCardId: payload.cardId),
        ),
      );
    } else {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ReviewScreen()));
    }
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReviewScreen()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _buildBody(context)),
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

    final double goalProgress =
        _dailyGoal == 0 ? 0 : (_reviewsToday / _dailyGoal).clamp(0.0, 1.0);

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
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mỗi ngày nhớ thêm một chút',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            const Icon(
              Icons.event_rounded,
              size: AppSizes.iconSm,
              color: AppColors.textSecondary,
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
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.warning,
                  size: 28,
                ),
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
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _dueCount == 0
                          ? 'Tuyệt vời! Hãy quay lại sau khi có thẻ đến hạn.'
                          : '$_dueCount thẻ đang chờ bạn ôn tập.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '$_dueCount',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: AppColors.primary),
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
            backgroundColor: AppColors.surfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${(goalProgress * 100).round()}% đã hoàn thành',
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.right,
        ),

        const SizedBox(height: AppSpacing.xxl),

        // 3. Nhanh tập trung — 3 hành động chính
        AppSectionHeader(
          title: 'Nhanh tập trung',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _QuickActionCard(
                semanticsLabel: 'Bài học AI',
                icon: Icons.auto_awesome_rounded,
                iconColor: AppColors.info,
                iconBg: AppColors.infoSoft,
                title: 'Bài học AI',
                subtitle: 'Soạn bài + quiz ghi nhớ',
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
                iconBg: AppColors.successSoft,
                title: 'Tạo chủ đề',
                subtitle: 'Thêm kiến thức từ ghi chú',
                onTap: widget.onCreateTopic,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionCard(
                semanticsLabel: 'Khám phá chủ đề mới',
                icon: Icons.explore_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primarySoft,
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

        const SizedBox(height: AppSpacing.xxl),

        // 4. Chủ đề gần đây
        AppSectionHeader(
          title: 'Chủ đề gần đây',
          padding: EdgeInsets.zero,
        ),
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
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
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
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
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
