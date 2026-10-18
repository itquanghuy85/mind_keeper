import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/review_scheduler_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/review_card.dart';
import '../ai/ai_provider.dart';

/// Tạo/sửa kiến thức + câu hỏi/đáp án (thủ công hoặc nháp AI).
class KnowledgeEditorScreen extends StatefulWidget {
  const KnowledgeEditorScreen({
    super.key,
    this.topicId,
    this.itemId,
    this.initialContent,
    this.sourceId,
  });

  final String? topicId;
  final String? itemId;
  final String? initialContent;
  final String? sourceId;

  @override
  State<KnowledgeEditorScreen> createState() => _KnowledgeEditorScreenState();
}

class _KnowledgeEditorScreenState extends State<KnowledgeEditorScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();
  final TextEditingController _details = TextEditingController();
  final TextEditingController _question = TextEditingController();
  final TextEditingController _answer = TextEditingController();

  KnowledgeItem? _existing;
  bool _loading = true;
  bool _saving = false;
  bool _aiLoading = false;
  String? _error;
  String? _titleError;
  String? _contentError;
  List<ReviewCard> _existingCards = const <ReviewCard>[];

  bool get isEdit => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _content.text = widget.initialContent!;
    }
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _details.dispose();
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AppServices services = context.read<AppServices>();
    if (!isEdit) {
      setState(() => _loading = false);
      return;
    }
    try {
      final KnowledgeItem? item = await services.knowledge.getById(
        widget.itemId!,
      );
      if (item == null) {
        setState(() {
          _error = 'Kiến thức không tồn tại.';
          _loading = false;
        });
        return;
      }
      final List<ReviewCard> cards = await services.cards.listByKnowledgeItem(
        item.id,
      );
      _title.text = item.title;
      _content.text = item.content;
      _details.text = item.details;
      if (cards.isNotEmpty) {
        _question.text = cards.first.question;
        _answer.text = cards.first.answer;
      }
      if (!mounted) return;
      setState(() {
        _existing = item;
        _existingCards = cards;
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

  Future<void> _aiDraftQuestion() async {
    final AppServices services = context.read<AppServices>();
    if (_content.text.trim().isEmpty) {
      showAppSnack(
        context,
        message: 'Nhập nội dung kiến thức trước khi dùng AI.',
        error: true,
      );
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final List<AiQuestionDraft> drafts = await services.ai.draftQuestions(
        knowledgeContent: _content.text.trim(),
        count: 1,
      );
      if (drafts.isNotEmpty) {
        setState(() {
          _question.text = drafts.first.question;
          _answer.text = drafts.first.answer;
        });
        if (mounted) {
          showAppSnack(
            context,
            message: services.ai.isRealProvider
                ? 'Đã tạo nháp câu hỏi bằng AI — kiểm tra rồi lưu.'
                : 'Nháp từ mock AI (chưa phải dịch vụ thật) — kiểm tra rồi lưu.',
          );
        }
      }
    } catch (e) {
      if (mounted) showAppSnack(context, message: e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save() async {
    final AppServices services = context.read<AppServices>();
    setState(() {
      _saving = true;
      _titleError = null;
      _contentError = null;
    });
    try {
      KnowledgeItem item;
      if (isEdit) {
        item = await services.knowledge.update(
          _existing!.copyWith(
            title: _title.text,
            content: _content.text,
            details: _details.text,
          ),
        );
      } else {
        final String? topicId = widget.topicId;
        if (topicId == null) {
          throw const ValidationException('Thiếu chủ đề.');
        }
        item = await services.knowledge.create(
          topicId: topicId,
          title: _title.text,
          content: _content.text,
          details: _details.text,
          sourceId: widget.sourceId,
          skipDuplicateCheck: false,
        );
      }

      final String question = _question.text.trim();
      final String answer = _answer.text.trim();
      if (question.isNotEmpty && answer.isNotEmpty) {
        if (_existingCards.isNotEmpty) {
          final ReviewCard first = _existingCards.first;
          await services.cards.updateSchedule(
            first.copyWith(question: question, answer: answer),
          );
        } else {
          await services.cards.create(
            knowledgeItemId: item.id,
            question: question,
            answer: answer,
            dueAt: ReviewSchedulerService.initialDue(DateTime.now()),
          );
        }
      }
      if (!mounted) return;
      showAppSnack(context, message: 'Đã lưu kiến thức', success: true);
      AppBootstrap.instance.bumpDataVersion();
      Navigator.of(context).pop(item);
    } on ValidationException catch (e) {
      setState(() => _saving = false);
      if (e.field == 'title') {
        setState(() => _titleError = e.message);
      } else if (e.field == 'content') {
        setState(() => _contentError = e.message);
      } else if (mounted) {
        showAppSnack(context, message: e.message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, message: e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa kiến thức' : 'Thêm kiến thức')),
      body: SafeArea(
        child: _loading
            ? const AppLoading()
            : _error != null
            ? AppErrorState(message: _error, onRetry: _load)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  AppTextField(
                    controller: _title,
                    label: 'Tiêu đề',
                    required: true,
                    errorText: _titleError,
                    hint: 'Một ý chính, ngắn gọn',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _content,
                    label: 'Nội dung cốt lõi',
                    required: true,
                    errorText: _contentError,
                    hint: '1–3 câu, đi thẳng vào trọng tâm',
                    maxLines: 4,
                    minLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _details,
                    label: 'Chi tiết mở rộng (tuỳ chọn)',
                    maxLines: 5,
                    minLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Câu hỏi tự kiểm tra',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      AppButton(
                        label: _aiLoading ? 'Đang tạo...' : 'AI gợi ý',
                        variant: AppButtonVariant.ghost,
                        dense: true,
                        expanded: false,
                        icon: Icons.auto_awesome_rounded,
                        loading: _aiLoading,
                        onPressed: _aiDraftQuestion,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _question,
                    label: 'Câu hỏi',
                    hint: 'VD: Đường cong lãng mô tả điều gì?',
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _answer,
                    label: 'Đáp án',
                    hint: 'Câu trả lời tham chiếu',
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: isEdit ? 'Lưu thay đổi' : 'Lưu kiến thức',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
      ),
    );
  }
}
