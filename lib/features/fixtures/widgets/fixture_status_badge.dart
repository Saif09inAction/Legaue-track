import 'package:flutter/material.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/data/models/fixture.dart';

/// Compact status pill for a single fixture.
class FixtureStatusBadge extends StatelessWidget {
  const FixtureStatusBadge({super.key, required this.status, this.minute});

  final MatchStatus status;
  final int? minute;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    final (label, foreground, background) = switch (status) {
      MatchStatus.live => (
        'Live${minute == null ? '' : " $minute'"}',
        colors.live,
        colors.live.withValues(alpha: 0.14),
      ),
      MatchStatus.finished => (
        'Full time',
        colors.muted,
        colors.line.withValues(alpha: 0.7),
      ),
      MatchStatus.scheduled => (
        'Upcoming',
        colors.win,
        colors.win.withValues(alpha: 0.14),
      ),
      MatchStatus.postponed => (
        'Postponed',
        colors.draw,
        colors.draw.withValues(alpha: 0.16),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == MatchStatus.live) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
