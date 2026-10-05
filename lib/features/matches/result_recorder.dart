import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/network/connectivity_controller.dart';
import 'package:league_track/features/fixtures/fixture_board.dart';
import 'package:league_track/providers/league_providers.dart';

/// Writes a full-time score through the repository, then refreshes fixtures,
/// the table, and player totals from that stored season.
class ResultRecorder extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> record({
    required String fixtureId,
    required int homeScore,
    required int awayScore,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!ref.read(isOnlineProvider)) {
        throw const OfflineException();
      }
      await ref
          .read(leagueRepositoryProvider)
          .recordResult(
            fixtureId: fixtureId,
            homeScore: homeScore,
            awayScore: awayScore,
          );
      ref.invalidate(fixturesProvider);
      ref.invalidate(standingsProvider);
      ref.invalidate(playerStatsProvider);
      ref.invalidate(topScorersProvider);
    });
    return !state.hasError;
  }
}

final resultRecorderProvider =
    NotifierProvider<ResultRecorder, AsyncValue<void>>(ResultRecorder.new);
