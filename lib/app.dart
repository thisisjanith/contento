import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin/admin_shell.dart';
import 'auth/login_screen.dart';
import 'employee/employee_shell.dart';
import 'models/employee.dart';
import 'state/app_state.dart';
import 'theme/adaptive.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';

/// MaterialApp/CupertinoApp switch, theming, and role-based routing.
class ContentoApp extends ConsumerWidget {
  const ContentoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Adaptive.isIOSNative) {
      return CupertinoApp(
        title: 'Contento',
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(fontFamily: 'IBM Plex Sans', color: AppColors.textDark, fontSize: 15),
            navTitleTextStyle: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textDark),
            navLargeTitleTextStyle: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700, fontSize: 30, color: AppColors.textDark),
          ),
        ),
        home: const _SessionGate(),
      );
    }

    return MaterialApp(
      title: 'Contento',
      debugShowCheckedModeBanner: false,
      theme: _materialTheme(),
      home: const _SessionGate(),
    );
  }

  ThemeData _materialTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      fontFamily: 'IBM Plex Sans',
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        titleTextStyle: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700, fontSize: 19, color: AppColors.textDark),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        hintStyle: const TextStyle(fontFamily: 'IBM Plex Sans', color: AppColors.textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          elevation: 0,
          minimumSize: const Size(0, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          minimumSize: const Size(0, 44),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 14),
          minimumSize: const Size(0, 44),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 11.5, fontWeight: FontWeight.w600)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}

/// Backed by real Firebase Auth now — every platform shows the login
/// screen when signed out, and routes by the signed-in employee's actual
/// role (resolved from their `employees/{uid}` Firestore doc), not by
/// whatever the login toggle happened to be set to.
class _SessionGate extends ConsumerWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);

    if (user == null) return const LoginScreen();

    return user.role == UserRole.admin ? const AdminShell() : const EmployeeShell();
  }
}
