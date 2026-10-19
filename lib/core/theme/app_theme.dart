import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_palette.dart';

abstract final class AppTheme {
  static const String fontFamily = 'Inter';

  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // ========== LIGHT THEME ==========
  static ThemeData light() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.textOnPrimary,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.textOnPrimary,
          error: AppColors.danger,
          onError: AppColors.textOnPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerLowest: AppColors.surfaceContainerLowest,
          surfaceContainerLow: AppColors.surfaceContainerLow,
          surfaceContainer: AppColors.surfaceContainer,
          surfaceContainerHigh: AppColors.surfaceContainerHigh,
          surfaceContainerHighest: AppColors.surfaceContainerHighest,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          shadow: AppColors.shadowStrong,
          brightness: Brightness.light,
        ).copyWith(
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondaryContainer: AppColors.secondarySoft,
          onSecondaryContainer: AppColors.secondaryDark,
          tertiaryContainer: AppColors.tertiarySoft,
          onTertiaryContainer: AppColors.tertiary,
          errorContainer: AppColors.dangerContainer,
          onErrorContainer: AppColors.onDangerContainer,
          surfaceTint: Colors.transparent,
          onSurfaceVariant: AppColors.textTertiary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const <ThemeExtension<dynamic>>[AppPalette.lightPalette],
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.04),
      focusColor: AppColors.primary.withValues(alpha: 0.10),
      hintColor: AppColors.textTertiary,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.selection,
        selectionHandleColor: AppColors.primary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppSizes.dividerThickness,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleSpacing: AppSpacing.lg,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      ),
      textTheme: _textTheme(Brightness.light),
      filledButtonTheme: FilledButtonThemeData(style: _filledButtonStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(Brightness.light),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(Brightness.light),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(Brightness.light),
      ),
      inputDecorationTheme: _inputDecorationTheme(Brightness.light),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppSizes.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryContainer,
        checkmarkColor: AppColors.primary,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimaryContainer,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 0,
        ),
        showCheckmark: false,
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: AppSizes.iconSm,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppSizes.cardElevationElevated,
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14.5,
          height: 1.55,
          color: AppColors.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxlTop),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        dayPeriodShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        dayPeriodBorderSide: const BorderSide(color: AppColors.border),
        dialBackgroundColor: AppColors.surfaceMuted,
        dialHandColor: AppColors.primary,
        dialTextColor: WidgetStateColor.resolveWith(_timeDialTextColor),
        entryModeIconColor: AppColors.textSecondary,
        helpTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.4,
          color: Colors.white,
        ),
        actionTextColor: Color(0xFF8FBBFF),
        elevation: 4,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceMutedStrong,
        linearMinHeight: 6,
        circularTrackColor: AppColors.surfaceMuted,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.textSecondary,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.bottomNavHeight,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.1,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        overlayColor: WidgetStatePropertyAll<Color>(
          AppColors.primary.withValues(alpha: 0.06),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceMutedStrong,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x1F0068FF),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 1),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceMutedStrong;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.borderStrong;
        }),
        trackOutlineWidth: const WidgetStatePropertyAll<double>(1),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: AppColors.shadowStrong,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: fontFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12.5,
          height: 1.3,
          color: Colors.white,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll<double>(4),
        radius: const Radius.circular(4),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.hovered)) {
            return AppColors.borderStrong;
          }
          return AppColors.border;
        }),
      ),
    );
  }

  // ========== DARK THEME ==========
  static ThemeData dark() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimaryDark,
          secondary: AppColors.secondary,
          onSecondary: AppColors.textOnPrimaryDark,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.textOnPrimaryDark,
          error: AppColors.danger,
          onError: AppColors.textOnPrimaryDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
          surfaceContainerLow: AppColors.surfaceContainerLowDark,
          surfaceContainer: AppColors.surfaceContainerDark,
          surfaceContainerHigh: AppColors.surfaceContainerHighDark,
          surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
          outline: AppColors.outlineDark,
          outlineVariant: AppColors.outlineVariantDark,
          shadow: AppColors.shadowDark,
          brightness: Brightness.dark,
        ).copyWith(
          primaryContainer: AppColors.primaryContainerDark,
          onPrimaryContainer: AppColors.onPrimaryContainerDark,
          secondaryContainer: AppColors.secondarySoftDark,
          onSecondaryContainer: AppColors.secondary,
          tertiaryContainer: AppColors.infoSoftDark,
          onTertiaryContainer: AppColors.infoTextDark,
          errorContainer: AppColors.dangerContainerDark,
          onErrorContainer: AppColors.dangerTextDark,
          surfaceTint: Colors.transparent,
          onSurfaceVariant: AppColors.textTertiaryDark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const <ThemeExtension<dynamic>>[AppPalette.darkPalette],
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.06),
      focusColor: AppColors.primary.withValues(alpha: 0.14),
      hintColor: AppColors.textTertiaryDark,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.selection,
        selectionHandleColor: AppColors.primary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 22,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: AppSizes.dividerThickness,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleSpacing: AppSpacing.lg,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textPrimaryDark,
          height: 1.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark, size: 24),
        actionsIconTheme: IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 24,
        ),
      ),
      textTheme: _textTheme(Brightness.dark),
      filledButtonTheme: FilledButtonThemeData(style: _filledButtonStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(Brightness.dark),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(Brightness.dark),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(Brightness.dark),
      ),
      inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: AppSizes.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.borderDark),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primaryContainerDark,
        checkmarkColor: AppColors.primaryBright,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimaryContainerDark,
        ),
        side: const BorderSide(color: AppColors.borderDark),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 0,
        ),
        showCheckmark: false,
        iconTheme: const IconThemeData(
          color: AppColors.textSecondaryDark,
          size: AppSizes.iconSm,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: AppSizes.cardElevationElevated,
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14.5,
          height: 1.55,
          color: AppColors.textSecondaryDark,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrongDark,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxlTop),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        dayPeriodShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        dayPeriodBorderSide: const BorderSide(color: AppColors.borderDark),
        dialBackgroundColor: AppColors.surfaceContainerDark,
        dialHandColor: AppColors.primaryBright,
        dialTextColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) =>
              _timeDialTextColor(states, brightness: Brightness.dark),
        ),
        entryModeIconColor: AppColors.textSecondaryDark,
        helpTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimaryDark,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.4,
          color: Colors.white,
        ),
        actionTextColor: Color(0xFF8FBBFF),
        elevation: 4,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryBright,
        unselectedLabelColor: AppColors.textSecondaryDark,
        indicatorColor: AppColors.primaryBright,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.borderDark,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBright,
        linearTrackColor: AppColors.surfaceContainerDark,
        linearMinHeight: 6,
        circularTrackColor: AppColors.surfaceContainerLowDark,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.textSecondaryDark,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          height: 1.4,
          color: AppColors.textSecondaryDark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryBright,
        unselectedItemColor: AppColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.bottomNavHeight,
        indicatorColor: AppColors.primaryContainerDark,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.1,
            color: selected
                ? AppColors.primaryBright
                : AppColors.textSecondaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? AppColors.primaryBright
                : AppColors.textSecondaryDark,
          );
        }),
        overlayColor: WidgetStatePropertyAll<Color>(
          AppColors.primary.withValues(alpha: 0.08),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        activeTrackColor: AppColors.primaryBright,
        inactiveTrackColor: AppColors.surfaceContainerDark,
        thumbColor: AppColors.primaryBright,
        overlayColor: Color(0x1F0068FF),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 1),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.surfaceDark;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBright;
          }
          return AppColors.surfaceContainerDark;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.borderStrongDark;
        }),
        trackOutlineWidth: const WidgetStatePropertyAll<double>(1),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimaryDark,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: AppColors.shadowDark,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: fontFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimaryDark,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12.5,
          height: 1.3,
          color: Colors.white,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll<double>(4),
        radius: const Radius.circular(4),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.hovered)) {
            return AppColors.borderStrongDark;
          }
          return AppColors.borderDark;
        }),
      ),
    );
  }

  // ========== COMMON HELPERS ==========
  static Color _timeDialTextColor(
    Set<WidgetState> states, {
    Brightness brightness = Brightness.light,
  }) {
    if (states.contains(WidgetState.selected)) return Colors.white;
    return brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
  }

  static ButtonStyle _filledButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.primary.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.pressed)) {
          return AppColors.primaryPressed;
        }
        if (states.contains(WidgetState.hovered)) return AppColors.primaryDark;
        return AppColors.primary;
      }),
      foregroundColor: const WidgetStatePropertyAll<Color>(
        AppColors.textOnPrimary,
      ),
      overlayColor: WidgetStatePropertyAll<Color>(
        Colors.white.withValues(alpha: 0.08),
      ),
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size.fromHeight(AppSizes.controlHeight),
      ),
      elevation: const WidgetStatePropertyAll<double>(0),
      shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(_labelLarge),
    );
  }

  static ButtonStyle _outlinedButtonStyle(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return dark ? AppColors.textTertiaryDark : AppColors.textTertiary;
        }
        return dark ? AppColors.primaryBright : AppColors.primaryDark;
      }),
      backgroundColor: WidgetStatePropertyAll<Color>(
        dark ? AppColors.surfaceDark : AppColors.surface,
      ),
      overlayColor: WidgetStatePropertyAll<Color>(
        AppColors.primary.withValues(alpha: dark ? 0.12 : 0.06),
      ),
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size.fromHeight(AppSizes.controlHeight),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
      side: WidgetStateProperty.resolveWith<BorderSide>((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: dark ? AppColors.borderDark : AppColors.border,
          );
        }
        return BorderSide(
          color: dark ? AppColors.borderStrongDark : AppColors.borderStrong,
        );
      }),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(_labelLarge),
    );
  }

  static ButtonStyle _textButtonStyle(Brightness brightness) {
    return TextButton.styleFrom(
      foregroundColor: brightness == Brightness.dark
          ? AppColors.primaryBright
          : AppColors.primary,
      minimumSize: const Size(0, AppSizes.controlHeightSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      textStyle: _labelMedium,
    );
  }

  static ButtonStyle _iconButtonStyle(Brightness brightness) {
    return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll<Color>(
        brightness == Brightness.dark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary,
      ),
      iconSize: const WidgetStatePropertyAll<double>(22),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.all(AppSpacing.md),
      ),
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(AppSizes.touchTarget, AppSizes.touchTarget),
      ),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    final Color textTertiary = dark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiary;
    final Color textSecondary = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final Color accent = dark ? AppColors.primaryBright : AppColors.primary;
    final Color fillColor = dark ? AppColors.surfaceDark : AppColors.surface;
    final Color lineColor = dark ? AppColors.borderDark : AppColors.border;
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: TextStyle(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),
      labelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: accent,
      ),
      helperStyle: TextStyle(fontSize: 12, color: textTertiary),
      helperMaxLines: 2,
      errorStyle: const TextStyle(
        fontSize: 12.5,
        height: 1.3,
        color: AppColors.danger,
      ),
      errorMaxLines: 2,
      prefixIconColor: textTertiary,
      suffixIconColor: textSecondary,
      border: _inputBorder(lineColor),
      enabledBorder: _inputBorder(lineColor),
      focusedBorder: _inputBorder(accent, width: 1.6),
      errorBorder: _inputBorder(AppColors.danger),
      focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.6),
      disabledBorder: _inputBorder(lineColor),
      constraints: const BoxConstraints(minHeight: AppSizes.controlHeight),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.lgAll,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ========== TYPOGRAPHY ==========
  static const TextStyle _labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.25,
  );

  static const TextStyle _labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextTheme _textTheme(Brightness brightness) {
    const String family = fontFamily;
    final bool dark = brightness == Brightness.dark;
    final Color cPrimary = dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final Color cSecondary = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final Color cTertiary = dark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiary;
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: family,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
        color: cPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: family,
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
        color: cPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: cPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: family,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
        color: cPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
        color: cPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: family,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
        color: cPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
        color: cPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: cPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        height: 1.4,
        color: cPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: cPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: cPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: cSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.25,
        color: cPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.3,
        color: cSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.35,
        color: cTertiary,
      ),
    );
  }
}
