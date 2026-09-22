import 'package:flutter/material.dart';
import 'colors.dart';

/// Space Grotesk for headings/display, IBM Plex Sans for body/UI.
/// Deliberately not Inter/Roboto/Arial/system-default.
class AppTypography {
  AppTypography._();

  static const String display = 'Space Grotesk';
  static const String body = 'IBM Plex Sans';

  static TextTheme textTheme = TextTheme(
    displayLarge: const TextStyle(
      fontFamily: display,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
      height: 1.15,
    ),
    displayMedium: const TextStyle(
      fontFamily: display,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
      height: 1.18,
    ),
    headlineLarge: const TextStyle(
      fontFamily: display,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
      height: 1.2,
    ),
    headlineMedium: const TextStyle(
      fontFamily: display,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    headlineSmall: const TextStyle(
      fontFamily: display,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    titleLarge: const TextStyle(
      fontFamily: display,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    titleMedium: const TextStyle(
      fontFamily: body,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    titleSmall: const TextStyle(
      fontFamily: body,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    bodyLarge: const TextStyle(
      fontFamily: body,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textDark,
      height: 1.45,
    ),
    bodyMedium: const TextStyle(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textDark,
      height: 1.45,
    ),
    bodySmall: const TextStyle(
      fontFamily: body,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.4,
    ),
    labelLarge: const TextStyle(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    labelMedium: const TextStyle(
      fontFamily: body,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.4,
    ),
    labelSmall: const TextStyle(
      fontFamily: body,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.5,
    ),
  );
}
