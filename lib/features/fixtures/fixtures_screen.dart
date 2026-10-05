import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/core/theme/app_colors.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/core/utils/date_formatters.dart';
import 'package:league_track/data/models/fixture.dart';
import 'package:league_track/data/models/team.dart';
import 'package:league_track/features/cache/cache_status_banner.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/features/fixtures/widgets/fixture_card.dart';
import 'package:league_track/features/matches/match_details_screen.dart';
import 'package:league_track/providers/league_providers.dart';
import 'package:league_track/features/fixtures/widgets/fixture_state_view.dart';

enum FixtureListFilter { upcoming, live, completed }

/// Matchweek fixtures with upcoming, live, and completed views.
class FixturesScreen extends ConsumerStatefulWidget {
  const FixturesScreen({super.key});

  @override
  ConsumerState<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends ConsumerState<FixturesScreen> {
  int? _week;
  FixtureListFilter? _filter;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(fixtureBoardProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final horizontal = wide ? AppSpacing.xxl : AppSpacing.lg;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: RefreshIndicator(
                onRefresh: _refresh,
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
                              child: FixtureLoadingView(),
                            ),
                            error: (error, _) => SliverFillRemaining(
                              hasScrollBody: false,
                              child: error is OfflineException
                                  ? FixtureStateView(
                                      key: const Key('fixtures-offline'),
                                      icon: Icons.wifi_off_rounded,
                                      title: 'You are offline',
                                      message: 'Fixtures need a connection. Pull to refresh or try again when you are back online.',
                                      actionLabel: 'Try again',
                                      onAction: () => _refresh(),
                                    )
                                  : FixtureStateView(
                                      key: const Key('fixtures-error'),
                                      icon: Icons.error_outline_rounded,
                                      title: 'Could not load fixtures',
                                      message: 'Something went wrong while fetching the match list.',
                                      actionLabel: 'Try again',
                                      onAction: () => _refresh(),
                                    ),
                            ),
                            data: (data) {
                              final week =
                                  _week ?? _preferredWeek(data.fixtures);
                              if (_week == null) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted && _week == null) {
                                    setState(() => _week = week);
                                  }
                                });
                              }
                              return _schedule(data);
                            },
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

  Widget _schedule(FixtureBoard board) {
    final weeks =
        board.fixtures.map((fixture) => fixture.matchWeek).toSet().toList()
          ..sort();
    final week = _week ?? _preferredWeek(board.fixtures);
    final weekFixtures = board.fixtures
        .where((fixture) => fixture.matchWeek == week)
        .toList();
    final filter = _filter ?? _preferredFilter(weekFixtures);
    final visible = weekFixtures.where(filter.matches).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MatchweekBar(
                weeks: weeks,
                selected: week,
                onSelected: (value) {
                  setState(() {
                    _week = value;
                    _filter = _preferredFilter(
                      board.fixtures
                          .where((fixture) => fixture.matchWeek == value)
                          .toList(),
                    );
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterBar(
                selected: filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: FixtureStateView(
              key: const Key('fixtures-empty'),
              icon: filter.emptyIcon,
              title: filter.emptyTitle,
              message: filter.emptyMessage,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final groups = _groupByDay(visible);
              final day = groups.keys.elementAt(index);
              final fixtures = groups[day]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatters.formatMatchDay(day),
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final fixture in fixtures) ...[
                      FixtureCard(
                        key: Key('fixture-${fixture.id}'),
                        fixture: fixture,
                        home:
                            board.teamById(fixture.homeTeamId) ??
                            _placeholder(fixture.homeTeamId),
                        away:
                            board.teamById(fixture.awayTeamId) ??
                            _placeholder(fixture.awayTeamId),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  MatchDetailsScreen(fixtureId: fixture.id),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              );
            }, childCount: _groupByDay(visible).length),
          ),
      ],
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(isOnlineProvider);
    ref.invalidate(fixturesProvider);
    ref.invalidate(teamsProvider);
    ref.invalidate(fixtureBoardProvider);
    try {
      await ref.read(fixtureBoardProvider.future);
    } catch (_) {}
  }

  int _preferredWeek(List<Fixture> fixtures) {
    if (fixtures.isEmpty) {
      return 1;
    }
    final liveWeek = fixtures
        .where((fixture) => fixture.status == MatchStatus.live)
        .map((fixture) => fixture.matchWeek);
    if (liveWeek.isNotEmpty) {
      return liveWeek.first;
    }
    final upcoming = fixtures
        .where(
          (fixture) =>
              fixture.status == MatchStatus.scheduled ||
              fixture.status == MatchStatus.postponed,
        )
        .map((fixture) => fixture.matchWeek);
    if (upcoming.isNotEmpty) {
      return upcoming.reduce((a, b) => a < b ? a : b);
    }
    return fixtures
        .map((fixture) => fixture.matchWeek)
        .reduce((a, b) => a > b ? a : b);
  }

  FixtureListFilter _preferredFilter(List<Fixture> weekFixtures) {
    if (weekFixtures.any((fixture) => fixture.status == MatchStatus.live)) {
      return FixtureListFilter.live;
    }
    if (weekFixtures.any(
      (fixture) => filterMatches(FixtureListFilter.upcoming, fixture),
    )) {
      return FixtureListFilter.upcoming;
    }
    return FixtureListFilter.completed;
  }

  Map<DateTime, List<Fixture>> _groupByDay(List<Fixture> fixtures) {
    final groups = <DateTime, List<Fixture>>{};
    for (final fixture in fixtures) {
      final day = DateTime(
        fixture.kickoff.year,
        fixture.kickoff.month,
        fixture.kickoff.day,
      );
      groups.putIfAbsent(day, () => []).add(fixture);
    }
    return groups;
  }

  Team _placeholder(String id) {
    final label = id.toUpperCase();
    return Team(
      id: id,
      leagueId: AppConstants.leagueId,
      name: label,
      shortName: label.length > 3 ? label.substring(0, 3) : label,
      city: '',
      stadium: '',
      stadiumCapacity: 0,
      founded: 0,
      manager: '',
      primaryColor: AppColors.navy,
      secondaryColor: Colors.white,
    );
  }
}

bool filterMatches(FixtureListFilter filter, Fixture fixture) {
  return switch (filter) {
    FixtureListFilter.upcoming =>
      fixture.status == MatchStatus.scheduled ||
          fixture.status == MatchStatus.postponed,
    FixtureListFilter.live => fixture.status == MatchStatus.live,
    FixtureListFilter.completed => fixture.status == MatchStatus.finished,
  };
}

extension on FixtureListFilter {
  bool matches(Fixture fixture) => filterMatches(this, fixture);

  IconData get emptyIcon => switch (this) {
    FixtureListFilter.upcoming => Icons.event_available_outlined,
    FixtureListFilter.live => Icons.sensors_off_outlined,
    FixtureListFilter.completed => Icons.emoji_events_outlined,
  };

  String get emptyTitle => switch (this) {
    FixtureListFilter.upcoming => 'No upcoming fixtures',
    FixtureListFilter.live => 'No live matches',
    FixtureListFilter.completed => 'No completed fixtures',
  };

  String get emptyMessage => switch (this) {
    FixtureListFilter.upcoming => 'This matchweek has no scheduled games.',
    FixtureListFilter.live => 'Nothing is in progress in this matchweek.',
    FixtureListFilter.completed =>
      'Full-time results will show up here after the games are played.',
  };
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
        Text('Fixtures', style: Theme.of(context).textTheme.titleLarge),
        Text(
          '${AppConstants.leagueName} · ${AppConstants.season}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _MatchweekBar extends StatelessWidget {
  const _MatchweekBar({
    required this.weeks,
    required this.selected,
    required this.onSelected,
  });

  final List<int> weeks;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final week in weeks)
          FilterChip(
            key: Key('matchweek-$week'),
            label: Text('MW $week'),
            selected: week == selected,
            onSelected: (_) => onSelected(week),
            showCheckmark: false,
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final FixtureListFilter selected;
  final ValueChanged<FixtureListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return SegmentedButton<FixtureListFilter>(
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: FixtureListFilter.upcoming,
          label: const Text('Upcoming'),
          icon: compact ? null : const Icon(Icons.schedule),
        ),
        ButtonSegment(
          value: FixtureListFilter.live,
          label: const Text('Live'),
          icon: compact ? null : const Icon(Icons.sensors),
        ),
        ButtonSegment(
          value: FixtureListFilter.completed,
          label: const Text('Completed'),
          icon: compact ? null : const Icon(Icons.flag_outlined),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}
