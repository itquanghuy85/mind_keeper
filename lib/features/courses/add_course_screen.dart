import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../ai/ai_provider.dart';
import '../discover/domain_catalog.dart';
import '../../data/models/course.dart';

/// Cấu hình + đề cương của một chủ đề trong luồng thêm khóa học.
class _Draft {
  _Draft(this.topic);

  final String topic;
  CourseLevel level = CourseLevel.basic;
  int count = 10;
  List<String>? outline;
  String? error;
  bool loading = false;
}

/// Thêm khóa học: 1) chọn chủ đề  2) cấp độ + số mẩu  3) xem/chỉnh đề cương.
class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  static const List<int> _countPresets = <int>[5, 10, 20, 30];

  int _step = 0;
  bool _starting = false;
  final TextEditingController _topicController = TextEditingController();
  final List<_Draft> _drafts = <_Draft>[];
  final Map<String, TextEditingController> _addControllers =
      <String, TextEditingController>{};

  late final List<String> _suggestions = <String>[
    for (final LearningDomain d in LearningDomains.all)
      ...d.sampleTopics.take(2),
  ];

  @override
  void dispose() {
    _topicController.dispose();
    for (final TextEditingController c in _addControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _has(String topic) => _drafts.any(
    (_Draft d) => d.topic.toLowerCase() == topic.trim().toLowerCase(),
  );

  void _addTopic(String raw) {
    final String topic = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (topic.isEmpty || _has(topic)) return;
    setState(() {
      _drafts.add(_Draft(topic));
      _topicController.clear();
    });
  }

  void _toggleSuggestion(String topic) {
    if (_has(topic)) {
      setState(() {
        _drafts.removeWhere(
          (_Draft d) => d.topic.toLowerCase() == topic.toLowerCase(),
        );
      });
    } else {
      _addTopic(topic);
    }
  }

  Future<void> _loadOutline(_Draft draft) async {
    final AppServices services = context.read<AppServices>();
    setState(() {
      draft.loading = true;
      draft.error = null;
    });
    try {
      final List<String> titles = await services.courseService.draftOutline(
        topicName: draft.topic,
        level: draft.level,
        count: draft.count,
      );
      if (!mounted) return;
      setState(() {
        draft.outline = titles;
        draft.loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        draft.error = e is AiConfigurationException ? e.userMessage : '$e';
        draft.loading = false;
      });
    }
  }

  Future<void> _goToOutline() async {
    setState(() => _step = 2);
    for (final _Draft d in _drafts) {
      if (d.outline == null && !d.loading) {
        unawaited(_loadOutline(d));
      }
    }
  }

  bool get _canStart =>
      !_starting &&
      _drafts.isNotEmpty &&
      _drafts.every(
        (_Draft d) => d.outline != null && d.outline!.isNotEmpty,
      );

  Future<void> _start() async {
    final AppServices services = context.read<AppServices>();
    final NavigatorState nav = Navigator.of(context);
    setState(() => _starting = true);
    try {
      for (final _Draft d in _drafts) {
        await services.courseService.startCourse(
          topicName: d.topic,
          level: d.level,
          titles: d.outline!,
        );
      }
      AppBootstrap.instance.bumpDataVersion();
      // Sinh mẩu đầu tiên + lên lịch thông báo ở nền (không chặn UI).
      unawaited(
        services.courseService.sync().then((_) {
          AppBootstrap.instance.bumpDataVersion();
        }),
      );
      if (!mounted) return;
      nav.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tạo được khóa học: $e')));
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = <String>[
      'Chọn chủ đề',
      'Cấp độ và số mẩu',
      'Đề cương',
    ];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text('Thêm khóa học · ${_step + 1}/3'),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  titles[_step],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: switch (_step) {
                0 => _stepTopics(context),
                1 => _stepConfig(context),
                _ => _stepOutline(context),
              },
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final String label;
    final VoidCallback? onPressed;
    switch (_step) {
      case 0:
        label = _drafts.isEmpty
            ? 'Chọn ít nhất 1 chủ đề'
            : 'Tiếp tục (${_drafts.length} chủ đề)';
        onPressed = _drafts.isEmpty
            ? null
            : () => setState(() => _step = 1);
      case 1:
        label = 'Soạn đề cương';
        onPressed = _goToOutline;
      default:
        label = 'Bắt đầu học';
        onPressed = _canStart ? _start : null;
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppButton(
          label: label,
          loading: _starting,
          onPressed: onPressed,
        ),
      ),
    );
  }

  // ---------------- Bước 1: chọn chủ đề ----------------
  Widget _stepTopics(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: <Widget>[
        Text(
          'Gõ chủ đề bạn muốn tìm hiểu, hoặc chọn gợi ý bên dưới. '
          'Có thể chọn nhiều chủ đề.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _topicController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Chủ đề',
                  hintText: 'Ví dụ: Bếp từ và lò vi sóng',
                ),
                onSubmitted: _addTopic,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: 'Thêm chủ đề',
              onPressed: () => _addTopic(_topicController.text),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        if (_drafts.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text('Đã chọn', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final _Draft d in _drafts)
                InputChip(
                  label: Text(d.topic),
                  onDeleted: () => setState(() => _drafts.remove(d)),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Gợi ý', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final String s in _suggestions)
              AppChip(
                label: s,
                selected: _has(s),
                onTap: () => _toggleSuggestion(s),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ---------------- Bước 2: cấp độ + số mẩu ----------------
  Widget _stepConfig(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: <Widget>[
        for (final _Draft d in _drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(d.topic, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Text('Cấp độ', style: text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final CourseLevel l in CourseLevel.values)
                        AppChip(
                          label: l.label,
                          selected: d.level == l,
                          onTap: () => setState(() {
                            d.level = l;
                            d.outline = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(d.level.hint, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  Text('Số mẩu kiến thức', style: text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final int n in _countPresets)
                        AppChip(
                          label: '$n',
                          selected: d.count == n,
                          onTap: () => setState(() {
                            d.count = n;
                            d.outline = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      key: ValueKey<String>('count-${d.topic}-${d.count}'),
                      initialValue: '${d.count}',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tự nhập (3–60)',
                        isDense: true,
                      ),
                      onChanged: (String v) {
                        final int? n = int.tryParse(v);
                        if (n == null) return;
                        d.count = n.clamp(3, 60);
                        d.outline = null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ---------------- Bước 3: đề cương ----------------
  Widget _stepOutline(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: <Widget>[
        Text(
          'AI đã soạn đề cương. Bạn có thể bỏ mục không cần hoặc thêm mục '
          'của riêng mình trước khi bắt đầu.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final _Draft d in _drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(child: _outlineCard(context, d)),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _outlineCard(BuildContext context, _Draft d) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<Widget> children = <Widget>[
      Text('${d.topic} · ${d.level.label}', style: text.titleMedium),
      const SizedBox(height: AppSpacing.sm),
    ];
    if (d.loading) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppSpacing.md),
              Text('AI đang soạn đề cương...'),
            ],
          ),
        ),
      );
    } else if (d.error != null) {
      children
        ..add(
          Text(
            d.error!,
            style: text.bodyMedium?.copyWith(color: AppColors.danger),
          ),
        )
        ..add(const SizedBox(height: AppSpacing.sm))
        ..add(
          AppButton(
            label: 'Thử lại',
            variant: AppButtonVariant.tonal,
            expanded: false,
            dense: true,
            onPressed: () => _loadOutline(d),
          ),
        );
    } else if (d.outline != null) {
      final TextEditingController add = _addControllers.putIfAbsent(
        d.topic,
        TextEditingController.new,
      );
      for (int i = 0; i < d.outline!.length; i++) {
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 28,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('${i + 1}.', style: text.bodySmall),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(d.outline![i], style: text.bodyMedium),
                ),
              ),
              IconButton(
                tooltip: 'Bỏ mục ${i + 1}',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => d.outline!.removeAt(i)),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
        );
      }
      children
        ..add(const SizedBox(height: AppSpacing.sm))
        ..add(
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: add,
                  decoration: const InputDecoration(
                    labelText: 'Thêm mục',
                    isDense: true,
                  ),
                  onSubmitted: (String v) => _appendOutline(d, add),
                ),
              ),
              IconButton(
                tooltip: 'Thêm mục vào đề cương',
                onPressed: () => _appendOutline(d, add),
                icon: const Icon(Icons.add_circle_rounded),
              ),
            ],
          ),
        );
      if (d.outline!.isEmpty) {
        children.add(
          Text(
            'Đề cương đang trống — hãy thêm ít nhất một mục.',
            style: text.bodySmall?.copyWith(color: AppColors.danger),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  void _appendOutline(_Draft d, TextEditingController controller) {
    final String t = controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      d.outline!.add(t);
      controller.clear();
    });
  }
}
