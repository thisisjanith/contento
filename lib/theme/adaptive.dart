import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Platform-detection helpers. Deliberately avoids `dart:io`'s `Platform`
/// (not available at all on web) in favor of `defaultTargetPlatform`, which
/// is safe to read on every target including web.
class Adaptive {
  Adaptive._();

  static bool get isWeb => kIsWeb;

  static bool get isIOSNative =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroidNative =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isNativeMobile => isIOSNative || isAndroidNative;

  /// Desktop web / desktop-class window: persistent sidebar chrome.
  static bool get isDesktopClass =>
      kIsWeb ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux));

  static const double mobileBreakpoint = 760;
  static const double tabletBreakpoint = 1024;

  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;
}
