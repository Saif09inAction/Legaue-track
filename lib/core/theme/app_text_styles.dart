import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Plus Jakarta Sans for interface text and Barlow Condensed for scores.
abstract final class AppTextStyles {
  static TextTheme sans(TextTheme base) {
    return GoogleFonts.plusJakartaSansTextTheme(base);
  }

  static TextStyle score({required Color color}) {
    return GoogleFonts.barlowCondensed(
      color: color,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: 0.4,
    );
  }

  static TextStyle sectionTitle({required Color color}) {
    return GoogleFonts.plusJakartaSans(
      color: color,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
  }
}
