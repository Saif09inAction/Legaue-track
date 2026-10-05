import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/theme/app_spacing.dart';
import 'package:league_track/core/theme/app_text_styles.dart';
import 'package:league_track/core/theme/league_track_colors.dart';
import 'package:league_track/data/models/fixture.dart';
import 'package:league_track/data/models/team.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/features/matches/result_recorder.dart';

/// Score entry that saves through [resultRecorderProvider].
class RecordResultForm extends ConsumerStatefulWidget {
  const RecordResultForm({
    super.key,
    required this.fixture,
    required this.home,
    required this.away,
  });

  final Fixture fixture;
  final Team home;
  final Team away;

  @override
  ConsumerState<RecordResultForm> createState() => _RecordResultFormState();
}

class _RecordResultFormState extends ConsumerState<RecordResultForm> {
  late int _homeScore = widget.fixture.homeScore ?? 0;
  late int _awayScore = widget.fixture.awayScore ?? 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LeagueTrackColors>() ??
        LeagueTrackColors.light;
    final theme = Theme.of(context);
    final saving = ref.watch(resultRecorderProvider).isLoading;
    final editing = widget.fixture.status == MatchStatus.finished;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Update result' : 'Record result',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Saving marks the match as full time and rebuilds the table from every finished score.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ScoreDial(
                    team: widget.home,
                    score: _homeScore,
                    scoreKey: const Key('home-score'),
                    downKey: const Key('home-score-down'),
                    upKey: const Key('home-score-up'),
                    onChanged: saving
                        ? null
                        : (value) => setState(() => _homeScore = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    '–',
                    style: AppTextStyles.score(
                      color: theme.colorScheme.onSurface,
                    ).copyWith(fontSize: 28),
                  ),
                ),
                Expanded(
                  child: _ScoreDial(
                    team: widget.away,
                    score: _awayScore,
                    scoreKey: const Key('away-score'),
                    downKey: const Key('away-score-down'),
                    upKey: const Key('away-score-up'),
                    onChanged: saving
                        ? null
                        : (value) => setState(() => _awayScore = value),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                key: const Key('record-result-error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('save-result'),
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(saving ? 'Saving' : 'Save result'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final saved = await ref
        .read(resultRecorderProvider.notifier)
        .record(
          fixtureId: widget.fixture.id,
          homeScore: _homeScore,
          awayScore: _awayScore,
        );
    if (!mounted) {
      return;
    }
    if (!saved) {
      final error = ref.read(resultRecorderProvider).error;
      setState(() {
        _error = error is OfflineException
            ? 'You are offline. The result was not saved.'
            : 'Could not save this result.';
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Result saved. The table has been updated.'),
      ),
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({
    required this.team,
    required this.score,
    required this.scoreKey,
    required this.downKey,
    required this.upKey,
    required this.onChanged,
  });

  final Team team;
  final int score;
  final Key scoreKey;
  final Key downKey;
  final Key upKey;
  final ValueChanged<int>? onChanged;

  static const _maxScore = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<LeagueTrackColors>() ?? LeagueTrackColors.light;
    return Column(
      children: [
        Text(
          team.shortName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: downKey,
              tooltip: 'Lower ${team.shortName} score',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: onChanged == null || score == 0
                  ? null
                  : () => onChanged!(score - 1),
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$score',
                  key: scoreKey,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.score(color: theme.colorScheme.onSurface)
                      .copyWith(fontSize: 32),
                ),
              ),
            ),
            IconButton(
              key: upKey,
              tooltip: 'Raise ${team.shortName} score',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: onChanged == null || score >= _maxScore
                  ? null
                  : () => onChanged!(score + 1),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
