import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/knowledge_generation.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/topic.dart';
import '../../features/knowledge/knowledge_detail_screen.dart';

/// Màn hình thư viện kiến thức của một chủ đề.
class KnowledgeLibraryScreen extends StatefulWidget {
  const KnowledgeLibraryScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<KnowledgeLibraryScreen> createState() => _KnowledgeLibraryScreenState();
}

enum _KnowledgeFilter { all, unread, read, due, failed }

class _KnowledgeLibraryScreenState extends State<KnowledgeLibraryScreen> {
  Topic? _topic;
  KnowledgeGenerationTask? _generationTask;
  List<KnowledgeItem> _items = const <KnowledgeItem>[];
  bool _loading = true;
  String? _error;
  String _query = '';
  _KnowledgeFilter _filter = _KnowledgeFilter.all;
  String _sortBy = 'learning_order'; // learning_order, created_desc, due_soon

  @override
  void initState() {
    super.initState();
    _load();
    _listenToGenerationUpdates();
  }

  void _listenToGenerationUpdates() {
    // Listen to data version changes to refresh
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
      final Topic? topic = await services.topics.getById(widget.topicId);
      if (topic == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Chủ đề không tồn tại.';
          _loading = false;
        });
        return;
      }

      final KnowledgeGenerationTask? task = await services
          .knowledgeGeneration
          .generationRepository
          .getByTopicId(widget.topicId);
      final List<KnowledgeItem> items = await services.knowledge.listByTopic(
        widget.topicId,
        query: _query.isEmpty ? null : _query,
      );

      // Lọc theo filter
      List<KnowledgeItem> filtered = _applyFilter(items);

      // Sắp xếp
      filtered = _applySort(filtered);

      if (!mounted) return;
      setState(() {
        _topic = topic;
        _generationTask = task;
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

  List<KnowledgeItem> _applyFilter(List<KnowledgeItem> items) {
    switch (_filter) {
      case _KnowledgeFilter.unread:
        return items.where((item) => !_isRead(item)).toList();
      case _KnowledgeFilter.read:
        return items.where((item) => _isRead(item)).toList();
      case _KnowledgeFilter.due:
        // Cần kiểm tra review cards để tìm bài đến hạn
        return items; // Simplified - cần implement check due
      case _KnowledgeFilter.failed:
        // Lọc bài lỗi (cần track riêng)
        return const <KnowledgeItem>[];
      case _KnowledgeFilter.all:
        return items;
    }
  }

  bool _isRead(KnowledgeItem item) {
    // Kiểm tra xem bài đã được đọc chưa - dùng isFavorite làm proxy hoặc cần field riêng
    return item
        .isFavorite; // Tạm dùng isFavorite, nên thêm field isRead vào KnowledgeItem
  }

  List<KnowledgeItem> _applySort(List<KnowledgeItem> items) {
    switch (_sortBy) {
      case 'created_desc':
        return List.from(items)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'due_soon':
        return items; // Cần implement
      case 'learning_order':
      default:
        return items; // Giữ thứ tự tạo (created_at ASC)
    }
  }

  Future<void> _retryGeneration() async {
    if (_generationTask == null || !_generationTask!.canRetry) return;
    final AppServices services = context.read<AppServices>();
    setState(() => _loading = true);
    try {
      await services.knowledgeGeneration.retryGeneration(widget.topicId);
      if (mounted) {
        showAppSnack(
          context,
          message: 'Đang thử lại sinh thư viện...',
          success: true,
        );
      }
    } catch (e) {
      if (mounted) showAppSnack(context, message: e.toString(), error: true);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_topic?.name ?? 'Thư viện kiến thức'),
        actions: <Widget>[
          if (_generationTask != null && _generationTask!.isGenerating)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  '${(_generationTask!.progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
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
    if (_loading) return const AppLoading(label: 'Đang tải thư viện...');
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }
    if (_topic == null) {
      return const AppErrorState(message: 'Chủ đề không tồn tại.');
    }

    return Column(
      children: <Widget>[
        // Thông tin chủ đề & tiến độ sinh
        _buildTopicHeader(),

        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: AppSearchField(
            hint: 'Tìm trong thư viện...',
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

        // Bộ lọc & sắp xếp
        _buildFilterBar(),

        // Danh sách kiến thức
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
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final KnowledgeItem item = _items[index];
                      return _buildKnowledgeCard(item);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTopicHeader() {
    final Topic topic = _topic!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (topic.icon.isEmpty)
                  const AppIconBadge(
                    icon: Icons.menu_book_rounded,
                    tone: AppIconTone.primary,
                    size: AppSizes.badgeLg,
                    radius: AppRadius.xl,
                  )
                else
                  Container(
                    width: AppSizes.badgeLg,
                    height: AppSizes.badgeLg,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      topic.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        topic.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (topic.category.isNotEmpty)
                        Text(
                          topic.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (!topic.isActive)
                  const Icon(
                    Icons.pause_circle_rounded,
                    color: AppColors.warning,
                  ),
              ],
            ),
            if (topic.description.isNotEmpty &&
                !topic.description.startsWith('catalog:')) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                topic.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_generationTask != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _buildGenerationProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationProgress() {
    final KnowledgeGenerationTask task = _generationTask!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: LinearProgressIndicator(
                value: task.totalPlanned > 0 ? task.progress : 0,
                backgroundColor: AppColors.primarySoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${task.completedCount}/${task.totalPlanned}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          task.isGenerating
              ? 'Đang sinh bài ${task.currentBatch}/${task.totalPlanned}...'
              : task.status == KnowledgeGenerationStatus.completed
              ? 'Hoàn tất! ${task.completedCount} bài đã sẵn sàng.'
              : task.status == KnowledgeGenerationStatus.failed
              ? 'Thất bại: ${task.lastError ?? 'Lỗi không xác định'}'
              : 'Đang chờ bắt đầu...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (task.canRetry) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Thử lại',
              variant: AppButtonVariant.ghost,
              dense: true,
              expanded: false,
              icon: Icons.refresh_rounded,
              onPressed: _retryGeneration,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: AppSizes.chipHeight + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          AppChip(
            label: 'Tất cả',
            selected: _filter == _KnowledgeFilter.all,
            onTap: () {
              setState(() => _filter = _KnowledgeFilter.all);
              _load();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          AppChip(
            label: 'Chưa đọc',
            selected: _filter == _KnowledgeFilter.unread,
            onTap: () {
              setState(() => _filter = _KnowledgeFilter.unread);
              _load();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          AppChip(
            label: 'Đã đọc',
            selected: _filter == _KnowledgeFilter.read,
            onTap: () {
              setState(() => _filter = _KnowledgeFilter.read);
              _load();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          AppChip(
            label: 'Đến hạn ôn',
            selected: _filter == _KnowledgeFilter.due,
            onTap: () {
              setState(() => _filter = _KnowledgeFilter.due);
              _load();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() => _sortBy = value);
              _load();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'learning_order',
                child: Text('Theo thứ tự học'),
              ),
              const PopupMenuItem<String>(
                value: 'created_desc',
                child: Text('Mới nhất trước'),
              ),
              const PopupMenuItem<String>(
                value: 'due_soon',
                child: Text('Sắp đến hạn ôn'),
              ),
            ],
            child: AppChip(label: 'Sắp xếp ▼', selected: false, onTap: () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_query.isNotEmpty) {
      return AppEmptyState(
        title: 'Không tìm thấy kết quả',
        message: 'Thử từ khóa khác hoặc xóa bộ lọc.',
        icon: Icons.search_off_rounded,
      );
    }
    if (_generationTask?.isGenerating == true) {
      return AppEmptyState(
        title: 'Đang sinh thư viện...',
        message: 'Vui lòng đợi trong giây lát. Bạn có thể thoát màn hình này.',
        icon: Icons.hourglass_empty_rounded,
      );
    }
    if (_generationTask?.status == KnowledgeGenerationStatus.failed) {
      return AppEmptyState(
        title: 'Sinh thư viện thất bại',
        message: _generationTask?.lastError ?? 'Không xác định nguyên nhân.',
        icon: Icons.error_outline_rounded,
        actionLabel: 'Thử lại',
        onAction: _retryGeneration,
      );
    }
    return AppEmptyState(
      title: 'Chưa có kiến thức',
      message: 'Thư viện đang được sinh tự động. Hãy quay lại sau vài phút.',
      icon: Icons.library_books_outlined,
    );
  }

  Widget _buildKnowledgeCard(KnowledgeItem item) {
    final bool isRead = _isRead(item);
    return AppCard(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => KnowledgeDetailScreen(itemId: item.id),
          ),
        );
        if (mounted) await _load();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
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
              if (isRead)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (item.details.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.details,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
