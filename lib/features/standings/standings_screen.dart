import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/data/models/standing.dart';
import 'package:league_track/data/models/team.dart';
import 'package:league_track/features/cache/cache_status_banner.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/features/fixtures/widgets/fixture_state_view.dart';
import 'package:league_track/features/fixtures/widgets/team_crest.dart';
import 'package:league_track/features/standings/standings_board.dart';
import 'package:league_track/providers/league_providers.dart';

/// League table. Rows come from [standingsBoardProvider], which reloads
/// after a recorded result.
class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(standingsBoardProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final horizontal = wide ? AppSpacing.xxl : AppSpacing.lg;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: RefreshIndicator(
                onRefresh: () => _refresh(ref),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverAppBar(
                      pinned: true,
                      toolbarHeight: 76,
                      title: _Title(),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        AppSpacing.sm,
                        horizontal,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          const SliverToBoxAdapter(child: CacheStatusBanner()),
                          board.when(
                            skipLoadingOnReload: true,
                            loading: () => const SliverToBoxAdapter(
                              child: _StandingsLoading(
                                key: Key('standings-loading'),
                              ),
                            ),
                            error: (error, _) => SliverFillRemaining(
                              hasScrollBody: false,
                              child: error is OfflineException
                                  ? FixtureStateView(
                                      key: const Key('standings-offline'),
                                      icon: Icons.wifi_off_rounded,
                                      title: 'You are offline',
                                      message: 'The table needs a connection. Pull to refresh or try again when you are back online.',
                                      actionLabel: 'Try again',
                                      onAction: () => _refresh(ref),
                                    )
                                  : FixtureStateView(
                                      key: const Key('standings-error'),
                                      icon: Icons.error_outline_rounded,
                                      title: 'Could not load the table',
                                      message: 'Something went wrong while calculating the standings.',
                                      actionLabel: 'Try again',
                                      onAction: () => _refresh(ref),
                                    ),
                            ),
                            data: (data) => SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Win ${AppConstants.pointsForWin} · Draw ${AppConstants.pointsForDraw} · Loss ${AppConstants.pointsForLoss}. Ordered by points, then goal difference, then goals scored.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              Theme.of(context)
                                                  .extension<
                                                    LeagueTrackColors
                                                  >()
                                                  ?.muted ??
                                              LeagueTrackColors.light.muted,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _StandingsTable(board: data),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(isOnlineProvider);
    ref.invalidate(standingsProvider);
    ref.invalidate(teamsProvider);
    ref.invalidate(standingsBoardProvider);
    try {
      await ref.read(standingsBoardProvider.future);
    } catch (_) {}
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Standings', style: Theme.of(context).textTheme.titleLarge),
        Text(
          '${AppConstants.leagueName} · ${AppConstants.season}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.board});

  final StandingsBoard board;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    if (board.standings.isEmpty) {
      return const FixtureStateView(
        key: Key('standings-empty'),
        icon: Icons.leaderboard_outlined,
        title: 'No standings yet',
        message: 'The table appears after the first full-time result.',
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              key: const Key('standings-table'),
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  horizontalMargin: AppSpacing.lg,
                  columnSpacing: AppSpacing.md,
                  headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                  columns: const [
                    DataColumn(label: Text('POS')),
                    DataColumn(label: Text('TEAM')),
                    DataColumn(label: Text('P'), numeric: true),
                    DataColumn(label: Text('W'), numeric: true),
                    DataColumn(label: Text('D'), numeric: true),
                    DataColumn(label: Text('L'), numeric: true),
                    DataColumn(label: Text('GF'), numeric: true),
                    DataColumn(label: Text('GA'), numeric: true),
                    DataColumn(label: Text('GD'), numeric: true),
                    DataColumn(label: Text('PTS'), numeric: true),
                  ],
                  rows: [
                    for (final standing in board.standings)
                      _row(
                        context,
                        standing: standing,
                        team: board.teamById(standing.teamId),
                        colors: colors,
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

  DataRow _row(
    BuildContext context, {
    required Standing standing,
    required Team? team,
    required LeagueTrackColors colors,
  }) {
    final leader = standing.position == 1;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final name = team?.name ?? standing.teamId;
    final highlight = colors.gold.withValues(alpha: 0.18);

    Text stat(String value, {Key? key, Color? color, FontWeight? weight}) {
      return Text(
        value,
        key: key,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color ?? onSurface,
          fontWeight: weight ?? FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return DataRow(
      key: ValueKey('standing-row-${standing.teamId}'),
      color: WidgetStatePropertyAll(leader ? highlight : null),
      cells: [
        DataCell(
          Container(
            key: leader ? const Key('standing-leader') : null,
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: leader
                ? BoxDecoration(color: colors.gold, shape: BoxShape.circle)
                : null,
            child: Text(
              '${standing.position}',
              key: Key('standing-${standing.teamId}-pos'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: leader ? const Color(0xFF101828) : onSurface,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 168,
            child: Row(
              children: [
                if (team != null) ...[
                  TeamCrest(team: team, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: leader ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          stat(
            '${standing.played}',
            key: Key('standing-${standing.teamId}-played'),
          ),
        ),
        DataCell(stat('${standing.won}')),
        DataCell(stat('${standing.drawn}')),
        DataCell(stat('${standing.lost}')),
        DataCell(stat('${standing.goalsFor}')),
        DataCell(stat('${standing.goalsAgainst}')),
        DataCell(
          stat(
            _signed(standing.goalDifference),
            key: Key('standing-${standing.teamId}-gd'),
            color: _differenceColor(standing.goalDifference, colors, onSurface),
          ),
        ),
        DataCell(
          stat(
            '${standing.points}',
            key: Key('standing-${standing.teamId}-pts'),
            weight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';

  Color _differenceColor(int value, LeagueTrackColors colors, Color neutral) {
    if (value > 0) {
      return colors.win;
    }
    if (value < 0) {
      return colors.loss;
    }
    return neutral;
  }
}

class _StandingsLoading extends StatelessWidget {
  const _StandingsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    return Column(
      children: [
        for (var index = 0; index < 8; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: colors.line.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
      ],
    );
  }
}
