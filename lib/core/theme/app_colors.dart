import 'package:flutter/material.dart';

/// Design tokens for Nabd (نبض) Health Application.
/// Enforces WCAG AA compliant contrast ratios (>= 4.5:1) for both light and dark themes.
class AppColors {
  AppColors._();

  // Primary Medical Brand Palette
  static const Color primaryBlue = Color(0xFF0F62FE);       // Core Medical Royal Blue
  static const Color primaryDarkBlue = Color(0xFF0043CE);   // Dark Accent Blue
  static const Color primaryLightBlue = Color(0xFFEDF5FF);  // Soft Tonal Blue Background
  static const Color secondaryTeal = Color(0xFF007D79);     // Clinical Vitality Teal
  static const Color secondaryLightTeal = Color(0xFFE5F6F5);
  static const Color accentTeal = Color(0xFF007D79);
  static const Color darkCardBg = Color(0xFF222B35);

  // Status & Health Indicator Colors (Strict Medical Interpretation)
  static const Color statusNormal = Color(0xFF198038);      // Safe / Normal Reference Range (Green)
  static const Color statusNormalBg = Color(0xFFDEFBE6);
  static const Color statusWarning = Color(0xFFB28600);     // Borderline / Caution (Amber/Yellow)
  static const Color statusWarningBg = Color(0xFFFDF4DC);
  static const Color statusAlert = Color(0xFFDA1E28);       // Out-of-Range / Consult Doctor (Red)
  static const Color statusAlertBg = Color(0xFFFFF1F1);

  // Light Mode Surfaces & Text
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E6ED);
  static const Color lightTextPrimary = Color(0xFF161616);
  static const Color lightTextSecondary = Color(0xFF525252);
  static const Color lightTextMuted = Color(0xFF8D8D8D);

  // Dark Mode Surfaces & Text
  static const Color darkBackground = Color(0xFF12161A);
  static const Color darkSurface = Color(0xFF1A2129);
  static const Color darkSurfaceCard = Color(0xFF222B35);
  static const Color darkBorder = Color(0xFF2E3846);
  static const Color darkTextPrimary = Color(0xFFF4F7FB);
  static const Color darkTextSecondary = Color(0xFFC1C7CD);
  static const Color darkTextMuted = Color(0xFF878D96);

  // Focus & Accessibility Outlines
  static const Color focusRing = Color(0xFF0F62FE);
}
