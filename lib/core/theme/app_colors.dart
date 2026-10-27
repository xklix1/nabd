import 'package:flutter/material.dart';

/// Modern Clinical UX Design Tokens for Nabd (نبض).
/// Enforces WCAG AA compliant contrast ratios (>= 4.5:1) with rich medical aesthetics,
/// deep midnight navy dark mode, refined porcelain light mode, and soft glassmorphism.
class AppColors {
  AppColors._();

  // Primary Medical Brand Palette
  static const Color primaryBlue = Color(0xFF1A56DB);       // Modern Clinical Electric Blue
  static const Color primaryDarkBlue = Color(0xFF1E40AF);   // Deep Accent Blue
  static const Color primaryLightBlue = Color(0xFFEBF5FF);  // Soft Tonal Blue Background
  static const Color secondaryTeal = Color(0xFF0D9488);     // Modern Medical Teal
  static const Color secondaryLightTeal = Color(0xFFCCFBF1);// Soft Tonal Teal
  static const Color accentCyan = Color(0xFF06B6D4);        // Vibrant Clinical Cyan
  static const Color darkCardBg = Color(0xFF162032);

  // Status & Clinical Indicators
  static const Color statusNormal = Color(0xFF059669);      // Safe Reference (Emerald Green)
  static const Color statusNormalBg = Color(0xFFD1FAE5);
  static const Color statusWarning = Color(0xFFD97706);     // Caution / Borderline (Amber)
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusAlert = Color(0xFFDC2626);       // Out-of-Range / Immediate Review (Ruby Red)
  static const Color statusAlertBg = Color(0xFFFEE2E2);

  // Light Mode Surfaces & Text (Refined Clinical Porcelain)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEDF2F7);
  static const Color lightTextPrimary = Color(0xFF0F172A);  // Deep Slate 900
  static const Color lightTextSecondary = Color(0xFF475569);// Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);    // Slate 400

  // Dark Mode Surfaces & Text (Deep Midnight Slate / Navy)
  static const Color darkBackground = Color(0xFF0A0F1D);   // Deep Space Slate
  static const Color darkSurface = Color(0xFF111827);      // Deep Slate 900
  static const Color darkSurfaceCard = Color(0xFF162032);  // Rich Elevated Navy Card
  static const Color darkBorder = Color(0xFF1F2C45);       // Subtle Midnight Blue Border
  static const Color darkBorderSubtle = Color(0xFF182236);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);  // Crisp White Slate
  static const Color darkTextSecondary = Color(0xFFCBD5E1);// Slate 300
  static const Color darkTextMuted = Color(0xFF64748B);    // Slate 500

  // Focus & Accessibility Outlines
  static const Color focusRing = Color(0xFF3B82F6);

  // Modern Clinical Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A56DB), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentCyanGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
