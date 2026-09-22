import 'package:flutter/material.dart';
import '../models/post.dart';

/// Brand palette for Contento. Keep this the single source of truth for
/// color — screens should never hardcode hex values inline.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B4FE5);
  static const Color primaryDark = Color(0xFF4A3FD1);
  static const Color accent = Color(0xFFF2703C);
  static const Color textDark = Color(0xFF1E2140);
  static const Color background = Color(0xFFF8F6F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color approved = Color(0xFF1F8A4C);
  static const Color approvedLight = Color(0xFF2FAE64);

  static const Color border = Color(0xFFE7E2D8);
  static const Color textMuted = Color(0xFF6B6E8A);

  // Status semantics.
  static const Color statusPending = Color(0xFF8A8D9E);
  static const Color statusPendingBg = Color(0xFFE7E6ED);
  static const Color statusSubmitted = primary;
  static const Color statusSubmittedBg = Color(0xFFE6E3FB);
  static const Color statusNeedsRevision = accent;
  static const Color statusNeedsRevisionBg = Color(0xFFFBE4D9);
  static const Color statusApproved = approved;
  static const Color statusApprovedBg = Color(0xFFDCF0E3);

  static Color statusColor(PostStatus status) {
    switch (status) {
      case PostStatus.pending:
        return statusPending;
      case PostStatus.submitted:
        return statusSubmitted;
      case PostStatus.needsRevision:
        return statusNeedsRevision;
      case PostStatus.approved:
        return statusApproved;
    }
  }

  static Color statusBackground(PostStatus status) {
    switch (status) {
      case PostStatus.pending:
        return statusPendingBg;
      case PostStatus.submitted:
        return statusSubmittedBg;
      case PostStatus.needsRevision:
        return statusNeedsRevisionBg;
      case PostStatus.approved:
        return statusApprovedBg;
    }
  }
}
