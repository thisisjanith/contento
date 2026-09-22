import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/adaptive.dart';
import '../theme/colors.dart';

/// Toast/snackbar helper — Material `SnackBar` on Android/web, a
/// Cupertino-style transient top banner on iOS (a verbatim Material
/// SnackBar reads as un-native there).
class AppToast {
  AppToast._();

  static void show(BuildContext context, String message, {bool isError = false}) {
    if (Adaptive.isIOSNative) {
      _showCupertinoBanner(context, message, isError: isError);
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.accent : AppColors.textDark,
        content: Text(message, style: const TextStyle(fontFamily: 'IBM Plex Sans')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void _showCupertinoBanner(BuildContext context, String message, {required bool isError}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CupertinoBanner(
        message: message,
        isError: isError,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _CupertinoBanner extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _CupertinoBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_CupertinoBanner> createState() => _CupertinoBannerState();
}

class _CupertinoBannerState extends State<_CupertinoBanner> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2, milliseconds: 400), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isError
                      ? CupertinoIcons.exclamationmark_circle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: widget.isError ? AppColors.accent : AppColors.approvedLight,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      color: CupertinoColors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
