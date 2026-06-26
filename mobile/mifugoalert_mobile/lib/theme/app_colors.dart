import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const deepGreen = Color(0xFF092E20);
  static const primary = Color(0xFF1B7A3D);
  static const primaryDark = Color(0xFF145C2E);
  static const primaryTint = Color(0xFFE3EFE8);

  static const gold = Color(0xFFD49F12);
  static const goldDark = Color(
    0xFF8A6308,
  );
  static const goldTint = Color(0xFFFAF0D2);

  static const maroon = Color(0xFF600718);
  static const maroonDark = Color(0xFF45040F);
  static const maroonTint = Color(0xFFF6E4E7);

  static const bg = Color(0xFFF1EFEF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E0DD);

  static const textPrimary = Color(0xFF1A1410);
  static const textSecondary = Color(0xFF6B6360);
  static const textOnDark = Color(0xFFFFFFFF);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepGreen, primary],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3B23A), gold],
  );

  static const pendingBg = goldTint;
  static const pendingFg = goldDark;
  static const assignedBg = Color(0xFFDDE8F2);
  static const assignedFg = Color(0xFF1D4E89);
  static const progressBg = goldTint;
  static const progressFg = goldDark;
  static const resolvedBg = primaryTint;
  static const resolvedFg = primary;
  static const emergencyBg = maroonTint;
  static const emergencyFg = maroon;
}
