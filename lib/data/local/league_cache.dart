import 'package:hive/hive.dart';
import 'package:league_track/data/local/league_snapshot.dart';
import 'package:league_track/data/models/models.dart';

/// Local copy of the fixture list and table.
abstract interface class LeagueCache {
  Future<LeagueSnapshot?> read();

  /// Merges the provided lists into the saved snapshot.
  ///
  /// Only the lists passed in are marked fresh. A list left out keeps its
  /// stale flag, so a later club refresh cannot hide a failed fixture fetch.
  Future<void> save({
    List<Fixture>? fixtures,
    List<Standing>? standings,
    List<Team>? teams,
  });

  /// A saved list is being shown because its latest fetch failed.
  bool get usingStaleData;

  /// Marks the listed collections stale. With no flags, every collection is stale.
  void markStale({
    bool fixtures = false,
    bool standings = false,
    bool teams = false,
  });
}

class _StaleFlags {
  bool fixtures = false;
  bool standings = false;
  bool teams = false;

  bool get any => fixtures || standings || teams;

  void mark({
    bool fixtures = false,
    bool standings = false,
    bool teams = false,
  }) {
    if (!fixtures && !standings && !teams) {
      this.fixtures = true;
      this.standings = true;
      this.teams = true;
      return;
    }
    if (fixtures) {
      this.fixtures = true;
    }
    if (standings) {
      this.standings = true;
    }
    if (teams) {
      this.teams = true;
    }
  }

  void clearWritten({
    required bool fixtures,
    required bool standings,
    required bool teams,
  }) {
    if (fixtures) {
      this.fixtures = false;
    }
    if (standings) {
      this.standings = false;
    }
    if (teams) {
      this.teams = false;
    }
  }
}

/// Cache kept in memory for tests and as the provider default.
class MemoryLeagueCache implements LeagueCache {
  LeagueSnapshot? _snapshot;
  final _stale = _StaleFlags();

  @override
  bool get usingStaleData => _stale.any;

  @override
  Future<LeagueSnapshot?> read() async => _snapshot;

  @override
  Future<void> save({
    List<Fixture>? fixtures,
    List<Standing>? standings,
    List<Team>? teams,
  }) async {
    final current = _snapshot;
    _snapshot = LeagueSnapshot(
      fixtures: List<Fixture>.from(fixtures ?? current?.fixtures ?? const []),
      standings: List<Standing>.from(
        standings ?? current?.standings ?? const [],
      ),
      teams: List<Team>.from(teams ?? current?.teams ?? const []),
      updatedAt: DateTime.now(),
    );
    _stale.clearWritten(
      fixtures: fixtures != null,
      standings: standings != null,
      teams: teams != null,
    );
  }

  @override
  void markStale({
    bool fixtures = false,
    bool standings = false,
    bool teams = false,
  }) {
    if (_snapshot == null) {
      return;
    }
    _stale.mark(fixtures: fixtures, standings: standings, teams: teams);
  }
}

/// Hive box of one JSON snapshot. Preferences stay in shared preferences.
class HiveLeagueCache implements LeagueCache {
  HiveLeagueCache(this._box);

  static const boxName = 'local_league_cache';
  static const _snapshotKey = 'snapshot';

  final Box<String> _box;
  LeagueSnapshot? _memory;
  final _stale = _StaleFlags();

  @override
  bool get usingStaleData => _stale.any;

  @override
  Future<LeagueSnapshot?> read() async {
    final cached = _memory;
    if (cached != null) {
      return cached;
    }
    final raw = _box.get(_snapshotKey);
    if (raw == null) {
      return null;
    }
    final snapshot = LeagueSnapshotCodec.decode(raw);
    _memory = snapshot;
    return snapshot;
  }

  @override
  Future<void> save({
    List<Fixture>? fixtures,
    List<Standing>? standings,
    List<Team>? teams,
  }) async {
    final current = await read();
    final snapshot = LeagueSnapshot(
      fixtures: List<Fixture>.from(fixtures ?? current?.fixtures ?? const []),
      standings: List<Standing>.from(
        standings ?? current?.standings ?? const [],
      ),
      teams: List<Team>.from(teams ?? current?.teams ?? const []),
      updatedAt: DateTime.now(),
    );
    _memory = snapshot;
    _stale.clearWritten(
      fixtures: fixtures != null,
      standings: standings != null,
      teams: teams != null,
    );
    await _box.put(_snapshotKey, LeagueSnapshotCodec.encode(snapshot));
  }

  @override
  void markStale({
    bool fixtures = false,
    bool standings = false,
    bool teams = false,
  }) {
    if (_memory == null && _box.get(_snapshotKey) == null) {
      return;
    }
    _stale.mark(fixtures: fixtures, standings: standings, teams: teams);
  }
}
