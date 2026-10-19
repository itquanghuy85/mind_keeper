import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/enums.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/topic_repository.dart';
import 'create_topic_screen.dart';
import 'topic_detail_screen.dart';
import '../../core/theme/app_palette.dart';

enum _TopicFilter { all, mine, learned, favorite }

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key, this.reloadListenable});

  /// Nâng giá trị để yêu cầu reload (dùng khi dữ liệu đổi từ tab khác).
  final Listenable? reloadListenable;

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  _TopicFilter _filter = _TopicFilter.all;
  String _query = '';
  bool _loading = true;
  String? _error;
  List<Topic> _topics = const <Topic>[];
  Map<String, TopicStats> _stats = <String, TopicStats>{};

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
      final TopicOrigin? origin = switch (_filter) {
        _TopicFilter.mine => TopicOrigin.personal,
        _TopicFilter.learned => TopicOrigin.discovered,
        _TopicFilter.all || _TopicFilter.favorite => null,
      };
      List<Topic> topics = await services.topics.list(
        query: _query.isEmpty ? null : _query,
        origin: origin,
      );
      final Map<String, TopicStats> stats = await services.topics
          .statsForTopics(topics.map((Topic t) => t.id).toList());
      if (_filter == _TopicFilter.favorite) {
        // "Yêu thích" = chủ đề có kiến thức yêu thích — lọc bằng cách kiểm tra nhanh.
        final List<Topic> fav = <Topic>[];
        for (final Topic t in topics) {
          final List items = await services.knowledge.listByTopic(t.id);
          if (items.any((dynamic i) => (i as dynamic).isFavorite == true)) {
            fav.add(t);
          }
        }
        topics = fav;
      }
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _stats = <String, TopicStats>{
          for (final MapEntry<String, TopicStats> e in stats.entries)
            e.key: e.value,
        };
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

  Future<void> _create() async {
    final Topic? created = await Navigator.of(context).push<Topic>(
      MaterialPageRoute<Topic>(builder: (_) => const CreateTopicScreen()),
    );
    if (created != null && mounted) {
      await _openDetail(created.id);
    }
  }

  Future<void> _openDetail(String topicId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TopicDetailScreen(topicId: topicId),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chủ đề'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tạo chủ đề',
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppSearchField(
                onChanged: (String value) {
                  _query = value;
                  _load();
                },
                onClear: () {
                  _query = '';
                  _load();
                },
              ),
            ),

            // Bộ lọc
            SizedBox(
              height: AppSizes.chipHeight + 8,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  AppChip(
                    label: 'Tất cả',
                    selected: _filter == _TopicFilter.all,
                    onTap: () {
                      setState(() => _filter = _TopicFilter.all);
                      _load();
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Của tôi',
                    selected: _filter == _TopicFilter.mine,
                    onTap: () {
                      setState(() => _filter = _TopicFilter.mine);
                      _load();
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Đã khám phá',
                    selected: _filter == _TopicFilter.learned,
                    onTap: () {
                      setState(() => _filter = _TopicFilter.learned);
                      _load();
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: 'Yêu thích',
                    selected: _filter == _TopicFilter.favorite,
                    onTap: () {
                      setState(() => _filter = _TopicFilter.favorite);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const AppLoading(label: 'Đang tải chủ đề...');
    }
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }
    if (_topics.isEmpty) {
      return AppEmptyState(
        title: 'Chưa có chủ đề',
        message: 'Tạo chủ đề đầu tiên để bắt đầu lưu kiến thức.',
        icon: Icons.grid_view_rounded,
        actionLabel: 'Tạo chủ đề',
        onAction: _create,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        itemCount: _topics.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Topic topic = _topics[index];
          final TopicStats s =
              _stats[topic.id] ??
              const TopicStats(knowledgeCount: 0, dueCount: 0);
          return AppCard(
            semanticsLabel: 'Mở chủ đề ${topic.name}',
            onTap: () => _openDetail(topic.id),
            child: Row(
              children: <Widget>[
                const AppIconBadge(
                  icon: Icons.folder_rounded,
                  tone: AppIconTone.primary,
                  size: AppSizes.badgeMd,
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
                      Row(
                        children: <Widget>[
                          if (s.dueCount > 0) ...<Widget>[
                            AppTag(
                              label: '${s.dueCount} đến hạn',
                              tone: AppTagTone.warning,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Expanded(
                            child: Text(
                              '${s.knowledgeCount} kiến thức',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (topic.origin == TopicOrigin.discovered)
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.explore_rounded,
                      size: AppSizes.iconSm,
                      color: context.appColors.primary,
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.appColors.textTertiary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
