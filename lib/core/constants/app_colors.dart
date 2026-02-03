import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Ultra Premium
  static const Color primary = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF020617);

  // Secondary & Accent - Sophisticated
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryLight = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF1D4ED8);

  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color accentDark = Color(0xFF7C3AED);

  // Background Colors - Ultra Premium
  static const Color background = Color(0xFFFCFCFD);
  static const Color backgroundSecondary = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceInput = Color(0xFFF1F5F9);

  // Text Colors - Ultra High Contrast
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textQuaternary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Status Colors - Premium
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDCF2FF);
  static const Color infoDark = Color(0xFF1D4ED8);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border & Divider - Ultra Subtle
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color borderStrong = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFF1F5F9);

  // Grey Colors
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);

  // Shadow - Professional
  static const Color shadow = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowStrong = Color(0x25000000);
  static const Color shadowColored = Color(0x0A3B82F6);

  // Interactive States
  static const Color hover = Color(0xFFF8FAFC);
  static const Color pressed = Color(0xFFF1F5F9);
  static const Color selected = Color(0xFFEFF6FF);
  static const Color focus = Color(0xFFDCF2FF);

  // Special Purpose
  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0xFFF1F5F9);
  static const Color skeleton = Color(0xFFE2E8F0);

  // Premium Feature Colors
  static const Color premium = Color(0xFFFFD700);
  static const Color premiumLight = Color(0xFFFFFBEB);
  static const Color verified = Color(0xFF10B981);
  static const Color featured = Color(0xFF8B5CF6);
}
