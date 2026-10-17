import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/review_scheduler_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/enums.dart';
import '../../data/models/knowledge_item.dart';
import '../../data/models/source.dart';
import '../../data/models/topic.dart';
import '../ai/ai_provider.dart';

/// Nhập từ liên kết web: tải HTML, trích text, tạo nguồn + kiến thức.
class LinkImportScreen extends StatefulWidget {
  const LinkImportScreen({super.key});

  @override
  State<LinkImportScreen> createState() => _LinkImportScreenState();
}

class _LinkImportScreenState extends State<LinkImportScreen> {
  final TextEditingController _url = TextEditingController();
  List<Topic> _topics = const <Topic>[];
  Topic? _topic;
  bool _fetching = false;
  bool _saving = false;
  String? _error;
  String? _extracted;
  String? _lastSourceId;
  List<AiKnowledgeDraft> _drafts = const <AiKnowledgeDraft>[];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    final AppServices services = context.read<AppServices>();
    final List<Topic> topics = await services.topics.list();
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _topic = topics.isNotEmpty ? topics.first : null;
    });
  }

  static final RegExp _titleRe = RegExp(
    r'<title[^>]*>(.*?)</title>',
    caseSensitive: false,
  );
  static final RegExp _scriptRe = RegExp(
    r'<(script|style)[^>]*>.*?</\1>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _tagRe = RegExp(r'<[^>]+>');
  static final RegExp _blockRe = RegExp(r'</(p|div|h[1-6]|li|br)\s*>', caseSensitive: false); // ignore: lines_longer_than_80_chars

  String _htmlToText(String html) {
    String text = html.replaceAll(_scriptRe, ' ');
    text = text.replaceAll(_blockRe, '\n');
    text = text.replaceAll(_tagRe, ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    final StringBuffer buffer = StringBuffer();
    for (final String line in text.split('\n')) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(trimmed);
    }
    return buffer.toString();
  }

  Future<void> _fetch() async {
    final String rawUrl = _url.text.trim();
    Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      showAppSnack(context, message: 'URL không hợp lệ.', error: true);
      return;
    }
    setState(() {
      _fetching = true;
      _error = null;
      _extracted = null;
      _drafts = const <AiKnowledgeDraft>[];
    });
    final AppServices services = context.read<AppServices>();
    try {
      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final String html = utf8.decode(response.bodyBytes);
      final String title =
          _titleRe.firstMatch(html)?.group(1)?.trim() ?? rawUrl;
      final String text = _htmlToText(html);
      if (text.length < 40) {
        throw Exception('Không trích xuất được nội dung đủ ý từ trang này.');
      }
      // Lưu nguồn trước khi tạo kiến thức.
      final Source source = await services.sources.create(
        topicId: _topic?.id,
        type: SourceType.link,
        title: title,
        contentText: text.length > 200000 ? text.substring(0, 200000) : text,
        status: SourceStatus.ready,
        referenceUrl: rawUrl,
      );
      _lastSourceId = source.id;
      if (!mounted) return;
      setState(() {
        _extracted = text.length > 6000 ? text.substring(0, 6000) : text;
      });
      // Tạo nháp kiến thức bằng AI (mock hoặc thật).
      final List<AiKnowledgeDraft> drafts = await services.ai.draftKnowledge(
        sourceText: _extracted!,
        maxItems: 5,
      );
      if (!mounted) return;
      setState(() => _drafts = drafts);
      showAppSnack(
        context,
        message:
            'Đã trích xuất "${title.length > 40 ? '${title.substring(0, 40)}…' : title}" (nguồn đã lưu).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không đọc được liên kết: $e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _saveDrafts() async {
    final Topic? topic = _topic;
    if (topic == null) {
      showAppSnack(context, message: 'Chọn chủ đề đích.', error: true);
      return;
    }
    if (_drafts.isEmpty) return;
    final AppServices services = context.read<AppServices>();
    setState(() => _saving = true);
    int saved = 0;
    try {
      final DateTime now = DateTime.now().toUtc();
      final String? sourceId = _lastSourceId;
      for (final AiKnowledgeDraft draft in _drafts) {
        try {
          final KnowledgeItem item = await services.knowledge.create(
            topicId: topic.id,
            title: draft.title,
            content: draft.content,
            details: draft.details,
            sourceId: sourceId,
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
        message: 'Đã lưu $saved kiến thức (giữ liên kết nguồn).',
        success: true,
      );
      if (saved > 0) AppBootstrap.instance.bumpDataVersion();
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) showAppSnack(context, message: e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập từ liên kết web')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            AppTextField(
              controller: _url,
              label: 'Đường dẫn bài viết',
              hint: 'https://...',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
            ),
            const SizedBox(height: AppSpacing.md),
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
            AppButton(
              label: 'Tải và trích xuất',
              icon: Icons.cloud_download_outlined,
              loading: _fetching,
              onPressed: _fetch,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppErrorState(message: _error, onRetry: _fetch),
            ],
            if (_extracted != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              Text('Nội dung trích xuất', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Text(
                  _extracted!,
                  maxLines: 20,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (_drafts.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              Text('Nháp kiến thức (${_drafts.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._drafts.map(
                (AiKnowledgeDraft d) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(d.title, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(d.content),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Lưu vào chủ đề',
                loading: _saving,
                onPressed: _saveDrafts,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Text(
                'Lưu URL không đồng nghĩa nhập xong: chỉ lưu khi trích '
                'được nội dung. Lỗi mạng hoặc trang không đọc được sẽ báo rõ.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
