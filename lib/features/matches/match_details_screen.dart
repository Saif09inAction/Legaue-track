import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/app_text_styles.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/core/utils/date_formatters.dart';
import 'package:league_track/data/models/fixture.dart';
import 'package:league_track/data/models/match_event.dart';
import 'package:league_track/data/models/player.dart';
import 'package:league_track/data/models/standing.dart';
import 'package:league_track/data/models/team.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/features/fixtures/widgets/fixture_state_view.dart';
import 'package:league_track/features/fixtures/widgets/fixture_status_badge.dart';
import 'package:league_track/features/fixtures/widgets/team_crest.dart';
import 'package:league_track/features/matches/match_details.dart';
import 'package:league_track/features/matches/widgets/record_result_form.dart';
import 'package:league_track/providers/league_providers.dart';

/// One fixture, its events, and the table rows that a saved result updates.
class MatchDetailsScreen extends ConsumerWidget {
  const MatchDetailsScreen({super.key, required this.fixtureId});

  final String fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(matchDetailsProvider(fixtureId));

    return Scaffold(
      appBar: AppBar(title: const Text('Match details')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: details.when(
                skipLoadingOnReload: true,
                loading: () => const SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: FixtureLoadingView(),
                ),
                error: (error, _) => CenteredScrollable(
                  child: FixtureStateView(
                    icon: error is OfflineException
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    title: error is OfflineException
                        ? 'You are offline'
                        : 'Could not load this match',
                    message: error is OfflineException
                        ? 'Match details need a connection.'
                        : 'Something went wrong while fetching this fixture.',
                    actionLabel: 'Try again',
                    onAction: () =>
                        ref.invalidate(matchDetailsProvider(fixtureId)),
                  ),
                ),
                data: (match) => ListView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? AppSpacing.xxl : AppSpacing.lg,
                    AppSpacing.sm,
                    wide ? AppSpacing.xxl : AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    _Scoreboard(
                      fixture: match.fixture,
                      home: match.home,
                      away: match.away,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _MatchStatistics(match: match),
                    const SizedBox(height: AppSpacing.lg),
                    RecordResultForm(
                      fixture: match.fixture,
                      home: match.home,
                      away: match.away,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TableImpact(match: match),
                    const SizedBox(height: AppSpacing.lg),
                    _EventsSection(
                      match: match,
                      onRetry: () {
                        ref.invalidate(fixtureEventsProvider(fixtureId));
                        ref.invalidate(playersProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.fixture,
    required this.home,
    required this.away,
  });

  final Fixture fixture;
  final Team home;
  final Team away;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Club(team: home)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: _Score(fixture: fixture),
                ),
                Expanded(child: _Club(team: away)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Fact(
              label: 'Date',
              value: DateFormatters.formatDate(fixture.kickoff),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Fact(
              label: 'Time',
              value: DateFormatters.formatTime(fixture.kickoff),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Fact(
              label: 'Venue',
              value: fixture.venue.isEmpty ? home.stadium : fixture.venue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Club extends StatelessWidget {
  const _Club({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamCrest(team: team, size: 52),
        const SizedBox(height: AppSpacing.sm),
        Text(
          team.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = AppTextStyles.score(color: theme.colorScheme.onSurface)
        .copyWith(fontSize: 36);
    if (!fixture.hasScore) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          DateFormatters.formatTime(fixture.kickoff),
          style: style.copyWith(fontSize: 28),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${fixture.homeScore}', style: style),
          TextSpan(text: '  –  ', style: style.copyWith(fontSize: 28)),
          TextSpan(text: '${fixture.awayScore}', style: style),
        ],
      ),
      key: const Key('match-scoreline'),
      textAlign: TextAlign.center,
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchStatistics extends StatelessWidget {
  const _MatchStatistics({required this.match});

  final MatchDetails match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    final home = _count(match.home.id);
    final away = _count(match.away.id);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Counted from the goals and cards in this match.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Spacer(),
                _StatValue(match.home.shortName, muted: true),
                const SizedBox(width: 28),
                _StatValue(match.away.shortName, muted: true),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatLine(
              label: 'Goals',
              home: '${home.goals}',
              away: '${away.goals}',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatLine(
              label: 'Yellow cards',
              home: '${home.yellow}',
              away: '${away.yellow}',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatLine(
              label: 'Red cards',
              home: '${home.red}',
              away: '${away.red}',
            ),
          ],
        ),
      ),
    );
  }

  ({int goals, int yellow, int red}) _count(String teamId) {
    var goals = 0;
    var yellow = 0;
    var red = 0;
    for (final event in match.events) {
      if (event.teamId != teamId) {
        continue;
      }
      switch (event.type) {
        case MatchEventType.goal:
          goals++;
        case MatchEventType.yellowCard:
          yellow++;
        case MatchEventType.redCard:
          red++;
      }
    }
    return (goals: goals, yellow: yellow, red: red);
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue(this.value, {this.muted = false});

  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    return SizedBox(
      width: 36,
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: muted ? colors.muted : null,
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.home,
    required this.away,
  });

  final String label;
  final String home;
  final String away;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        _StatValue(home),
        const SizedBox(
          width: 28,
          child: Text('–', textAlign: TextAlign.center),
        ),
        _StatValue(away),
      ],
    );
  }
}

class _TableImpact extends StatelessWidget {
  const _TableImpact({required this.match});

  final MatchDetails match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Points and matches played update as soon as a result is saved.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            _StandingRow(
              standing: match.standingFor(match.home.id),
              team: match.home,
              pointsKey: const Key('home-standing-points'),
              playedKey: const Key('home-standing-played'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StandingRow(
              standing: match.standingFor(match.away.id),
              team: match.away,
              pointsKey: const Key('away-standing-points'),
              playedKey: const Key('away-standing-played'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.standing,
    required this.team,
    required this.pointsKey,
    required this.playedKey,
  });

  final Standing? standing;
  final Team team;
  final Key pointsKey;
  final Key playedKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    final row = standing;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            row == null ? '–' : '${row.position}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TeamCrest(team: team, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          row == null ? '–' : 'P ${row.played}',
          key: playedKey,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          row == null ? '–' : '${row.points}',
          key: pointsKey,
          style: AppTextStyles.score(color: theme.colorScheme.onSurface)
              .copyWith(fontSize: 22),
        ),
      ],
    );
  }
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.match, required this.onRetry});

  final MatchDetails match;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    final ordered = [...match.events]
      ..sort((a, b) => a.minute.compareTo(b.minute));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!match.eventsAvailable)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Events could not be loaded.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ],
              )
            else if (ordered.isEmpty)
              Text(
                'No match events yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.muted,
                ),
              )
            else
              for (final event in ordered) ...[
                _EventTile(
                  event: event,
                  player: match.playerById(event.playerId),
                  side: event.teamId == match.home.id
                      ? match.home
                      : event.teamId == match.away.id
                      ? match.away
                      : null,
                ),
                if (event != ordered.last)
                  const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.player,
    required this.side,
  });

  final MatchEvent event;
  final Player? player;
  final Team? side;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    final (icon, color, label) = switch (event.type) {
      MatchEventType.goal => (
        Icons.sports_soccer_rounded,
        theme.colorScheme.onSurface,
        'Goal',
      ),
      MatchEventType.yellowCard => (
        Icons.rectangle_rounded,
        colors.draw,
        'Yellow card',
      ),
      MatchEventType.redCard => (
        Icons.rectangle_rounded,
        colors.loss,
        'Red card',
      ),
    };
    final name = player?.name ?? 'Unknown player';
    final club = side?.shortName;
    final summary = club == null ? '$label · $name' : '$label · $name · $club';
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            "${event.minute}'",
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
