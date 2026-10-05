import 'package:flutter/material.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/league_track_colors.dart';

/// Centers [child] when it fits, and scrolls it when the viewport is short.
class CenteredScrollable extends StatelessWidget {
  const CenteredScrollable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [child],
            ),
          ),
        );
      },
    );
  }
}

/// Shared empty, error, and offline message for the fixtures feed.
class FixtureStateView extends StatelessWidget {
  const FixtureStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.muted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Placeholder cards shown while the fixture feed is loading.
class FixtureLoadingView extends StatelessWidget {
  const FixtureLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    return Column(
      children: [
        for (var index = 0; index < 4; index++) ...[
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.line),
            ),
          ),
          if (index != 3) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
