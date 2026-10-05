import 'package:equatable/equatable.dart';

/// Theme choice stored on device. Mapped to Flutter's ThemeMode in the app shell.
enum AppThemeSetting {
  system,
  light,
  dark;

  static AppThemeSetting fromName(String? name) {
    for (final setting in AppThemeSetting.values) {
      if (setting.name == name) {
        return setting;
      }
    }
    return AppThemeSetting.system;
  }
}

class UserPreferences extends Equatable {
  const UserPreferences({
    this.favoriteTeamId,
    this.themeSetting = AppThemeSetting.system,
    this.followedTeamIds = const [],
  });

  final String? favoriteTeamId;
  final AppThemeSetting themeSetting;
  final List<String> followedTeamIds;

  UserPreferences copyWith({
    String? favoriteTeamId,
    bool clearFavoriteTeam = false,
    AppThemeSetting? themeSetting,
    List<String>? followedTeamIds,
  }) {
    return UserPreferences(
      favoriteTeamId: clearFavoriteTeam
          ? null
          : favoriteTeamId ?? this.favoriteTeamId,
      themeSetting: themeSetting ?? this.themeSetting,
      followedTeamIds: followedTeamIds ?? this.followedTeamIds,
    );
  }

  @override
  List<Object?> get props => [favoriteTeamId, themeSetting, followedTeamIds];
}
