import 'package:flutter/material.dart';
import 'package:league_track/core/theme/app_colors.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/app_text_styles.dart';
import 'package:league_track/core/theme/league_track_colors.dart';

/// Light and dark Material 3 themes.
abstract final class AppTheme {
  static final ThemeData light = _build(
    brightness: Brightness.light,
    scaffold: AppColors.paper,
    surface: AppColors.paperRaised,
    onSurface: AppColors.ink,
    appBar: AppColors.paper,
    onAppBar: AppColors.ink,
    colors: LeagueTrackColors.light,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    scaffold: AppColors.navy,
    surface: AppColors.navyRaised,
    onSurface: AppColors.cloud,
    appBar: AppColors.navy,
    onAppBar: AppColors.cloud,
    colors: LeagueTrackColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color appBar,
    required Color onAppBar,
    required LeagueTrackColors colors,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pitch,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      primary: AppColors.pitch,
      onPrimary: brightness == Brightness.dark ? AppColors.navy : Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.loss,
    );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      useMaterial3: true,
    );
    final textTheme = AppTextStyles.sans(base.textTheme).copyWith(
      displaySmall: AppTextStyles.score(color: onSurface),
      titleLarge: AppTextStyles.sectionTitle(color: onSurface),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: onAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.line, thickness: 1),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
