import 'package:flutter/material.dart';
import 'package:league_track/core/theme/app_colors.dart';

/// Extra colors that [ColorScheme] does not cover: live state and form.
class LeagueTrackColors extends ThemeExtension<LeagueTrackColors> {
  const LeagueTrackColors({
    required this.live,
    required this.win,
    required this.draw,
    required this.loss,
    required this.gold,
    required this.muted,
    required this.card,
    required this.line,
  });

  final Color live;
  final Color win;
  final Color draw;
  final Color loss;
  final Color gold;
  final Color muted;
  final Color card;
  final Color line;

  static const light = LeagueTrackColors(
    live: AppColors.live,
    win: AppColors.win,
    draw: AppColors.draw,
    loss: AppColors.loss,
    gold: AppColors.gold,
    muted: AppColors.inkMuted,
    card: AppColors.paperRaised,
    line: AppColors.line,
  );

  static const dark = LeagueTrackColors(
    live: AppColors.live,
    win: AppColors.win,
    draw: AppColors.draw,
    loss: AppColors.loss,
    gold: AppColors.gold,
    muted: AppColors.cloudMuted,
    card: AppColors.navyCard,
    line: AppColors.navyLine,
  );

  @override
  LeagueTrackColors copyWith({
    Color? live,
    Color? win,
    Color? draw,
    Color? loss,
    Color? gold,
    Color? muted,
    Color? card,
    Color? line,
  }) {
    return LeagueTrackColors(
      live: live ?? this.live,
      win: win ?? this.win,
      draw: draw ?? this.draw,
      loss: loss ?? this.loss,
      gold: gold ?? this.gold,
      muted: muted ?? this.muted,
      card: card ?? this.card,
      line: line ?? this.line,
    );
  }

  @override
  LeagueTrackColors lerp(covariant LeagueTrackColors? other, double t) {
    if (other == null) {
      return this;
    }
    return LeagueTrackColors(
      live: Color.lerp(live, other.live, t)!,
      win: Color.lerp(win, other.win, t)!,
      draw: Color.lerp(draw, other.draw, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}
