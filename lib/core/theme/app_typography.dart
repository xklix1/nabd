import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for Nabd (نبض).
/// Dynamically selects Cairo for Arabic and Inter for English,
/// maintaining typographic hierarchy, readability, and contrast.
class AppTypography {
  AppTypography._();

  static TextStyle getHeading1({required bool isArabic, required Color color}) {
    final base = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: color,
    );
    return isArabic ? GoogleFonts.cairo(textStyle: base) : GoogleFonts.inter(textStyle: base);
  }

  static TextStyle getHeading2({required bool isArabic, required Color color}) {
    final base = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: color,
    );
    return isArabic ? GoogleFonts.cairo(textStyle: base) : GoogleFonts.inter(textStyle: base);
  }

  static TextStyle getHeading3({required bool isArabic, required Color color}) {
    final base = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: color,
    );
    return isArabic ? GoogleFonts.cairo(textStyle: base) : GoogleFonts.inter(textStyle: base);
  }

  static TextStyle getBodyLarge({required bool isArabic, required Color color}) {
    final base = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
    return isArabic ? GoogleFonts.cairo(textStyle: base) : GoogleFonts.inter(textStyle: base);
  }

  static TextStyle getBodyMedium({required bool isArabic, required Color color}) {
    final base = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
    return isArabic ? GoogleFonts.cairo(textStyle: base) : GoogleFonts.inter(textStyle: base);
  }

  static TextStyle getCaption({required bool isArabic, required Color color}) {
    final base = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: color,
    );
    return isArabic ? GoogleFonts.cairo(textStyle: base) : GoogleFonts.inter(textStyle: base);
  }

  static TextStyle getMetricValue({required bool isArabic, required Color color}) {
    final base = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.5,
      color: color,
    );
    return isArabic ? GoogleFonts.cairo(textStyle: base) : GoogleFonts.inter(textStyle: base);
  }
}
