import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/share_intake.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/topic.dart';
import '../ai/ai_provider.dart';
import '../import/link_import_screen.dart';
import '../import/text_import_screen.dart';
import 'quick_capture_service.dart';

/// Quick capture: nhận văn bản/liên kết từ share sheet, lưu nhanh vào chủ đề
/// (mặc định "Hộp thư đến") hoặc chuyển sang màn nhập đầy đủ.
class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key, required this.payload});

  final SharedPayload payload;

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  List<Topic> _topics = const <Topic>[];

  /// null = "Hộp thư đến" (tự tạo khi lưu nếu chưa có).
  String? _topicId;
  bool _saving = false;
  bool _summarizing = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(
      text: QuickCaptureService.suggestTitle(widget.payload),
    );
    _content = TextEditingController(text: widget.payload.text);
    _loadTopics();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  QuickCaptureService _service(AppServices s) => QuickCaptureService(
    topics: s.topics,
    knowledge: s.knowledge,
    cards: s.cards,
    sources: s.sources,
  );

  Future<void> _loadTopics() async {
    final AppServices services = context.read<AppServices>();
    final List<Topic> all = await services.topics.list(limit: 200);
    if (!mounted) return;
    // "Hộp thư đến" luôn là mục ảo đầu tiên (_topicId == null) dù đã tồn tại hay
    // chưa — không đưa id của nó vào danh sách để Dropdown không bị trùng giá trị.
    setState(() {
      _topics = all
          .where((Topic t) => t.name != QuickCaptureService.inboxName)
          .toList(growable: false);
    });
  }

  SharedPayload get _edited => SharedPayload(
    text: _content.text.trim(),
    subject: widget.payload.subject,
  );

  Future<void> _save() async {
    if (_saving) return;
    final String body = _content.text.trim();
    if (body.isEmpty || _title.text.trim().isEmpty) {
      showAppSnack(context, message: 'Nhập tiêu đề và nội dung.', error: true);
      return;
    }
    final AppServices services = context.read<AppServices>();
    setState(() => _saving = true);
    try {
      final QuickCaptureResult result = await _service(services).save(
        payload: _edited,
        topicId: _topicId,
        title: _title.text,
        content: body,
      );
      if (!mounted) return;
      if (result.duplicate) {
        showAppSnack(
          context,
          message:
              'Nội dung này đã có trong "${result.topic.name}" — không lưu trùng.',
        );
      } else {
        AppBootstrap.instance.bumpDataVersion();
        showAppSnack(
          context,
          message: 'Đã lưu vào "${result.topic.name}" — thẻ ôn đến hạn ngay.',
          success: true,
          duration: const Duration(seconds: 6),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showAppSnack(context, message: 'Không lưu được: $e', error: true);
        setState(() => _saving = false);
      }
    }
  }

  void _openFull() {
    final SharedPayload payload = _edited;
    final String? url = payload.url;
    final Widget screen = payload.isLink && url != null
        ? LinkImportScreen(initialUrl: url)
        : TextImportScreen(topicId: _topicId, initialText: payload.text);
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _summarizeWithAi() async {
    if (_summarizing) return;
    final AppServices services = context.read<AppServices>();
    setState(() => _summarizing = true);
    try {
      final List<AiKnowledgeDraft> drafts = await services.ai.draftKnowledge(
        sourceText: _content.text.trim(),
        maxItems: 1,
      );
      if (!mounted) return;
      if (drafts.isEmpty) {
        showAppSnack(context, message: 'AI chưa tóm tắt được nội dung này.');
      } else {
        setState(() {
          _title.text = drafts.first.title;
          _content.text = drafts.first.content;
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, message: 'Tóm tắt thất bại: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _summarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool aiReady = context.read<AppServices>().ai.isRealProvider;
    final String? url = widget.payload.url;
    return Scaffold(
      appBar: AppBar(title: const Text('Lưu nhanh')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text('Nội dung vừa chia sẻ', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppTextField(controller: _title, label: 'Tiêu đề'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _content,
                  label: 'Nội dung',
                  maxLines: 8,
                  minLines: 3,
                ),
                if (url != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.link_rounded, size: AppSizes.iconSm),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Liên kết sẽ được lưu làm nguồn tham khảo',
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Lưu vào chủ đề', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            initialValue: _topicId,
            isExpanded: true,
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(QuickCaptureService.inboxName),
              ),
              for (final Topic t in _topics)
                DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
            ],
            onChanged: (String? v) => setState(() => _topicId = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Lưu nhanh',
            icon: Icons.bolt_rounded,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Mở đầy đủ',
            icon: Icons.open_in_new_rounded,
            variant: AppButtonVariant.tonal,
            onPressed: _saving ? null : _openFull,
          ),
          if (aiReady) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Tóm tắt bằng AI',
              icon: Icons.auto_awesome_rounded,
              variant: AppButtonVariant.ghost,
              loading: _summarizing,
              onPressed: _summarizing ? null : _summarizeWithAi,
            ),
          ],
        ],
      ),
    );
  }
}
