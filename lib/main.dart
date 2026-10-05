import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:league_track/app/league_track_app.dart';
import 'package:league_track/data/local/league_cache.dart';
import 'package:league_track/data/local/shared_preferences_local_store.dart';
import 'package:league_track/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  final cacheBox = await Hive.openBox<String>(HiveLeagueCache.boxName);
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(
          SharedPreferencesLocalStore(preferences),
        ),
        leagueCacheProvider.overrideWithValue(HiveLeagueCache(cacheBox)),
      ],
      child: const LeagueTrackApp(),
    ),
  );
}
