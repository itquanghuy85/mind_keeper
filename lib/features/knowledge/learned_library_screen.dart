import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/review_card.dart';
import 'knowledge_detail_screen.dart';
import '../../core/theme/app_palette.dart';

class LearnedLibraryScreen extends StatefulWidget {
  const LearnedLibraryScreen({super.key});

  @override
  State<LearnedLibraryScreen> createState() => _LearnedLibraryScreenState();
}

enum _LearnedFilter { all, notRated, reviewing, due, completed }

enum _LearnedSort { startedAt, lastRead, dueSoon, priority }

class _LearnedItem {
  const _LearnedItem({required this.knowledgeItem, required this.cards});

  final KnowledgeItem knowledgeItem;
  final List<ReviewCard> cards;

  factory _LearnedItem.fromKnowledgeItem(
    KnowledgeItem item,
    List<ReviewCard> cards,
  ) {
    return _LearnedItem(knowledgeItem: item, cards: cards);
  }

  KnowledgeItem get item => knowledgeItem;
  String get id => knowledgeItem.id;
  String get title => knowledgeItem.title;
  String get content => knowledgeItem.content;
  String get details => knowledgeItem.details;
  DateTime? get startedAt => knowledgeItem.startedAt;
  DateTime get updatedAt => knowledgeItem.updatedAt;

  bool get hasNewCard => cards.any((c) => c.isNew);

  bool get isReviewing =>
      cards.any((c) => c.fsrsState == 0 || c.fsrsState == 2);

  bool get isDue {
    final DateTime now = DateTime.now().toUtc();
    return cards.any((c) => c.isDue(now));
  }

  bool get isCompleted {
    if (cards.isEmpty) return false;
    final DateTime now = DateTime.now().toUtc();
    return cards.every((c) => !c.isNew && !c.isDue(now));
  }

  DateTime? get earliestDue {
    if (cards.isEmpty) return null;
    final DateTime now = DateTime.now().toUtc();
    final dueCards = cards.where((c) => c.isDue(now)).toList(growable: false);
    if (dueCards.isEmpty) return null;
    return dueCards.reduce((a, b) => a.dueAt.isBefore(b.dueAt) ? a : b).dueAt;
  }
}

class _LearnedLibraryScreenState extends State<LearnedLibraryScreen> {
  List<_LearnedItem> _items = const <_LearnedItem>[];
  bool _loading = true;
  String? _error;
  String _query = '';
  _LearnedFilter _filter = _LearnedFilter.all;
  _LearnedSort _sortBy = _LearnedSort.startedAt;

  @override
  void initState() {
    super.initState();
    _load();
    AppBootstrap.instance.dataVersion.addListener(_load);
  }

