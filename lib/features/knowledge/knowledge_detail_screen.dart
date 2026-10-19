import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/review_card.dart';
import '../ai/ai_provider.dart';
import 'knowledge_editor_screen.dart';
import '../../core/theme/app_palette.dart';

class KnowledgeDetailScreen extends StatefulWidget {
  const KnowledgeDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<KnowledgeDetailScreen> createState() => _KnowledgeDetailScreenState();
}

class _KnowledgeDetailScreenState extends State<KnowledgeDetailScreen> {
  bool _loading = true;
  String? _error;
  KnowledgeItem? _item;
  List<ReviewCard> _cards = const <ReviewCard>[];
  bool _tutorBusy = false;
  String? _tutorNote;

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
      final KnowledgeItem? item = await services.knowledge.getById(
        widget.itemId,
      );
      if (item == null) {
        setState(() {
          _error = 'Kiến thức không tồn tại.';
          _loading = false;
        });
        return;
      }
      final List<ReviewCard> cards = await services.cards.listByKnowledgeItem(
        widget.itemId,
      );
      if (!mounted) return;
      setState(() {
        _item = item;
        _cards = cards;
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

  Future<void> _toggleFavorite() async {
    final AppServices services = context.read<AppServices>();
    await services.knowledge.toggleFavorite(
      widget.itemId,
      value: !_item!.isFavorite,
    );
    await _load();
  }

  Future<void> _togglePause() async {
    final AppServices services = context.read<AppServices>();
    await services.knowledge.setPaused(widget.itemId, paused: !_item!.isPaused);
    await _load();
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KnowledgeEditorScreen(itemId: widget.itemId),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _delete() async {
    final bool ok = await showAppConfirmDialog(
      context,
      title: 'Xoá kiến thức?',
      message:
          'Xoá kiến thức này cùng toàn bộ thẻ ôn và lịch sử ôn. Không thể hoàn tác.',
      confirmLabel: 'Xoá',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final AppServices services = context.read<AppServices>();
    await services.knowledge.delete(widget.itemId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _askTutor() async {
    if (_cards.isEmpty) return;
    final AppServices services = context.read<AppServices>();
    setState(() {
      _tutorBusy = true;
      _tutorNote = null;
    });
    try {
      final AiTutorExplanation explanation = await services.ai.explain(
        question: _cards.first.question,
        answer: _cards.first.answer,
      );
      if (!mounted) return;
      setState(() {
        _tutorNote = services.ai.isRealProvider
            ? explanation.explanation
            : '${explanation.explanation}\n(mock AI — chưa cấu hình dịch vụ thật)';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _tutorNote = 'Không thể giải thích lúc này: $e');
      }
    } finally {
      if (mounted) setState(() => _tutorBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết kiến thức'),
        actions: <Widget>[
          IconButton(
            tooltip: _item?.isFavorite == true ? 'Bỏ yêu thích' : 'Yêu thích',
            onPressed: _loading ? null : _toggleFavorite,
            icon: Icon(
              _item?.isFavorite == true
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              color: _item?.isFavorite == true ? AppColors.danger : null,
            ),
          ),
          IconButton(
            tooltip: 'Sửa',
            onPressed: _loading ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Xoá',
            onPressed: _loading ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading();
    if (_error != null || _item == null) {
      return AppErrorState(message: _error, onRetry: _load);
    }
    final KnowledgeItem item = _item!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Nội dung', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(item.content),
              if (item.details.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Chi tiết',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(item.details),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: item.isPaused ? 'Bỏ tạm ngưng' : 'Tạm ngưng ôn',
                variant: AppButtonVariant.tonal,
                dense: true,
                onPressed: _togglePause,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: 'Hỏi AI gia sư',
                variant: AppButtonVariant.secondary,
                dense: true,
                loading: _tutorBusy,
                onPressed: _cards.isEmpty ? null : _askTutor,
              ),
            ),
          ],
        ),
        if (_tutorNote != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: context.appColors.infoSoft,
            border: AppColors.info.withValues(alpha: 0.45),
            child: Text(
              _tutorNote!,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(
          title: 'Thẻ ôn tập (${_cards.length})',
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        if (_cards.isEmpty)
          AppCard(
            child: Text(
              'Chưa có thẻ ôn. Thêm kiến thức kèm câu hỏi để tham gia lịch ôn.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ..._cards.map(
            (ReviewCard card) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      card.question,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      card.answer,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      card.isNew
                          ? 'Thẻ mới — đến hạn ngay'
                          : 'Ôn tiếp theo: ${card.dueAt.toLocal()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
