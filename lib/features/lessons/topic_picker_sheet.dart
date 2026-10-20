import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/lesson.dart';
import '../ai/ai_provider.dart';
import '../discover/domain_catalog.dart';

/// Kết quả chọn nhiều chủ đề từ bottom sheet.
class TopicPickerResult {
  const TopicPickerResult({required this.topics, required this.mode});

  /// Danh sách chủ đề đã chọn (không rỗng, không trùng).
  final List<String> topics;

  /// Chế độ bài học áp dụng cho các bài sẽ tạo.
  final LessonMode mode;
}

/// Bottom sheet chọn nhiều chủ đề cho một lĩnh vực.
///
/// - Gợi ý danh sách chủ đề từ AI (có fallback offline tiếng Việt hợp lệ).
/// - Chọn/bỏ chọn nhiều mục, thêm chủ đề tùy chỉnh, tạo lại danh sách.
/// - Mọi thẻ chủ đề có semantics label rõ ràng (tên + mô tả + trạng thái chọn).
Future<TopicPickerResult?> showTopicPickerSheet({
  required BuildContext context,
  required LearningDomain domain,
  required LessonMode initialMode,
  int suggestionCount = 20,
}) {
  return showAppSheet<TopicPickerResult>(
    context: context,
    builder: (BuildContext sheetCtx) => _TopicPickerSheet(
      domain: domain,
      initialMode: initialMode,
      suggestionCount: suggestionCount,
    ),
  );
}

class _TopicPickerSheet extends StatefulWidget {
  const _TopicPickerSheet({
    required this.domain,
    required this.initialMode,
    required this.suggestionCount,
  });

  final LearningDomain domain;
  final LessonMode initialMode;
  final int suggestionCount;

  @override
  State<_TopicPickerSheet> createState() => _TopicPickerSheetState();
}

class _TopicPickerSheetState extends State<_TopicPickerSheet> {
  final TextEditingController _customCtrl = TextEditingController();

  List<AiTopicSuggestion> _suggestions = const <AiTopicSuggestion>[];
  final Set<String> _selected = <String>{};
  bool _loading = true;
  String? _error;
  LessonMode _mode = LessonMode.overview;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _loadSuggestions();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AppServices services = context.read<AppServices>();
      final List<AiTopicSuggestion> list = await services.lessonService
          .suggestTopics(domain: widget.domain, count: widget.suggestionCount);
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

  void _toggle(String title) {
    setState(() {
      if (!_selected.remove(title)) _selected.add(title);
    });
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_suggestions.map((AiTopicSuggestion s) => s.title));
    });
  }

  void _clearAll() {
    setState(() => _selected.clear());
  }

  void _addCustom() {
    final String value = _customCtrl.text.trim();
    if (value.isEmpty) {
      showAppSnack(context, message: 'Chủ đề không được để trống.', error: true);
      return;
    }
    setState(() {
      _selected.add(value);
      _customCtrl.clear();
    });
  }

  /// Thêm một chủ đề mẫu ngẫu nhiên của lĩnh vực vào danh sách chọn.
  void _addRandomTopic() {
    setState(() => _selected.add(widget.domain.randomTopic()));
  }

  void _submit() {
    final List<String> topics = <String>[
      for (final String t in _selected)
        if (t.trim().isNotEmpty) t.trim(),
    ];
    if (topics.isEmpty) {
      showAppSnack(
        context,
        message: 'Hãy chọn ít nhất một chủ đề.',
        error: true,
      );
      return;
    }
    Navigator.of(context).pop(TopicPickerResult(topics: topics, mode: _mode));
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Chủ đề trong ${widget.domain.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chọn nhiều chủ đề để tạo nhiều bài học cùng lúc.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Chủ đề ngẫu nhiên',
                  variant: AppButtonVariant.ghost,
                  dense: true,
                  expanded: false,
                  icon: Icons.shuffle_rounded,
                  onPressed: _addRandomTopic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Wrap: nút "Tất cả" / "Bỏ chọn tất cả" / "Đã chọn N" có độ dài
              // khác nhau theo ngôn ngữ và cỡ chữ — không xếp cứng trong Row
              // để tránh tràn ngang trên màn hình hẹp.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  AppButton(
                    label: 'Tất cả',
                    variant: AppButtonVariant.tonal,
                    dense: true,
                    expanded: false,
                    onPressed: _loading ? null : _selectAll,
                  ),
                  AppButton(
                    label: 'Bỏ chọn tất cả',
                    variant: AppButtonVariant.tonal,
                    dense: true,
                    expanded: false,
                    onPressed: _loading ? null : _clearAll,
                  ),
                  Text(
                    'Đã chọn ${_selected.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_loading)
                const AppLoading(label: 'Đang tải gợi ý chủ đề...')
              else if (_error != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Không tải được gợi ý chủ đề.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Tạo lại danh sách',
                        variant: AppButtonVariant.secondary,
                        dense: true,
                        expanded: false,
                        onPressed: _loadSuggestions,
                      ),
                    ],
                  ),
                )
              else
                ..._suggestions.map(
                  (AiTopicSuggestion s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TopicSuggestionTile(
                      suggestion: s,
                      selected: _selected.contains(s.title),
                      onToggle: () => _toggle(s.title),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Thêm chủ đề riêng',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _customCtrl,
                      label: 'Chủ đề tùy chỉnh',
                      hint: 'Nhập chủ đề riêng của bạn',
                      onSubmitted: (_) => _addCustom(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: AppButton(
                      label: 'Thêm',
                      dense: true,
                      expanded: false,
                      icon: Icons.add_rounded,
                      onPressed: _addCustom,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Chế độ bài học',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...LessonMode.values.map(
                (LessonMode m) => _ModeOption(
                  mode: m,
                  selected: _mode == m,
                  onTap: () => setState(() => _mode = m),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton(
                      label: 'Hủy',
                      variant: AppButtonVariant.tonal,
                      dense: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Tạo bài học',
                      icon: Icons.auto_awesome_rounded,
                      dense: true,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ một chủ đề gợi ý — có semantics đầy đủ cho trình đọc màn hình.
class _TopicSuggestionTile extends StatelessWidget {
  const _TopicSuggestionTile({
    required this.suggestion,
    required this.selected,
    required this.onToggle,
  });

  final AiTopicSuggestion suggestion;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final String state = selected ? 'đã chọn' : 'chưa chọn';
    final String action = selected ? 'Bỏ chọn' : 'Chọn';
    return Semantics(
      container: true,
      label: '${suggestion.title}. ${suggestion.description}. $state.',
      hint: '$action chủ đề ${suggestion.title}',
      toggled: selected,
      button: true,
      child: AppCard(
        color: selected ? context.appColors.primarySoft : null,
        border: selected ? context.appColors.primary : null,
        onTap: onToggle,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: selected
                  ? context.appColors.primary
                  : context.appColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    suggestion.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    suggestion.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final LessonMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: 'Chế độ bài học ${mode.label}. ${mode.description}.',
        selected: selected,
        button: true,
        child: AppCard(
          color: selected ? context.appColors.primarySoft : null,
          border: selected ? context.appColors.primary : null,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected
                      ? context.appColors.primary
                      : context.appColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        mode.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        mode.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
