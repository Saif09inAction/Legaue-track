import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/data/local/league_cache.dart';

/// Saved fixtures and standings. [main] overrides this with Hive.
final leagueCacheProvider = Provider<LeagueCache>((ref) {
  return MemoryLeagueCache();
});

/// What the status line should say about the current table and fixtures.
class CacheNotice {
  const CacheNotice({this.updatedAt, this.offline = false, this.stale = false});

  final DateTime? updatedAt;
  final bool offline;
  final bool stale;

  bool get visible => updatedAt != null;
}

class CacheNoticeController extends Notifier<CacheNotice> {
  @override
  CacheNotice build() => const CacheNotice();

  void report({DateTime? updatedAt, bool offline = false, bool stale = false}) {
    state = CacheNotice(updatedAt: updatedAt, offline: offline, stale: stale);
  }
}

final cacheNoticeProvider =
    NotifierProvider<CacheNoticeController, CacheNotice>(
      CacheNoticeController.new,
    );

/// Reads the cache after a board load and publishes the status line.
Future<void> publishCacheNotice(Ref ref, {required bool offline}) async {
  final cache = ref.read(leagueCacheProvider);
  final snapshot = await cache.read();
  ref
      .read(cacheNoticeProvider.notifier)
      .report(
        updatedAt: snapshot?.updatedAt,
        offline: offline,
        stale: cache.usingStaleData,
      );
}
