import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_chart_theme.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../data/repositories/stats_repository.dart';

enum _Range { d7, d30, all }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Range _range = _Range.d7;
  bool _loading = true;
  String? _error;
  OverallStats? _overall;
  List<DailyReviewStat> _daily = const <DailyReviewStat>[];
  List<TopicProgressStat> _topics = const <TopicProgressStat>[];
  int _newTopics = 0;

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
      final DateTime now = DateTime.now();
      final OverallStats overall = await services.stats.overall(now: now);
      final DateTime from = switch (_range) {
        _Range.d7 => now.subtract(const Duration(days: 7)),
        _Range.d30 => now.subtract(const Duration(days: 30)),
        _Range.all => DateTime(2000),
      };
      final List<DailyReviewStat> daily = await services.stats.dailyReviews(
        from: from,
        to: now,
      );
      final List<TopicProgressStat> topics = await services.stats
          .topicProgress();
      final int newTopics = await services.stats.newTopicsSince(from);
      if (!mounted) return;
      setState(() {
        _overall = overall;
        _daily = daily;
        _topics = topics;
        _newTopics = newTopics;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(label: 'Đang tải thống kê...');
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }
    final OverallStats stats = _overall!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          // Bộ lọc khoảng thời gian
          Row(
            children: <Widget>[
              _RangeChip(
                label: '7 ngày',
                selected: _range == _Range.d7,
                onTap: () {
                  setState(() => _range = _Range.d7);
                  _load();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _RangeChip(
                label: '30 ngày',
                selected: _range == _Range.d30,
                onTap: () {
                  setState(() => _range = _Range.d30);
                  _load();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _RangeChip(
                label: 'Tất cả',
                selected: _range == _Range.all,
                onTap: () {
                  setState(() => _range = _Range.all);
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Thẻ số liệu chính
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  title: 'Tổng chủ đề',
                  value: '${stats.topicCount}',
                  icon: Icons.folder_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  title: 'Kiến thức',
                  value: '${stats.knowledgeCount}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  title: 'Thẻ ôn tập',
                  value: '${stats.cardCount}',
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  title: 'Đến hạn',
                  value: '${stats.dueCount}',
                  icon: Icons.warning_amber_rounded,
                  color: stats.dueCount > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  title: 'Lượt ôn hôm nay',
                  value: '$_newTopics',
                  icon: Icons.event_available_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  title: 'Chính xác',
                  value: stats.totalReviews == 0
                      ? '-'
                      : '${(stats.accuracy * 100).round()}%',
                  icon: Icons.insights_rounded,
                  color: AppColors.ratingGood,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Lượt ôn theo thời gian
          AppSectionHeader(title: 'Lượt ôn theo thời gian'),
          AppCard(
            child: _daily.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Chưa có lượt ôn trong khoảng này.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildDailyBars(),
                  ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Đánh giá nhớ
          AppSectionHeader(title: 'Đánh giá nhớ'),
          AppCard(
            child: Column(
              children: <Widget>[
                _RatingRow(
                  label: 'Quên',
                  value: stats.againCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingAgain,
                  tone: AppTagTone.danger,
                ),
                _RatingRow(
                  label: 'Khó',
                  value: stats.hardCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingHard,
                  tone: AppTagTone.warning,
                ),
                _RatingRow(
                  label: 'Tốt',
                  value: stats.goodCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingGood,
                  tone: AppTagTone.primary,
                ),
                _RatingRow(
                  label: 'Dễ',
                  value: stats.easyCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingEasy,
                  tone: AppTagTone.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Tiến độ theo chủ đề
          AppSectionHeader(title: 'Tiến độ theo chủ đề'),
          if (_topics.isEmpty)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Chưa có chủ đề để hiển thị tiến độ.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Column(
              children: <Widget>[
                ..._topics.take(10).map((TopicProgressStat t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      semanticsLabel: 'Tiến độ chủ đề ${t.topicName}',
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                if (t.icon.isNotEmpty) ...<Widget>[
                                  const AppIconBadge(
                                    icon: Icons.folder_rounded,
                                    tone: AppIconTone.primary,
                                    size: AppSizes.badgeSm,
                                    radius: AppRadius.md,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        t.topicName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '${t.reviewedCards}/${t.totalCards} thẻ đã ôn',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ClipRRect(
                              borderRadius: AppRadius.pillAll,
                              child: LinearProgressIndicator(
                                value: t.progress,
                                minHeight: 8,
                                backgroundColor: AppChartTheme.progressTrack(
                                  context,
                                ),
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${(t.progress * 100).round()}%',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontFeatures: AppTheme.tabularFigures,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (_topics.length > 10)
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: Text(
                          'Và ${_topics.length - 10} chủ đề khác...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  List<Widget> _buildDailyBars() {
    final int maxDaily = _daily.fold<int>(
      0,
      (int acc, DailyReviewStat s) => s.count > acc ? s.count : acc,
    );
    final List<Widget> bars = <Widget>[];
    final List<String> weekdays = <String>[
      'CN',
      'Th2',
      'Th3',
      'Th4',
      'Th5',
      'Th6',
      'Th7',
    ];
    for (final DailyReviewStat s in _daily) {
      final double h = maxDaily == 0 ? 0 : (s.count / maxDaily) * 100;
      final String dayLabel = weekdays[s.day.weekday % 7];
      bars.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${s.count}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: h < AppChartTheme.minBarHeight
                  ? AppChartTheme.minBarHeight
                  : h,
              width: AppChartTheme.barWidth,
              decoration: BoxDecoration(
                color: AppChartTheme.lineColor(context),
                borderRadius: BorderRadius.circular(AppChartTheme.barRadius),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(dayLabel, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
    }
    return bars;
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppChip(label: label, selected: selected, onTap: onTap);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            AppIconBadge(
              icon: icon,
              color: color,
              background: color.withValues(alpha: 0.12),
              size: 42,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.tone,
  });

  final String label;
  final int value;
  final int total;
  final Color color;
  final AppTagTone tone;

  @override
  Widget build(BuildContext context) {
    final double ratio = total == 0 ? 0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 48,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              AppTag(label: '$value', tone: tone),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: color,
              backgroundColor: AppChartTheme.progressTrack(context),
            ),
          ),
        ],
      ),
    );
  }
}
