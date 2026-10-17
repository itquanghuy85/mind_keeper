import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_feedback.dart';
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
      final List<DailyReviewStat> daily =
          await services.stats.dailyReviews(from: from, to: now);
      final List<TopicProgressStat> topics = await services.stats.topicProgress();
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
    final int maxDaily = _daily.fold<int>(
      0,
      (int acc, DailyReviewStat s) => s.count > acc ? s.count : acc,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
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
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  title: 'Đã ôn tập',
                  value: '${stats.totalReviews}',
                  icon: Icons.event_available_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Chủ đề mới',
                  value: '$_newTopics',
                  icon: Icons.explore_rounded,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  title: 'Đến hạn',
                  value: '${stats.dueCount}',
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Quá hạn',
                  value: '${stats.overdueCount}',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Kết quả ôn theo thời gian', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: _daily.isEmpty
                ? Text(
                    'Chưa có lượt ôn trong khoảng này.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _daily.map((DailyReviewStat s) {
                        final double h = maxDaily == 0
                            ? 0
                            : (s.count / maxDaily) * 110;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  '${s.count}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: h < 4 ? 4 : h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Đánh giá nhớ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: <Widget>[
                _RatingRow(
                  label: 'Quên',
                  value: stats.againCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingAgain,
                ),
                _RatingRow(
                  label: 'Khó',
                  value: stats.hardCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingHard,
                ),
                _RatingRow(
                  label: 'Tốt',
                  value: stats.goodCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingGood,
                ),
                _RatingRow(
                  label: 'Dễ',
                  value: stats.easyCount,
                  total: stats.totalReviews,
                  color: AppColors.ratingEasy,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Tiến độ theo chủ đề', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (_topics.isEmpty)
            AppCard(
              child: Text(
                'Chưa có chủ đề để hiển thị tiến độ.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            AppCard(
              child: Column(
                children: _topics.map((TopicProgressStat t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            if (t.icon.isNotEmpty) ...<Widget>[
                              Text(t.icon),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Expanded(
                              child: Text(
                                t.topicName,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(t.progress * 100).round()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: AppRadius.pillAll,
                          child: LinearProgressIndicator(
                            value: t.progress,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Tổng quan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: <Widget>[
                _KV('Số chủ đề', '${stats.topicCount}'),
                _KV('Số kiến thức', '${stats.knowledgeCount}'),
                _KV('Số thẻ ghi nhớ', '${stats.cardCount}'),
                _KV(
                  'Tỉ lệ nhớ lại (ước tính)',
                  stats.totalReviews == 0
                      ? '—'
                      : '${(stats.accuracy * 100).round()}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Số liệu được tính trực tiếp từ dữ liệu ôn tập của bạn.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
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
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: AppRadius.pillAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(title, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
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
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double ratio = total == 0 ? 0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: color,
                backgroundColor: AppColors.surfaceMuted,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(k, style: Theme.of(context).textTheme.bodySmall)),
          Text(v, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
