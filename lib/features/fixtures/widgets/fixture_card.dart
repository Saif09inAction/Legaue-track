import 'package:flutter/material.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/app_text_styles.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/core/utils/date_formatters.dart';
import 'package:league_track/data/models/fixture.dart';
import 'package:league_track/data/models/team.dart';
import 'package:league_track/features/fixtures/widgets/fixture_status_badge.dart';
import 'package:league_track/features/fixtures/widgets/team_crest.dart';

/// One match, used for upcoming, live, and completed fixtures.
class FixtureCard extends StatelessWidget {
  const FixtureCard({
    super.key,
    required this.fixture,
    required this.home,
    required this.away,
    this.onTap,
  });

  final Fixture fixture;
  final Team home;
  final Team away;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    final theme = Theme.of(context);
    final homeLeading = _isLeading(fixture.homeScore, fixture.awayScore);
    final awayLeading = _isLeading(fixture.awayScore, fixture.homeScore);

    return Semantics(
      container: true,
      button: onTap != null,
      label: _description,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Matchweek ${fixture.matchWeek}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FixtureStatusBadge(
                      status: fixture.status,
                      minute: fixture.minute,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _TeamLine(
                            team: home,
                            emphasized: homeLeading,
                            muted: awayLeading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _TeamLine(
                            team: away,
                            emphasized: awayLeading,
                            muted: homeLeading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _ResultColumn(
                      fixture: fixture,
                      homeLeading: homeLeading,
                      awayLeading: awayLeading,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _footer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _description {
    final place = fixture.venue.isEmpty ? home.stadium : fixture.venue;
    final score = fixture.hasScore
        ? '${fixture.homeScore} to ${fixture.awayScore}'
        : 'kickoff ${DateFormatters.formatTime(fixture.kickoff)}';
    return '${home.name} versus ${away.name}, ${fixture.status.label}, $score, ${DateFormatters.formatDate(fixture.kickoff)}, $place';
  }

  String get _footer {
    final place = fixture.venue.isEmpty ? home.stadium : fixture.venue;
    return '$place · ${DateFormatters.formatDate(fixture.kickoff)}';
  }

  bool _isLeading(int? score, int? opponent) {
    if (!fixture.hasScore || score == null || opponent == null) {
      return false;
    }
    return score > opponent;
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.team,
    required this.emphasized,
    required this.muted,
  });

  final Team team;
  final bool emphasized;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
      color: muted ? colors.muted : null,
    );
    return Row(
      children: [
        TeamCrest(team: team),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _ResultColumn extends StatelessWidget {
  const _ResultColumn({
    required this.fixture,
    required this.homeLeading,
    required this.awayLeading,
  });

  final Fixture fixture;
  final bool homeLeading;
  final bool awayLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    if (!fixture.hasScore) {
      return SizedBox(
        width: 72,
        child: Text(
          DateFormatters.formatTime(fixture.kickoff),
          textAlign: TextAlign.center,
          style: AppTextStyles.score(color: theme.colorScheme.onSurface)
              .copyWith(fontSize: 26),
        ),
      );
    }

    TextStyle scoreStyle({required bool trailing}) {
      final color = trailing ? colors.muted : theme.colorScheme.onSurface;
      return AppTextStyles.score(color: color).copyWith(fontSize: 28);
    }

    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Text(
            '${fixture.homeScore}',
            textAlign: TextAlign.center,
            style: scoreStyle(trailing: awayLeading),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${fixture.awayScore}',
            textAlign: TextAlign.center,
            style: scoreStyle(trailing: homeLeading),
          ),
        ],
      ),
    );
  }
}
