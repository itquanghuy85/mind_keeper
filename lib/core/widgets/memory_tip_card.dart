import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'app_card.dart';

/// Thẻ "Mẹo nhớ" ở cuối nội dung mẩu/bài học. Ẩn hoàn toàn khi [tip] rỗng
/// (nội dung cũ chưa có mẹo nhớ).
class MemoryTipCard extends StatelessWidget {
  const MemoryTipCard({super.key, required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    final String text = tip.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final TextTheme theme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Mẹo nhớ. $text',
      child: ExcludeSemantics(
        child: AppCard(
          color: context.appColors.primarySoftAlt,
          border: context.appColors.border,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: AppSizes.iconMd,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Mẹo nhớ', style: theme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(text, style: theme.bodyMedium?.copyWith(height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
