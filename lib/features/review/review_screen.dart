import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/enums.dart';
import 'review_controller.dart';

/// Màn hình ôn tập: một câu hỏi mỗi lần, tự nhớ trước khi xem đáp án.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, this.targetCardId});

  /// Khi có từ thông báo: mở đúng thẻ này.
  final String? targetCardId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController _controller;
  final TextEditingController _answerInput = TextEditingController();
  bool _initStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = ReviewController(services: context.read<AppServices>())
      ..addListener(_onChanged);
    _start();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    if (_initStarted) return;
    _initStarted = true;
    if (widget.targetCardId != null) {
      await _controller.loadSingleCard(widget.targetCardId!);
    } else {
      await _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _answerInput.dispose();
    super.dispose();
  }

  Future<void> _exit() async {
    await _controller.exit();
    if (mounted) Navigator.of(context).pop(_controller.reviewedCount);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _exit,
          ),
          title: widget.targetCardId != null
              ? const Text('Ôn thẻ được nhắc')
              : Text('Ôn tập ${_controller.progress >= 1 ? '' : ''}'),
          bottom: _controller.loading || _controller.total == 0
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.pillAll,
                      child: LinearProgressIndicator(
                        value: _controller.progress,
                        minHeight: 6,
                      ),
                    ),
                  ),
                ),
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final ReviewController c = _controller;
    if (c.loading) return const AppLoading(label: 'Đang tải thẻ ôn tập...');
    if (c.error != null && c.current == null) {
      return AppErrorState(message: c.error, onRetry: () => c.load());
    }
    if (c.phase == ReviewPhase.finished || c.current == null) {
      return _FinishedView(
        reviewed: c.reviewedCount,
        again: c.againCount,
        onDone: () async {
          await c.finishAndClear();
          if (mounted) Navigator.of(context).pop(c.reviewedCount);
        },
      );
    }

    final item = c.current!;
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: Text(
                        item.shortLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${c.index + 1}/${c.total}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  item.card.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (c.phase == ReviewPhase.question) ...<Widget>[
                  Text(
                    'Hãy thử trả lời trước:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _answerInput,
                    hint: 'Viết câu trả lời của bạn...',
                    maxLines: 4,
                    minLines: 3,
                    onChanged: c.onAnswerChanged,
                  ),
                ] else ...<Widget>[
                  if (c.userAnswer.trim().isNotEmpty) ...<Widget>[
                    AppCard(
                      color: AppColors.surfaceMuted,
                      border: AppColors.border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Câu trả lời của bạn',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(c.userAnswer),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppCard(
                    color: AppColors.successSoft,
                    border: AppColors.success,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Đáp án',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.success),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(item.card.answer),
                        if (item.knowledge.details.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Chi tiết: ${item.knowledge.details}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: c.phase == ReviewPhase.question
              ? AppButton(
                  label: 'Xem đáp án',
                  icon: Icons.visibility_outlined,
                  onPressed: c.revealAnswer,
                )
              : _RatingBar(controller: c),
        ),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _RateButton(
          label: 'Quên',
          icon: Icons.close_rounded,
          color: AppColors.ratingAgain,
          soft: AppColors.ratingAgainSoft,
          onTap: () => controller.rate(MemoryRating.again),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RateButton(
          label: 'Khó',
          icon: Icons.sentiment_dissatisfied_rounded,
          color: AppColors.ratingHard,
          soft: AppColors.ratingHardSoft,
          onTap: () => controller.rate(MemoryRating.hard),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RateButton(
          label: 'Tốt',
          icon: Icons.check_rounded,
          color: AppColors.ratingGood,
          soft: AppColors.ratingGoodSoft,
          onTap: () => controller.rate(MemoryRating.good),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RateButton(
          label: 'Dễ',
          icon: Icons.sentiment_very_satisfied_rounded,
          color: AppColors.ratingEasy,
          soft: AppColors.ratingEasySoft,
          onTap: () => controller.rate(MemoryRating.easy),
        ),
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Đánh giá $label',
        child: Material(
          color: soft,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mdAll,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.reviewed,
    required this.again,
    required this.onDone,
  });

  final int reviewed;
  final int again;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              reviewed == 0 ? 'Không có thẻ đến hạn' : 'Hoàn thành phiên ôn!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reviewed == 0
                  ? 'Quay lại sau khi có kiến thức đến hạn nhé.'
                  : 'Đã ôn $reviewed thẻ${again > 0 ? ', ôn lại $again thẻ' : ''}.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Về trang chủ', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
