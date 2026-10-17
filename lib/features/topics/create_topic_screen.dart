import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/topic.dart';

const List<({String icon, String category})> _iconChoices =
    <({String icon, String category})>[
  (icon: '📱', category: 'Công nghệ'),
  (icon: '🔬', category: 'Khoa học'),
  (icon: '📚', category: 'Lịch sử'),
  (icon: '🇬🇧', category: 'Ngoại ngữ'),
  (icon: '💼', category: 'Kinh doanh'),
  (icon: '❤️', category: 'Sức khỏe'),
  (icon: '🧠', category: 'Tâm lý'),
  (icon: '🌍', category: 'Địa lý'),
  (icon: '🏠', category: 'Đời sống'),
  (icon: '📗', category: ''),
];

class CreateTopicScreen extends StatefulWidget {
  const CreateTopicScreen({super.key});

  @override
  State<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends State<CreateTopicScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String _icon = '📗';
  String _category = '';
  bool _saving = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AppServices services = context.read<AppServices>();
    setState(() {
      _saving = true;
      _nameError = null;
    });
    try {
      final Topic topic = await services.topics.create(
        name: _name.text,
        description: _description.text,
        category: _category.isEmpty
            ? (_iconChoices
                    .firstWhere(
                      (({String icon, String category}) e) =>
                          e.icon == _icon,
                      orElse: () =>
                          (icon: '📗', category: ''),
                    )
                    .category)
            : _category,
        icon: _icon,
      );
      if (!mounted) return;
      showAppSnack(context, message: 'Đã tạo chủ đề', success: true);
      Navigator.of(context).pop(topic);
    } on ValidationException catch (e) {
      setState(() {
        _nameError = e.field == 'name' ? e.message : null;
        _saving = false;
      });
      if (e.field != 'name' && mounted) {
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
      appBar: AppBar(title: const Text('Tạo chủ đề mới')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            AppTextField(
              controller: _name,
              label: 'Tên chủ đề',
              required: true,
              hint: 'VD: Kỹ thuật iPhone',
              errorText: _nameError,
              maxLength: 120,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _description,
              label: 'Mô tả (tuỳ chọn)',
              hint: 'Mô tả ngắn về chủ đề',
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chọn biểu tượng & danh mục',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _iconChoices.map((({String icon, String category}) e) {
                final bool selected = _icon == e.icon;
                return ChoiceChip(
                  label: Text(e.icon, style: const TextStyle(fontSize: 20)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _icon = e.icon;
                      _category = e.category;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Tạo chủ đề',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
