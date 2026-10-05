import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:league_track/core/constants/app_constants.dart';
import 'package:league_track/core/theme/app_theme.dart';
import 'package:league_track/app/home_shell.dart';
import 'package:league_track/providers/providers.dart';

/// Application shell. Fixtures open first; standings sit beside them.
class LeagueTrackApp extends ConsumerWidget {
  const LeagueTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
