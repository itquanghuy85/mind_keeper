import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/models/enums.dart';
import '../../data/models/lesson.dart';
import '../topics/topic_detail_screen.dart';
import 'lesson_service.dart';

/// Màn đọc bài học AI + quiz ghi nhớ. Sau khi đọc, người dùng làm quiz
/// (mỗi câu một lần, tự nhớ trước khi xem đáp án) để đưa bài vào lịch ôn FSRS.
class LessonReaderScreen extends StatefulWidget {
  const LessonReaderScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends State<LessonReaderScreen> {
  Lesson? _lesson;
  bool _loading = true;
  String? _error;

  bool _inQuiz = false;
  int _qIndex = 0;
  bool _revealed = false;
  final List<QuizAnswer> _answers = <QuizAnswer>[];
  bool _submitting = false;
  LessonQuizOutcome? _outcome;

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
      final Lesson? lesson = await services.lessons.getById(widget.lessonId);
      if (!mounted) return;
      setState(() {
        _lesson = lesson;
        _error = lesson == null ? 'Bài học không tồn tại.' : null;
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

  Future<void> _toggleFavorite() async {
    final Lesson? lesson = _lesson;
    if (lesson == null) return;
    final AppServices services = context.read<AppServices>();
    await services.lessonService.toggleFavorite(lesson);
    if (mounted) await _load();
  }

  Future<void> _startQuiz() async {
    final Lesson? lesson = _lesson;
    if (lesson == null) return;
    if (lesson.questions.isEmpty) {
      showAppSnack(context, message: 'Bài học này chưa có câu hỏi ghi nhớ.');
      return;
    }
    final AppServices services = context.read<AppServices>();
    await services.lessonService.markRead(lesson, read: true);
    if (!mounted) return;
    setState(() {
      _inQuiz = true;
      _qIndex = 0;
      _revealed = false;
      _answers.clear();
      _outcome = null;
    });
  }

  Future<void> _rate(MemoryRating rating) async {
    final Lesson lesson = _lesson!;
    _answers.add(QuizAnswer(questionIndex: _qIndex, rating: rating));
    if (_qIndex + 1 >= lesson.questions.length) {
      await _finishQuiz();
    } else if (mounted) {
      setState(() {
        _qIndex += 1;
        _revealed = false;
      });
    }
  }

  Future<void> _finishQuiz() async {
    final AppServices services = context.read<AppServices>();
    setState(() => _submitting = true);
    try {
      final LessonQuizOutcome outcome =
          await services.lessonService.completeQuiz(
        lesson: _lesson!,
        answers: _answers,
      );
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppSnack(context, message: e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_inQuiz ? 'Quiz ghi nhớ' : (_lesson?.title ?? 'Bài học')),
        actions: <Widget>[
          if (!_inQuiz && _lesson != null)
            IconButton(
              tooltip: _lesson!.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
              onPressed: _toggleFavorite,
              icon: Icon(
                _lesson!.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _lesson!.isFavorite ? AppColors.danger : null,
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(label: 'Đang tải bài học...');
    if (_error != null || _lesson == null) {
      return AppErrorState(message: _error ?? 'Bài học không tồn tại.');
    }
    if (_outcome != null) return _buildFinished();
    if (_inQuiz) return _buildQuiz();
    return _buildReading();
  }

  Widget _buildReading() {
    final Lesson lesson = _lesson!;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  _TagPill(
                    label: lesson.mode.label,
                    color: AppColors.primary,
                    background: AppColors.primarySoft,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _VerificationTag(lesson: lesson),
                  const Spacer(),
                  Text(
                    '${lesson.wordCount} từ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                lesson.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${lesson.domainName} · ${lesson.topic}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (lesson.medical) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: const Text(
                    'Nội dung về sức khỏe chỉ mang tính tham khảo, '
                    'không thay thế tư vấn y tế chuyên môn.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFB7791F)),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                lesson.content.introduction,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              for (final LessonSection section in lesson.content.sections) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  section.heading,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  section.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              if (lesson.content.keyPoints.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ý chính cần nhớ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final String point in lesson.content.keyPoints)
                  _Bullet(text: point),
              ],
              if (lesson.content.examples.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ví dụ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final String example in lesson.content.examples)
                  _Bullet(text: example),
              ],
              if (lesson.content.summary.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  color: AppColors.primarySoftAlt,
                  border: AppColors.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tóm tắt',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(lesson.content.summary),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _SourcesSection(
                lesson: lesson,
                onConfirm: () async {
                  final AppServices services = context.read<AppServices>();
                  await services.lessonService.confirmVerification(lesson);
                  if (mounted) await _load();
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: AppButton(
            label: lesson.isRead ? 'Làm lại quiz ghi nhớ' : 'Làm quiz ghi nhớ',
            icon: Icons.quiz_outlined,
            onPressed: _startQuiz,
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz() {
    final Lesson lesson = _lesson!;
    final LessonQuestion question = lesson.questions[_qIndex];
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Text(
                '${_qIndex + 1}/${lesson.questions.length}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              Text(
                lesson.mode.label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  question.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!_revealed)
                  Text(
                    'Hãy thử tự nhớ câu trả lời trước khi xem đáp án.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else ...<Widget>[
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
                        Text(question.answer),
                        if (question.explanation.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Giải thích: ${question.explanation}',
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
          child: _submitting
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : _revealed
                  ? _QuizRatingBar(onRate: _rate)
                  : AppButton(
                      label: 'Xem đáp án',
                      icon: Icons.visibility_outlined,
                      onPressed: () => setState(() => _revealed = true),
                    ),
        ),
      ],
    );
  }

  Widget _buildFinished() {
    final LessonQuizOutcome outcome = _outcome!;
    return Center(
      child: SingleChildScrollView(
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
              'Đã ghi nhớ bài học!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chủ đề "${outcome.topic.name}" đã được tạo với '
              '${outcome.cards.length} thẻ ôn tập.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (outcome.nextDueAt != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sẽ nhắc ôn lại vào lúc cần thiết.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Xem chủ đề',
              icon: Icons.folder_open_rounded,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TopicDetailScreen(topicId: outcome.topic.id),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Xong',
              variant: AppButtonVariant.tonal,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTag extends StatelessWidget {
  const _VerificationTag({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color color, IconData icon) = switch (lesson.verification) {
      LessonVerification.confirmed => (
          AppColors.successSoft,
          AppColors.success,
          Icons.verified_rounded,
        ),
      LessonVerification.sourced => (
          AppColors.infoSoft,
          AppColors.info,
          Icons.link_rounded,
        ),
      LessonVerification.unverified => (
          AppColors.warningSoft,
          Color(0xFFB7791F),
          Icons.help_outline_rounded,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            lesson.verification.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.lesson, required this.onConfirm});

  final Lesson lesson;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final List<LessonSource> sources = lesson.sources;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Nguồn tham khảo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sources.isEmpty)
          Text(
            'Bài học do AI sinh, chưa kèm nguồn — hãy đối chiếu trước khi dùng '
            'cho việc quan trọng.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final LessonSource source in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      source.url.isEmpty
                          ? source.title
                          : '${source.title} — ${source.url}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        if (lesson.verification != LessonVerification.confirmed) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text('Đã kiểm chứng'),
            ),
          ),
        ],
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(
              Icons.circle,
              size: 6,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuizRatingBar extends StatelessWidget {
  const _QuizRatingBar({required this.onRate});

  final void Function(MemoryRating rating) onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _RateButton(
          label: 'Quên',
          icon: Icons.close_rounded,
          color: AppColors.ratingAgain,
          soft: AppColors.ratingAgainSoft,
          onTap: () => onRate(MemoryRating.again),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RateButton(
          label: 'Khó',
          icon: Icons.sentiment_dissatisfied_rounded,
          color: AppColors.ratingHard,
          soft: AppColors.ratingHardSoft,
          onTap: () => onRate(MemoryRating.hard),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RateButton(
          label: 'Tốt',
          icon: Icons.check_rounded,
          color: AppColors.ratingGood,
          soft: AppColors.ratingGoodSoft,
          onTap: () => onRate(MemoryRating.good),
        ),
        const SizedBox(width: AppSpacing.sm),
        _RateButton(
          label: 'Dễ',
          icon: Icons.sentiment_very_satisfied_rounded,
          color: AppColors.ratingEasy,
          soft: AppColors.ratingEasySoft,
          onTap: () => onRate(MemoryRating.easy),
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
