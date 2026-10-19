import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.textCapitalization = TextCapitalization.sentences,
    this.required = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextCapitalization textCapitalization;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
            child: Text.rich(
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: context.appColors.textSecondary,
                ),
                children: <InlineSpan>[
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofocus: autofocus,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          cursorColor: AppColors.primary,
          cursorWidth: 1.6,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: context.appColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 20,
                    color: context.appColors.textTertiary,
                  ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: AppSizes.touchTarget,
            ),
            suffixIcon: suffix,
            counterText: '',
          ),
        ),
        if (helper != null && !hasError)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(
              helper!,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: context.appColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Tìm kiếm...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      autofocus: autofocus,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      prefixIcon: Icons.search_rounded,
      onChanged: onChanged,
      suffix: IconButton(
        icon: Icon(
          Icons.cancel_rounded,
          size: 18,
          color: context.appColors.textTertiary,
        ),
        onPressed: onClear,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
