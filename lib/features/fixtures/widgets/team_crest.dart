import 'package:flutter/material.dart';
import 'package:league_track/data/models/team.dart';

/// Colored monogram used in place of a club badge.
class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, required this.team, this.size = 36});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(team.primaryColor) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xFF101828);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: team.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: team.secondaryColor.withValues(alpha: 0.85),
          width: 1.5,
        ),
      ),
      child: Text(
        team.shortName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: onColor,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.28,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