  @override
  void dispose() {
    AppBootstrap.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final AppServices services = context.read<AppServices>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // search('') trả về rỗng → phải dùng listEnrolled để luôn có dữ liệu
      final List<KnowledgeItem> enrolledItems = await services.knowledge
          .listEnrolled(query: _query.isNotEmpty ? _query : null);

      final Map<String, List<ReviewCard>> cardsByItem =
          <String, List<ReviewCard>>{};
      for (final KnowledgeItem item in enrolledItems) {
        cardsByItem[item.id] = await services.cards.listByKnowledgeItem(
          item.id,
        );
      }

      List<_LearnedItem> learnedItems = enrolledItems
          .map((item) {
            return _LearnedItem.fromKnowledgeItem(
              item,
              cardsByItem[item.id] ?? const <ReviewCard>[],
            );
          })
          .toList(growable: false);

      List<_LearnedItem> filtered = _applyFilter(learnedItems);

      filtered = _applySort(filtered);

      if (!mounted) return;
      setState(() {
        _items = filtered;
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

  List<_LearnedItem> _applyFilter(List<_LearnedItem> items) {
    switch (_filter) {
      case _LearnedFilter.all:
        return items;
      case _LearnedFilter.notRated:
        // Chưa đánh giá = chưa có thẻ nào được chấm, hoặc item chưa có thẻ nào
        return items
            .where((item) => item.cards.isEmpty || item.hasNewCard)
            .toList(growable: false);
      case _LearnedFilter.reviewing:
        return items.where((item) => item.isReviewing).toList(growable: false);
      case _LearnedFilter.due:
        return items.where((item) => item.isDue).toList(growable: false);
      case _LearnedFilter.completed:
        return items.where((item) => item.isCompleted).toList(growable: false);
    }
  }

  List<_LearnedItem> _applySort(List<_LearnedItem> items) {
    final List<_LearnedItem> sorted = List<_LearnedItem>.from(items);
    final DateTime now = DateTime.now().toUtc();
    switch (_sortBy) {
      case _LearnedSort.startedAt:
        sorted.sort(
          (a, b) => (b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
        break;
      case _LearnedSort.lastRead:
        sorted.sort(
          (a, b) => (b.item.lastReadAt ?? b.startedAt ?? b.updatedAt).compareTo(
            a.item.lastReadAt ?? a.startedAt ?? a.updatedAt,
          ),
        );
        break;
      case _LearnedSort.dueSoon:
        sorted.sort((a, b) {
          final DateTime? aDue = a.earliestDue;
          final DateTime? bDue = b.earliestDue;
          if (aDue == null && bDue == null) return 0;
          if (aDue == null) return 1;
          if (bDue == null) return -1;
          return aDue.compareTo(bDue);
        });
        break;
      case _LearnedSort.priority:
        sorted.sort((a, b) {
          final int aPriority = _computePriority(a, now);
          final int bPriority = _computePriority(b, now);
          return bPriority.compareTo(aPriority);
        });
        break;
    }
    return sorted;
  }

  int _computePriority(_LearnedItem item, DateTime now) {
    int priority = 0;
    if (item.isDue) priority += 1000;
    if (item.isReviewing) priority += 500;
    if (item.hasNewCard) priority += 200;
    final ReviewCard? earliest = item.cards
        .where((c) => c.isDue(now))
        .fold<ReviewCard?>(
          null,
          (prev, card) =>
              prev == null || card.dueAt.isBefore(prev.dueAt) ? card : prev,
        );
    if (earliest != null) {
      if (earliest.difficulty != null) {
        priority += (earliest.difficulty! * 10).toInt();
      }
      if (earliest.stability != null) {
        priority -= (earliest.stability! / 10).toInt().clamp(0, 100);
      }
    }
    return priority;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho đã học'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Lỗi tải dữ liệu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: AppSearchField(
            hint: 'Tìm trong kho đã học...',
            onChanged: (value) {
              _query = value;
              _load();
            },
            onClear: () {
              _query = '';
              _load();
            },
          ),
        ),
        _buildFilterBar(),
        Expanded(
          child: _items.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxxl * 3,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) =>
                        _buildKnowledgeCard(_items[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: AppSizes.chipHeight + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _buildFilterChip('Tất cả', _LearnedFilter.all),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Chưa đánh giá', _LearnedFilter.notRated),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Đang ghi nhớ', _LearnedFilter.reviewing),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Đến hạn ôn', _LearnedFilter.due),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Đã hoàn thành', _LearnedFilter.completed),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<_LearnedSort>(
            onSelected: (value) {
              setState(() => _sortBy = value);
              _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _LearnedSort.startedAt,
                child: Text('Ngày bắt đầu'),
              ),
              const PopupMenuItem(
                value: _LearnedSort.lastRead,
                child: Text('Lần đọc gần nhất'),
              ),
              const PopupMenuItem(
                value: _LearnedSort.dueSoon,
                child: Text('Sắp đến hạn ôn'),
              ),
              const PopupMenuItem(
                value: _LearnedSort.priority,
                child: Text('Ưu tiên ôn'),
              ),
            ],
            child: AppChip(label: 'Sắp xếp ▼', selected: false, onTap: () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, _LearnedFilter value) {
    return AppChip(
      label: label,
      selected: _filter == value,
      onTap: () {
        setState(() => _filter = value);
        _load();
      },
    );
  }

  Widget _buildEmptyState() {
    final bool hasQuery = _query.isNotEmpty;
    if (hasQuery) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: context.appColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Không tìm thấy kết quả',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Thử từ khóa khác hoặc xóa bộ lọc.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 48,
                color: context.appColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chưa có bài trong Kho đã học',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mở đọc bài học lần đầu để tự động thêm vào đây.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Khám phá bài học',
                icon: Icons.explore_rounded,
                expanded: false,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.lessonDiscover),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildKnowledgeCard(_LearnedItem learnedItem) {
    final KnowledgeItem item = learnedItem.knowledgeItem;
    return AppCard(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => KnowledgeDetailScreen(itemId: item.id),
          ),
        );
        if (mounted) await _load();
      },
      child: _buildCardContent(item, learnedItem),
    );
  }

  Widget _buildCardContent(KnowledgeItem item, _LearnedItem learnedItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (item.isFavorite)
              const Icon(
                Icons.favorite_rounded,
                size: 18,
                color: AppColors.danger,
              ),
            if (item.isPaused)
              const Icon(
                Icons.pause_rounded,
                size: 18,
                color: AppColors.warning,
              ),
            if (item.isEnrolled)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.success,
              ),
            if (learnedItem.hasNewCard)
              AppTag(label: 'Mới', tone: AppTagTone.info),
            if (learnedItem.isDue && !learnedItem.hasNewCard)
              AppTag(label: 'Đến hạn', tone: AppTagTone.danger),
            if (learnedItem.isReviewing && !learnedItem.isDue)
              AppTag(label: 'Đang học', tone: AppTagTone.warning),
            if (learnedItem.isCompleted)
              AppTag(label: 'Hoàn thành', tone: AppTagTone.success),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (item.startedAt != null)
          Text(
            'Bắt đầu: ${_formatDate(item.startedAt!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textTertiary,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (item.details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              item.details,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
