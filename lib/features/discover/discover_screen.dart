import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/models/topic.dart';
import '../topics/topic_detail_screen.dart';
import 'discovery_catalog.dart';
import 'discovery_service.dart';

/// Tab Khám phá: 1–3 chủ đề mới mỗi ngày; Học / Lưu / Bỏ qua.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _loading = true;
  String? _error;
  List<DiscoverySuggestion> _suggestions = const <DiscoverySuggestion>[];
  String? _categoryFilter;
  final Set<String> _savingIds = <String>{};

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
      List<DiscoverySuggestion> list = await services.discovery
          .suggestionsForToday();
      if (_categoryFilter != null) {
        list = list
            .where(
              (DiscoverySuggestion s) => s.entry.category == _categoryFilter,
            )
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _suggestions = list;
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

  Future<void> _save(DiscoverySuggestion suggestion) async {
    final AppServices services = context.read<AppServices>();
    if (_savingIds.contains(suggestion.entry.id)) return;
    setState(() => _savingIds.add(suggestion.entry.id));
    try {
      final Topic topic = await services.discovery.saveEntry(suggestion.entry);
      if (!mounted) return;
      showAppSnack(
        context,
        message: 'Đã lưu "${topic.name}" vào chủ đề — tham gia lịch ôn ngay.',
        success: true,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TopicDetailScreen(topicId: topic.id),
        ),
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) showAppSnack(context, message: e.toString(), error: true);
    } finally {
      if (mounted) {
        setState(() => _savingIds.remove(suggestion.entry.id));
      }
    }
  }

  Future<void> _learn(DiscoverySuggestion suggestion) async {
    final AppServices services = context.read<AppServices>();
    final Topic topic = await services.discovery.saveEntry(suggestion.entry);
    if (!mounted) return;
    // Học = lưu + mở kiến thức đầu tiên để đọc ngay.
    final items = await services.knowledge.listByTopic(topic.id);
    if (!mounted) return;
    if (items.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TopicDetailScreen(topicId: topic.id),
        ),
      );
    } else {
      showAppSnack(
        context,
        message: 'Đã lưu chủ đề "${topic.name}".',
        success: true,
      );
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khám phá chủ đề mới')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(label: 'Đang tải đề xuất...');
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        SizedBox(
          height: AppSizes.controlHeightSm + 8,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              _catChip(null),
              ...DiscoveryCatalog.categories.map(_catChip),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Đề xuất hôm nay', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Nội dung biên soạn offline, đánh dấu là đề xuất đã kiểm đính — '
          'không phải AI sinh thời gian thực.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_suggestions.isEmpty)
          AppEmptyState(
            title: 'Hết đề xuất hôm nay',
            message:
                'Ngày mai sẽ có gợi ý mới. Hoặc tăng số chủ đề mới mỗi ngày trong Cá nhân.',
            icon: Icons.explore_off_rounded,
          )
        else
          ..._suggestions.map(
            (DiscoverySuggestion s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        AppTag(label: s.entry.category),
                        const Spacer(),
                        if (s.isSaved)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      s.entry.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      s.entry.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${s.entry.items.length} kiến thức · ~${s.entry.minutes} phút',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton(
                            label: 'Học',
                            dense: true,
                            loading: _savingIds.contains(s.entry.id),
                            onPressed: () => _learn(s),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Lưu',
                            variant: AppButtonVariant.secondary,
                            dense: true,
                            onPressed: () => _save(s),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Bỏ qua',
                            variant: AppButtonVariant.tonal,
                            dense: true,
                            onPressed: () {
                              setState(() {
                                _suggestions = _suggestions
                                    .where(
                                      (DiscoverySuggestion x) =>
                                          x.entry.id != s.entry.id,
                                    )
                                    .toList();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Đổi gợi ý ngẫu nhiên',
          variant: AppButtonVariant.ghost,
          icon: Icons.shuffle_rounded,
          onPressed: _load,
        ),
      ],
    );
  }

  Widget _catChip(String? category) {
    final bool selected = _categoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: AppChip(
        label: category ?? 'Tất cả',
        selected: selected,
        onTap: () {
          setState(() => _categoryFilter = category);
          _load();
        },
      ),
    );
  }
}
