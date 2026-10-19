import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/topic.dart';
import '../../features/knowledge/knowledge_detail_screen.dart';
import '../../features/knowledge/knowledge_editor_screen.dart';
import '../../features/knowledge/knowledge_library_screen.dart';
import '../import/media_import_flow.dart';
import '../import/text_import_screen.dart';
import '../import/voice_import_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  Topic? _topic;
  List<KnowledgeItem> _items = const <KnowledgeItem>[];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final Topic? topic = await services.topics.getById(widget.topicId);
      if (topic == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Chủ đề không tồn tại.';
          _loading = false;
        });
        return;
      }
      final List<KnowledgeItem> items = await services.knowledge.listByTopic(
        widget.topicId,
        query: _query.isEmpty ? null : _query,
      );
      if (!mounted) return;
      setState(() {
        _topic = topic;
        _items = items;
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

  Future<void> _editTopic() async {
    final Topic? topic = _topic;
    if (topic == null || !mounted) return;
    final AppServices services = context.read<AppServices>();
    final TextEditingController name = TextEditingController(text: topic.name);
    final TextEditingController desc = TextEditingController(
      text: topic.description.startsWith('catalog:') ? '' : topic.description,
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sửa chủ đề'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppTextField(controller: name, label: 'Tên chủ đề', required: true),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: desc,
              label: 'Mô tả',
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
        actions: <Widget>[
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.tonal,
            dense: true,
            expanded: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          AppButton(
            label: 'Lưu',
            variant: AppButtonVariant.primary,
            dense: true,
            expanded: false,
            onPressed: () => Navigator.of(context).pop('save'),
          ),
        ],
      ),
    );
    if (result == 'save' && mounted) {
      try {
        await services.topics.update(
          topic.copyWith(name: name.text, description: desc.text),
        );
        if (mounted) await _load();
      } catch (e) {
        if (mounted) showAppSnack(context, message: e.toString(), error: true);
      }
    }
    name.dispose();
    desc.dispose();
  }

  Future<void> _toggleActive() async {
    final Topic? topic = _topic;
    if (topic == null) return;
    final AppServices services = context.read<AppServices>();
    await services.topics.setActive(topic.id, active: !topic.isActive);
    if (mounted) await _load();
  }

  Future<void> _delete() async {
    final Topic? topic = _topic;
    if (topic == null || !mounted) return;
    final bool ok = await showAppConfirmDialog(
      context,
      title: 'Xoá chủ đề?',
      message:
          'Xoá "${topic.name}" sẽ xoá toàn bộ kiến thức và lịch ôn liên quan. Không thể hoàn tác.',
      confirmLabel: 'Xoá',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final AppServices services = context.read<AppServices>();
    await services.topics.delete(topic.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addKnowledge() async {
    final Topic? topic = _topic;
    if (topic == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KnowledgeEditorScreen(topicId: topic.id),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _showImportMenu() async {
    final Topic? topic = _topic;
    if (topic == null || !mounted) return;
    final String? choice = await showAppSheet<String>(
      context: context,
      builder: (BuildContext sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Văn bản'),
              onTap: () => Navigator.of(sheetCtx).pop('text'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ảnh (OCR)'),
              onTap: () => Navigator.of(sheetCtx).pop('image'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF'),
              onTap: () => Navigator.of(sheetCtx).pop('pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none_outlined),
              title: const Text('Giọng nói'),
              onTap: () => Navigator.of(sheetCtx).pop('voice'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'text':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TextImportScreen(topicId: topic.id),
          ),
        );
      case 'image':
        await MediaImportFlow.fromImage(context, topicId: topic.id);
      case 'pdf':
        await MediaImportFlow.fromPdf(context, topicId: topic.id);
      case 'voice':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VoiceImportScreen(topicId: topic.id),
          ),
        );
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_topic?.name ?? 'Chủ đề', overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: 'Kho kiến thức',
            onPressed: _topic == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          KnowledgeLibraryScreen(topicId: _topic!.id),
                    ),
                  ),
            icon: const Icon(Icons.library_books_outlined),
          ),
          IconButton(
            tooltip: 'Sửa',
            onPressed: _editTopic,
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'pause':
                  _toggleActive();
                case 'delete':
                  _delete();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'pause',
                child: Text(
                  _topic?.isActive == true ? 'Tạm ngưng' : 'Kích hoạt',
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Xoá chủ đề'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AppButton.fab(
        label: 'Thêm kiến thức',
        icon: Icons.add_rounded,
        onPressed: _addKnowledge,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading();
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }
    final Topic topic = _topic!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
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
                      Text(
                        topic.icon.isEmpty ? '📗' : topic.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (topic.category.isNotEmpty)
                              Text(
                                topic.category,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if (!topic.isActive)
                        AppIconButton(
                          icon: Icons.pause_circle_rounded,
                          tone: AppIconTone.warning,
                          size: 36,
                          onPressed: _toggleActive,
                          label: 'Tạm ngưng chủ đề',
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppSearchField(
              hint: 'Tìm trong chủ đề...',
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
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${_items.length} kiến thức',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                AppButton(
                  label: 'Nhập',
                  variant: AppButtonVariant.ghost,
                  dense: true,
                  expanded: false,
                  icon: Icons.upload_file_rounded,
                  onPressed: _showImportMenu,
                ),
              ],
            ),
          ),
          _items.isEmpty
              ? SizedBox(
                  width: double.infinity,
                  child: AppEmptyState(
                    title: 'Chưa có kiến thức',
                    message: 'Thêm kiến thức đầu tiên cho chủ đề này.',
                    icon: Icons.lightbulb_outline_rounded,
                    actionLabel: 'Thêm kiến thức',
                    onAction: _addKnowledge,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  itemCount: _items.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final KnowledgeItem item = _items[index];
                    return AppCard(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                KnowledgeDetailScreen(itemId: item.id),
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
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
