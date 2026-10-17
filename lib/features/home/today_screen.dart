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
      if (!mounted) return;
      setState(() {
        _dueCount = due;
        _reviewsToday = reviews;
        _dailyGoal = goal;
        _recentTopics = all.take(3).toList(growable: false);
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
            Text(
              _formatDate(_loadedAt ?? DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.warningSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Ôn kiến thức đến hạn',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _dueCount == 0
                              ? 'Không có thẻ nào đến hạn. Tuyệt vời!'
                              : 'Dành 5–10 phút để củng cố trí nhớ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_dueCount',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _dueCount == 0 ? 'Ôn lại ngẫu nhiên' : 'Bắt đầu ôn tập',
                icon: Icons.play_arrow_rounded,
                onPressed: _startReview,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(
          title: 'Chủ đề của tôi',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_recentTopics.isEmpty)
          AppCard(
            child: Text(
              'Bạn chưa có chủ đề nào. Tạo chủ đề đầu tiên để bắt đầu ghi nhớ.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ..._recentTopics.map(
            (Topic topic) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
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
                    Text(
                      topic.icon.isEmpty ? '📘' : topic.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        topic.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DiscoverScreen()),
            );
            if (mounted) await _load();
          },
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Khám phá chủ đề mới',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Đề xuất mỗi ngày theo lĩnh vực bạn quan tâm',
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
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LessonDiscoverScreen(),
              ),
            );
            if (mounted) await _load();
          },
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.infoSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Bài học AI',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Soạn bài + quiz ghi nhớ theo lĩnh vực bạn chọn',
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
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: widget.onCreateTopic,
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.success),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Tạo chủ đề của tôi',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Thêm kiến thức từ ghi chú, tài liệu',
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
      ],
    );
  }
}
