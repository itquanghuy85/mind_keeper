import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/review_scheduler_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/topic.dart';
import '../ai/ai_provider.dart';
import '../knowledge/knowledge_editor_screen.dart';

/// Nhập văn bản → xem trước → tạo kiến thức + câu hỏi (thủ công hoặc AI).
class TextImportScreen extends StatefulWidget {
  const TextImportScreen({super.key, this.topicId, this.initialText});

  final String? topicId;

  /// Nội dung có sẵn (từ OCR/PDF/giọng nói) điền sẵn vào ô văn bản.
  final String? initialText;

  @override
  State<TextImportScreen> createState() => _TextImportScreenState();
}

class _TextImportScreenState extends State<TextImportScreen> {
  final TextEditingController _text = TextEditingController();
  Topic? _topic;
  List<Topic> _topics = const <Topic>[];
  bool _busy = false;
  List<AiKnowledgeDraft> _drafts = const <AiKnowledgeDraft>[];
  bool _draftLoaded = false;

  @override
  void initState() {
    super.initState();
    final String initial = widget.initialText?.trim() ?? '';
    if (initial.isNotEmpty) _text.text = initial;
    _loadTopics();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    final AppServices services = context.read<AppServices>();
    final List<Topic> topics = await services.topics.list();
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _topic = widget.topicId == null
          ? (topics.isNotEmpty ? topics.first : null)
          : topics.where((Topic t) => t.id == widget.topicId).firstOrNull;
    });
  }

  Future<void> _previewAi() async {
    final AppServices services = context.read<AppServices>();
    final String source = _text.text.trim();
    if (source.isEmpty) {
      showAppSnack(context, message: 'Dán nội dung trước.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final List<AiKnowledgeDraft> drafts =
          await services.ai.draftKnowledge(sourceText: source, maxItems: 5);
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _draftLoaded = true;
      });
      if (drafts.isEmpty) {
        showAppSnack(context, message: 'Không tóm tắt được nội dung.');
      } else {
        showAppSnack(
          context,
          message: services.ai.isRealProvider
              ? 'Đã tạo ${drafts.length} nháp — kiểm tra rồi lưu.'
              : '${drafts.length} nháp từ mock AI — kiểm tra rồi lưu.',
        );
      }
    } catch (e) {
      if (mounted) showAppSnack(context, message: e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDrafts() async {
    final AppServices services = context.read<AppServices>();
    final Topic? topic = _topic;
    if (topic == null) {
      showAppSnack(context, message: 'Chọn chủ đề đích.', error: true);
      return;
    }
    if (_drafts.isEmpty) {
      showAppSnack(context, message: 'Chưa có nháp để lưu.', error: true);
      return;
    }
    setState(() => _busy = true);
    int saved = 0;
    try {
      final DateTime now = DateTime.now().toUtc();
      for (final AiKnowledgeDraft draft in _drafts) {
        try {
          final KnowledgeItem item = await services.knowledge.create(
            topicId: topic.id,
            title: draft.title,
            content: draft.content,
            details: draft.details,
            origin: KnowledgeOrigin.aiSuggested,
            skipDuplicateCheck: true,
          );
          await services.cards.create(
            knowledgeItemId: item.id,
            question: '${draft.title} — nhớ được điều gì?',
            answer: draft.content,
            dueAt: ReviewSchedulerService.initialDue(DateTime.now()),
            now: now,
          );
          saved++;
        } on ValidationException {
          continue;
        }
      }
      if (!mounted) return;
      showAppSnack(
        context,
        message: 'Đã lưu $saved kiến thức vào "${topic.name}".',
        success: true,
      );
      if (saved > 0) AppBootstrap.instance.bumpDataVersion();
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) showAppSnack(context, message: e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createFromText() async {
    final Topic? topic = _topic;
    if (topic == null || !mounted) return;
    final String text = _text.text.trim();
    final KnowledgeItem? saved =
        await Navigator.of(context).push<KnowledgeItem>(
      MaterialPageRoute<KnowledgeItem>(
        builder: (_) => KnowledgeEditorScreen(
          topicId: topic.id,
          initialContent: text.isEmpty ? null : text,
        ),
      ),
    );
    if (saved != null && mounted) Navigator.of(context).pop(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập từ văn bản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            if (_topics.isNotEmpty) ...<Widget>[
              DropdownButtonFormField<Topic>(
                initialValue: _topic,
                decoration: const InputDecoration(labelText: 'Chủ đề đích'),
                items: _topics
                    .map(
                      (Topic t) => DropdownMenuItem<Topic>(
                        value: t,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (Topic? value) => setState(() => _topic = value),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              controller: _text,
              label: 'Nội dung dán vào',
              hint: 'Dán đoạn văn, ghi chú hoặc trích đoạn sách...',
              maxLines: 10,
              minLines: 5,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Xem trước với AI',
              variant: AppButtonVariant.secondary,
              icon: Icons.auto_awesome_rounded,
              loading: _busy,
              onPressed: _previewAi,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Tạo kiến thức thủ công',
              variant: AppButtonVariant.tonal,
              icon: Icons.edit_rounded,
              onPressed: _createFromText,
            ),
            if (_draftLoaded) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Nháp (${_drafts.length}) — duyệt trước khi lưu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._drafts.map(
                (AiKnowledgeDraft d) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          d.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(d.content),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Lưu ${_drafts.length} kiến thức đã duyệt',
                loading: _busy,
                onPressed: _saveDrafts,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Text(
                'Nguồn văn bản được lưu trong metadata kiến thức. '
                'Nội dung AI (nếu có) được đánh dấu origin = ai_suggested.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
