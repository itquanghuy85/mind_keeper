import 'package:flutter/material.dart';

import '../../core/services/voice_transcription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import 'text_import_screen.dart';

/// Ghi âm giọng nói → văn bản → chuyển sang màn nhập văn bản.
class VoiceImportScreen extends StatefulWidget {
  const VoiceImportScreen({super.key, this.topicId});

  final String? topicId;

  @override
  State<VoiceImportScreen> createState() => _VoiceImportScreenState();
}

class _VoiceImportScreenState extends State<VoiceImportScreen> {
  final VoiceTranscriptionService _voice = VoiceTranscriptionService();
  final TextEditingController _text = TextEditingController();
  bool _listening = false;
  bool _busy = false;
  String? _hint;

  @override
  void dispose() {
    if (_listening) _voice.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _voice.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() {
      _busy = true;
      _hint = null;
    });
    final bool started = await _voice.start(
      onResult: (String text, bool isFinal) {
        if (!mounted) return;
        setState(() {
          _text.text = text;
          if (isFinal) _listening = false;
        });
      },
      onError: (String message) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _hint = message;
        });
        showAppSnack(context, message: message, error: true);
      },
      onStatus: (String status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
    );
    if (!mounted) return;
    setState(() {
      _listening = started;
      _busy = false;
      if (!started && _hint == null) {
        _hint = 'Không khởi tạo được nhận dạng giọng nói.';
      }
    });
  }

  void _useText() {
    final String value = _text.text.trim();
    if (value.isEmpty) {
      showAppSnack(context, message: 'Chưa có nội dung — hãy ghi âm trước.', error: true);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TextImportScreen(
          topicId: widget.topicId,
          initialText: value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập bằng giọng nói')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            AppCard(
              child: Column(
                children: <Widget>[
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _listening
                          ? AppColors.dangerSoft
                          : AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 44,
                      color: _listening ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _listening
                        ? 'Đang nghe — nói tự nhiên, ngưng nói để dừng.'
                        : (_hint ?? 'Nhấn Bắt đầu để nói. Có thể ghi nhiều lần, văn bản cộng dồn.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: _listening ? 'Dừng ghi âm' : 'Bắt đầu ghi âm',
                    variant: _listening ? AppButtonVariant.danger : AppButtonVariant.primary,
                    icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    loading: _busy,
                    onPressed: _toggle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _text,
              label: 'Văn bản nhận được',
              hint: 'Nói để điền vào đây...',
              maxLines: 10,
              minLines: 5,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Dùng văn bản này',
              variant: AppButtonVariant.secondary,
              icon: Icons.arrow_forward_rounded,
              onPressed: _useText,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Text(
                'Nhận dạng chạy qua dịch vụ của hệ thống — kết quả tùy thiết bị. '
                'Kiểm tra lại văn bản trước khi tạo kiến thức.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
